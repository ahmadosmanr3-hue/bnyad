import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { FOOD_TEST_FILE, foodApproval, foodTestArmed, requireFoodApproval, supervisedFood, localNetworkTransport, localFoodTestSelected } from '../lib/ai/supervised-food';
import { buildPrompt, validateOutput } from '../lib/ai/contract';
import { DevelopmentBudget } from '../scripts/lib/gemini-development';
import type { Config } from '../lib/ai/provider';

const original = { ...process.env }, cwd = process.cwd(), dirs: string[] = [];
const model = 'gemini-3.5-flash-lite', key = 'private-fictional-provider-key';
const input = { image: { mimeType:'image/jpeg', data:'/9j/fixture' } };
const profile = { dailyCalories:2000, dailyProtein:100, dailyCarbs:260, dailyFat:60 };
const prompt = buildPrompt('food',input,profile);
const config: Config = { key:'dummy-local', model, enabled:true, inputRate:.3, outputRate:2.5, budgetMicros:1000000,
  dailyLimit:100, minuteLimit:20, inputLimit:12000, outputLimit:8192, timeoutMs:25000, cacheSeconds:21600 };
afterEach(() => {
  process.chdir(cwd); for (const k of Object.keys(process.env)) if (!(k in original)) delete process.env[k]; Object.assign(process.env,original);
  for (const dir of dirs.splice(0)) fs.rmSync(dir,{ recursive:true });
});
function setup() {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'bnyad-one-food-')); dirs.push(dir); process.chdir(dir);
  Object.assign(process.env,{ APP_ENV:'local-iphone', NODE_ENV:'development', BNYAD_LOCAL_TEST:'true',
    BNYAD_LOCAL_ENVIRONMENT_ID:'bnyad-local-iphone-v1', BNYAD_LOCAL_AI_MODE:'mock',
    DATABASE_URL:'postgresql://fictional:fictional@127.0.0.1:55439/bnyad_local_iphone_20261020' }); delete process.env.VERCEL;
  fs.mkdirSync('.gemini-development',{ mode:0o700 }); fs.mkdirSync('.local-development',{ mode:0o700 });
  fs.writeFileSync('.gemini-development/requests.json',JSON.stringify({ version:1, requests:19, model, modelAccessible:true }),{ mode:0o600 });
  fs.writeFileSync('.env.gemini-development.local',`GEMINI_API_KEY=${key}\nGEMINI_MODEL=${model}\nBNYAD_GEMINI_FREE_TIER_CONFIRMED=true\n`,{ mode:0o600 });
  fs.writeFileSync(FOOD_TEST_FILE,JSON.stringify({version:1,id:'11111111-1111-4111-8111-111111111111',userId:1,operation:'food',model,
    requestCap:21,startRequests:19,enabled:true,state:'armed',expiresAt:new Date(Date.now()+60000).toISOString()}),{mode:0o600});
}
const ledger = () => JSON.parse(fs.readFileSync('.gemini-development/requests.json','utf8'));
const raw = { names:{en:'Whole egg',ar:'بيضة كاملة',ku:'هێلکە'}, descriptions:{en:'An estimated egg portion.',ar:'حصة بيض تقديرية.',ku:'بڕێکی خەمڵێنراوی هێلکە.'}, portions:[{id:'p8',grams:50}] };
function provider(calls: string[], failure?: string): typeof fetch {
  return localNetworkTransport((async (url: any, init: any) => {
    calls.push(String(url));
    assert.equal(foodApproval()?.enabled,false); assert.equal(foodApproval()?.state,'claimed');
    assert.equal(new Headers(init.headers).get('x-goog-api-key'),key); assert.ok(!String(url).includes(key));
    if (failure && String(url).endsWith(':'+failure)) return Response.json({}, {status:429});
    if (String(url).endsWith(':countTokens')) return Response.json({totalTokens:100});
    return Response.json({usageMetadata:{promptTokenCount:100,totalTokenCount:300},candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify(raw)}]}}]});
  }) as typeof fetch);
}
test('one supervised food scan uses exactly calls 20/21 and returns actual provider data, never mock tomato', async () => {
  setup(); const calls:string[]=[];
  assert.equal(localFoodTestSelected('food',1,true),true);
  const result=await supervisedFood(prompt,input,config,1,provider(calls));
  assert.equal(calls.length,2); assert.ok(calls[0].endsWith(':countTokens')); assert.ok(calls[1].endsWith(':generateContent'));
  assert.equal(ledger().requests,21); assert.equal(foodTestArmed(),false); assert.equal(foodApproval()?.state,'finished');
  const valid=validateOutput('food',result.result,input,profile); assert.equal(valid.components[0].id,'p8'); assert.equal(valid.names.ku,'هێلکە');
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls))); assert.equal(calls.length,2);
  const budget=new DevelopmentBudget('.gemini-development',model,provider(calls),false,21);
  try { await assert.rejects(budget.fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:countTokens`,{method:'POST'})); }
  finally { budget.close(); }
  assert.equal(calls.length,2); assert.equal(ledger().requests,21);
});
test('failed token count stops at 20, disables grant and cannot retry or generate', async () => {
  setup();const calls:string[]=[];
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls,'countTokens')));
  assert.equal(calls.length,1); assert.equal(ledger().requests,20); assert.equal(foodApproval()?.state,'failed');
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls))); assert.equal(calls.length,1);
});
test('failed generation stops at 21 with no retry and no reusable approval', async () => {
  setup();const calls:string[]=[];
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls,'generateContent')));
  assert.equal(calls.length,2); assert.equal(ledger().requests,21); assert.equal(foodTestArmed(),false);
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls))); assert.equal(calls.length,2);
});
test('unauthorized account, wrong operation, expiration and altered cap cannot reach Google', async () => {
  setup();let calls=0;const transport=(async()=>{calls++;return Response.json({});}) as typeof fetch;
  assert.throws(()=>localFoodTestSelected('recipe',1,true)); assert.throws(()=>requireFoodApproval(2));
  await assert.rejects(supervisedFood(prompt,input,config,2,transport));
  const a=foodApproval()!; a.expiresAt=new Date(0).toISOString(); fs.writeFileSync(FOOD_TEST_FILE,JSON.stringify(a));
  await assert.rejects(supervisedFood(prompt,input,config,1,transport));
  fs.writeFileSync(FOOD_TEST_FILE,JSON.stringify({...a,requestCap:100})); assert.throws(foodApproval);
  assert.equal(calls,0); assert.equal(ledger().requests,19);
});
test('global network gate blocks direct, duplicate, wrong-model and metadata calls', async () => {
  setup();let calls=0;const gate=localNetworkTransport((async()=>{calls++;return Response.json({});}) as typeof fetch);
  for(const url of ['https://example.com',`https://generativelanguage.googleapis.com/v1beta/models/${model}`,`https://generativelanguage.googleapis.com/v1beta/models/${model}:countTokens`])await assert.rejects(gate(url,{method:'POST'}));
  const budget=new DevelopmentBudget('.gemini-development',model,gate,false,21);
  try {
    const a=foodApproval()!;a.enabled=false;a.state='claimed';fs.writeFileSync(FOOD_TEST_FILE,JSON.stringify(a));
    const target=`https://generativelanguage.googleapis.com/v1beta/models/${model}:countTokens`;
    await budget.fetch(target,{method:'POST',headers:{'x-goog-api-key':key}});
    await assert.rejects(gate(target,{method:'POST',headers:{'x-goog-api-key':key}}));
    assert.equal(calls,1);
  }finally{budget.close();}
});
test('concurrent supervised scans cannot race the shared budget lock', async () => {
  setup();const calls:string[]=[];let release!:()=>void;
  const pause=new Promise<void>(resolve=>{release=resolve;});const real=provider(calls);
  const slow=(async(input:any,init:any)=>{if(String(input).endsWith(':countTokens'))await pause;return real(input,init);}) as typeof fetch;
  const first=supervisedFood(prompt,input,config,1,slow);
  await assert.rejects(supervisedFood(prompt,input,config,1,provider(calls)));
  release();await first;assert.equal(calls.length,2);assert.equal(ledger().requests,21);
});
test('malformed provider content consumes its attempts but never permits a second scan', async () => {
  setup();let calls=0;const gate=localNetworkTransport((async(url:any)=>{calls++;return String(url).endsWith(':countTokens')?Response.json({totalTokens:100}):Response.json({usageMetadata:{promptTokenCount:100,totalTokenCount:200},candidates:[{finishReason:'STOP',content:{parts:[{text:'bad JSON'}]}}]});}) as typeof fetch);
  await assert.rejects(supervisedFood(prompt,input,config,1,gate));assert.equal(calls,2);assert.equal(foodApproval()?.state,'failed');
  await assert.rejects(supervisedFood(prompt,input,config,1,gate));assert.equal(calls,2);
});
