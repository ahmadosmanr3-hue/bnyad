import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { localizedNotification, parseNotificationTranslations } from '../lib/notification-localization';
import { prisma } from '../lib/db';
import { POST as sendNotification } from '../app/api/admin/notifications/route';
import { GET as inbox } from '../app/api/notifications/route';

const originalEnv = { ...process.env };
const originals = { create: prisma.notification.create, findMany: prisma.notification.findMany,
  user: prisma.user.findUnique, token: prisma.apiToken.findUnique };
afterEach(() => {
  prisma.notification.create=originals.create; prisma.notification.findMany=originals.findMany;
  prisma.user.findUnique=originals.user; prisma.apiToken.findUnique=originals.token;
  for(const key of Object.keys(process.env)) if(!(key in originalEnv)) delete process.env[key];
  Object.assign(process.env,originalEnv);
});

const translations = {
  en: {title:'Reminder',body:'Check your daily plan.'},
  ar: {title:'تذكير',body:'راجع خطتك اليومية.'},
  ckb: {title:'بیرهێنانەوە',body:'پلانی ڕۆژانەت بپشکنە.'},
};
test('authored notifications select recipient locale and legacy ku safely', () => {
  const note={title:'Legacy',body:'Original message',translations:parseNotificationTranslations(translations)};
  for(const lang of ['en','ar','ckb'] as const) assert.deepEqual(localizedNotification(note,lang),translations[lang]);
  assert.deepEqual(localizedNotification(note,'ku'),translations.ckb);
  assert.equal(localizedNotification({title:'Legacy',body:'Preserve user text'},'ku').body,'Preserve user text');
  assert.equal(parseNotificationTranslations(undefined),undefined);
});
test('partial, malformed, oversized and ambiguous authored translations are rejected', () => {
  for(const raw of [null, [], {}, {en:translations.en}, {...translations,ckb:{title:'',body:'x'}},
    {...translations,ku:translations.ckb}, {...translations,ckb:{title:'x',body:'x'.repeat(4001)}},
    {...translations,ckb:{title:1,body:'x'}}, {...translations,ckb:{title:'x',body:'x',unexpected:true}}]) {
    assert.throws(()=>parseNotificationTranslations(raw));
  }
  const {ckb,...other}=translations;
  assert.deepEqual(parseNotificationTranslations({...other,ku:ckb})?.ckb,ckb);
});

test('notification publishing still requires admin authentication and validates before writes', async () => {
  process.env.ADMIN_SECRET='fixture-only-local-test-secret';
  let writes=0;
  prisma.notification.create=(async () => { writes++; throw new Error('must not write'); }) as any;
  const request=(headers:Record<string,string>, value:unknown) => new Request('http://localhost/api/admin/notifications',{
    method:'POST', headers:{'content-type':'application/json',...headers},body:JSON.stringify(value),
  });
  assert.equal((await sendNotification(request({}, {title:'Test',body:'Test'}))).status,401);
  assert.equal((await sendNotification(request({'x-admin-secret':process.env.ADMIN_SECRET}, {
    title:'Test',body:'Test',translations:{en:translations.en},
  }))).status,422);
  assert.equal(writes,0);
});

test('optional translation storage does not rewrite legacy text or require a push provider', async () => {
  process.env.ADMIN_SECRET='fixture-only-local-test-secret';
  let saved:any;
  prisma.notification.create=(async (args:any) => { saved=args.data; return {id:7,...args.data}; }) as any;
  prisma.user.findUnique=(async () => ({fcmToken:null,profile:{language:'ku'}})) as any;
  const result=await sendNotification(new Request('http://localhost/api/admin/notifications',{
    method:'POST',headers:{'content-type':'application/json','x-admin-secret':process.env.ADMIN_SECRET},
    body:JSON.stringify({title:'Legacy fallback',body:'Original message',userId:7,translations}),
  }));
  assert.equal(result.status,201);
  assert.equal(saved.title,'Legacy fallback');assert.equal(saved.body,'Original message');
  assert.deepEqual(saved.translations,translations);
});

test('authenticated Sorani inbox returns Sorani text and maps for later language switching', async () => {
  prisma.apiToken.findUnique=(async () => ({id:1,user:{id:7,profile:{language:'ckb'},subscriptions:[]}})) as any;
  prisma.notification.findMany=(async () => [{id:1,title:'Legacy',body:'Legacy',translations,createdAt:new Date()}]) as any;
  const response=await inbox(new Request('http://localhost/api/notifications',{headers:{authorization:'Bearer '+ 'a'.repeat(80)}}));
  assert.equal(response.status,200);
  const body=await response.json();
  assert.equal(body.data[0].title,translations.ckb.title);
  assert.deepEqual(body.data[0].translations,translations);
});
