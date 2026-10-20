import fs from 'node:fs';
import https from 'node:https';
import { parseEnv } from 'node:util';
import { assertLocalDevelopment } from '../lib/local-development';

async function main() {
  if (process.env.DATABASE_URL || process.env.VERCEL) throw new Error('Use a clean local-only process.');
  Object.assign(process.env, parseEnv(fs.readFileSync('.local-development/backend.env', 'utf8')));
  assertLocalDevelopment();
  if (process.env.BNYAD_LOCAL_AI_MODE !== 'mock') throw new Error('Mocks only.');
  const { prisma } = await import('../lib/db');
  const { CONSENT_VERSION } = await import('../lib/ai/contract');
  const credential = fs.readFileSync('.local-development/qa-account.txt', 'utf8');
  const password = credential.match(/^Password: (.+)$/m)?.[1];
  if (!password) throw new Error('Private fictional credentials required.');
  const ca = fs.readFileSync('.local-development/ca/rootCA.pem');
  const origin = `https://${process.env.BNYAD_LOCAL_LAN_ADDRESS}:8443`;
  let token = '';
  const check = (condition: unknown, name: string) => { if (!condition) throw new Error('Failed: ' + name); };
  const request = (route: string, method = 'GET', body?: unknown, scenario = '', bearer = token): Promise<{ status: number; body: any }> => new Promise((resolve, reject) => {
    const data = body === undefined ? undefined : JSON.stringify(body);
    const req = https.request(origin + '/api/' + route, { ca, method, timeout: 45000, headers: {
      'Content-Type': 'application/json', ...(bearer ? { Authorization: 'Bearer ' + bearer } : {}),
      ...(scenario ? { 'X-Bnyad-Mock-Scenario': scenario } : {}),
    } }, res => {
      let output = ''; res.on('data', chunk => { output += chunk; });
      res.on('end', () => { try { resolve({ status: res.statusCode!, body: JSON.parse(output) }); } catch { reject(new Error('Expected API JSON.')); } });
    });
    req.on('error', () => reject(new Error('Private HTTPS request failed.'))); req.on('timeout', () => req.destroy());
    req.end(data);
  });
  const ledger = fs.readFileSync('.gemini-development/requests.json', 'utf8');
  try {
    check((await request('local-development/readiness')).body.liveGoogleAllowed === false, 'readiness');
    const qa = await prisma.user.findUniqueOrThrow({ where: { phone: '+9647000000000' } });
    const profileBefore = await prisma.userProfile.findUniqueOrThrow({ where: { userId: qa.id } });
    check((await request('auth/login', 'POST', { phone: '+9647000000000', password: 'incorrect-fictional-test' })).status === 401, 'wrong password rejected');
    const login = await request('auth/login', 'POST', { phone: '+9647000000000', password });
    check(login.status === 200 && login.body.user.subscription.isPremium, 'normal password login and DB Premium'); token = login.body.token;
    check((await request('auth/me')).status === 200, 'persisted bearer session');
    const generation = { operation: 'meal-plan', input: {} };
    check((await request('ai/generate', 'POST', generation, '', '')).status === 401, 'anonymous rejected');
    await prisma.subscription.updateMany({ where: { userId: qa.id }, data: { active: false } });
    check((await request('ai/generate', 'POST', generation)).status === 403, 'no Premium rejected');
    await prisma.subscription.updateMany({ where: { userId: qa.id }, data: { active: true } });
    await request('ai/consent', 'PUT', { enabled: false, version: CONSENT_VERSION });
    check((await request('ai/generate', 'POST', generation)).status === 403, 'consent required');
    check((await request('ai/consent', 'PUT', { enabled: true, version: CONSENT_VERSION })).status === 200, 'normal consent enabled');
    const image = { mimeType: 'image/jpeg', data: fs.readFileSync('.gemini-development/fixtures/food.jpg').toString('base64') };
    const cases = [generation, { operation: 'recipe', input: { ingredients: ['rice','chicken','tomato'] } }, { operation: 'food', input: { image } }, { operation: 'fridge', input: { image } }];
    for (const body of cases) {
      const result = await request('ai/generate', 'POST', body);
      check(result.status === 200 && result.body.simulated === true, body.operation + ' simulated result');
      const data = result.body.data;
      const content = body.operation === 'meal-plan' ? data.lunch : body.operation === 'fridge' ? data.recipe : data;
      for (const lang of ['en','ar','ku']) check(content.names?.[lang], body.operation + ' ' + lang);
      if (body.operation === 'meal-plan') {
        check(Object.keys(data).length === 4, 'daily only');
        const targets = { calories:2000, protein:100, carbs:260, fat:60 };
        for (const [nutrient, target] of Object.entries(targets)) {
          const total = Object.values(data).reduce((sum: number, meal: any) => sum + meal[nutrient], 0);
          check(Math.abs(total - target) <= target * (nutrient === 'calories' ? .2 : .3), 'daily ' + nutrient);
        }
        check((await request('meal-plan', 'PUT', { plan: data })).status === 200, 'plan saved');
        check((await request('meal-plan')).body.data.plan.lunch.names.ku, 'plan restored');
      }
      console.log('PASS: authenticated mocked ' + body.operation + ', estimated nutrition and EN/AR/Sorani response.');
    }
    check((await request('ai/generate', 'POST', generation)).body.cached === true, 'cache reuse');
    for (const [scenario, status] of [['malformed',502],['unavailable',503],['rate-limit',429]] as const) {
      check((await request('ai/generate', 'POST', cases[1], scenario)).status === status, scenario + ' handling');
    }
    check((await request('ai/generate', 'POST', { operation:'food', input:{ image:{ mimeType:'image/jpeg', data:'invalid' } } })).status === 422, 'invalid image rejected');
    check((await request('water', 'PUT', { glasses: 3 })).status === 200, 'water saved');
    check((await request('water')).body.data.glasses === 3, 'water restored');
    check((await request('weights', 'POST', { weight: 70 })).status === 200, 'fictional weight saved');
    const food = await request('logs', 'POST', { name:'Fictional test tomato', external_food_id:'v3', amount:100, calories:18, protein:1, carbs:4, fat:0, meal_type:'snacks' });
    check(food.status === 201, 'fictional food logged');
    check((await request('logs')).body.data.some((item: any) => item.id === food.body.data.id), 'food restored');
    const profileAfter = await prisma.userProfile.findUniqueOrThrow({ where: { userId: qa.id } });
    for (const key of ['dailyCalories','dailyProtein','dailyCarbs','dailyFat'] as const) check(profileBefore[key] === profileAfter[key], 'unchanged food target ' + key);
    check(await prisma.aiUsage.count({ where:{ userId:qa.id, status:'succeeded' } }) >= 4, 'DB usage accounting');
    await request('ai/consent','PUT',{ enabled:false, version:CONSENT_VERSION });
    check(await prisma.aiCache.count({ where:{ userId:qa.id } }) === 0, 'consent revocation clears cache');
    check((await request('ai/generate','POST',generation)).status === 403, 'revoked consent rejected');
    await request('ai/consent','PUT',{ enabled:true, version:CONSENT_VERSION });
    // Explicit synthetic accounting fixtures exercise the real SQL quota path.
    // Remove only these tagged records, never ordinary usage or user records.
    const fixtureKey = 'local-iphone-quota-integration';
    const quotaRows = (count: number, createdAt: Date) => Array.from({length:count}, (_,i) => ({
      id: `local-quota-${Date.now()}-${i}`, userId:qa.id, operation:'recipe', model:'mock-quota-fixture',
      budgetPeriod:new Date().toISOString().slice(0,7), reservedMicros:0, chargedMicros:0, status:'failed', cacheKey:fixtureKey, createdAt,
    }));
    try {
      await prisma.aiUsage.createMany({data:quotaRows(100,new Date(Date.now()-120000))});
      const daily = await request('ai/generate','POST',generation);
      check(daily.status===429 && daily.body.code==='ai_daily_limit','real daily quota enforced');
      await prisma.aiUsage.deleteMany({where:{userId:qa.id,cacheKey:fixtureKey}});
      await prisma.aiUsage.createMany({data:quotaRows(20,new Date())});
      const minute = await request('ai/generate','POST',generation);
      check(minute.status===429 && minute.body.code==='ai_rate_limit','real server rate limit enforced');
    } finally { await prisma.aiUsage.deleteMany({where:{userId:qa.id,cacheKey:fixtureKey}}); }
    await request('ai/consent','PUT',{ enabled:false, version:CONSENT_VERSION });
    check((await request('auth/logout','POST')).status === 200, 'logout');
    check((await request('auth/me')).status === 401, 'revoked session rejected');
    check(fs.readFileSync('.gemini-development/requests.json','utf8') === ledger, '19/20 ledger unchanged');
    console.log('PASS: HTTPS, authentication, server Premium, consent/revocation, cache, malformed/error/rate-limit, nutrition persistence, session logout and unchanged Google ledger.');
  } finally {
    const user = await prisma.user.findUnique({ where:{ phone:'+9647000000000' } });
    if (user) await prisma.subscription.updateMany({ where:{ userId:user.id }, data:{ active:true } });
    await prisma.$disconnect();
  }
}
main().catch(error => { console.error(error instanceof Error && error.message.startsWith('Failed: ') ? error.message : 'Local integration stopped; inspect private server diagnostics.'); process.exitCode=1; });
