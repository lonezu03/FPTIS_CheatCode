const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

test('API enforces owner, staff and tenant isolation and CSRF', async t => {
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'rental-security-'));
 const port=31000+Math.floor(Math.random()*20000); const base=`http://127.0.0.1:${port}`;
 const child=spawn(process.execPath,[path.join(__dirname,'index.js')],{env:{...process.env,DATA_DIR:dir,PORT:String(port),HOST:'127.0.0.1'},stdio:'ignore'});
 t.after(async()=>{child.kill(); await new Promise(resolve=>child.once('exit',resolve)); fs.rmSync(dir,{recursive:true,force:true});});
 let started=false; for(let i=0;i<100;i++) {try { await fetch(base+'/api/auth/status'); started=true; break; } catch {await new Promise(r=>setTimeout(r,50));}} assert.ok(started,'server did not start');
 async function req(method,url,data,cookie,headers={}) { const response=await fetch(base+url,{method,headers:{...(data!==undefined?{'Content-Type':'application/json'}:{}),...(cookie?{Cookie:cookie}:{}),...headers},...(data!==undefined?{body:JSON.stringify(data)}:{})}); const text=await response.text(); return {status:response.status,data:text?JSON.parse(text):null,cookie:response.headers.get('set-cookie')?.split(';')[0]}; }
 async function expect(method,url,data,cookie,status=201) {const r=await req(method,url,data,cookie); assert.equal(r.status,status,`${method} ${url}: ${JSON.stringify(r.data)}`); return r;}
 const owner1=(await expect('POST','/api/auth/bootstrap',{username:'owner1',password:'password-123'})).cookie;
 await expect('POST','/api/users',{username:'owner2',password:'password-123',role:'OWNER'},owner1);
 const owner2=(await expect('POST','/api/auth/login',{username:'owner2',password:'password-123'},null,200)).cookie;
 async function fixtures(owner,suffix) {const p=(await expect('POST','/api/properties',{name:'P'+suffix},owner)).data; const r=(await expect('POST','/api/rooms',{propertyId:p.id,name:'R'+suffix,rent:100000},owner)).data; const tenant=(await expect('POST','/api/tenants',{name:'T'+suffix},owner)).data; const c=(await expect('POST','/api/contracts',{roomId:r.id,tenantId:tenant.id,startDate:'2026-01-01',rent:100000},owner)).data; const reading=(await expect('POST','/api/readings',{roomId:r.id,month:'2026-02',electricPrevious:0,electricCurrent:1,waterPrevious:0,waterCurrent:1,electricRate:1000,waterRate:1000},owner)).data; const invoice=(await expect('POST','/api/invoices',{roomId:r.id,contractId:c.id,month:'2026-02'},owner)).data; const payment=(await expect('POST','/api/payments',{invoiceId:invoice.id,amount:1000,paidAt:'2026-02-01'},owner)).data; await expect('POST','/api/users',{username:'tenant'+suffix,password:'password-123',role:'TENANT',tenantId:tenant.id},owner); const cookie=(await expect('POST','/api/auth/login',{username:'tenant'+suffix,password:'password-123'},null,200)).cookie; return {properties:p,rooms:r,tenants:tenant,contracts:c,readings:reading,invoices:invoice,payments:payment,cookie}; }
 const a=await fixtures(owner1,'a'), b=await fixtures(owner2,'b');
 await expect('POST','/api/users',{username:'staff',password:'password-123',role:'STAFF',grants:[{propertyId:a.properties.id,permissions:['readings']}]},owner1);
 const staff=(await expect('POST','/api/auth/login',{username:'staff',password:'password-123'},null,200)).cookie;
 const me=await expect('GET','/api/auth/me',undefined,staff,200); assert.deepEqual(me.data.grants,[{propertyId:a.properties.id,permission:'readings'}]);
 for(const [role,cookie,fixture] of [['other owner',owner2,a],['other tenant',b.cookie,a],['staff lacking permission',staff,a]]) {
  for(const type of ['properties','rooms','tenants','contracts','invoices','payments']) {const detail=await req('GET',`/api/${type}/${fixture[type].id}`,undefined,cookie); assert.equal(detail.status,404,`${role} detail ${type}`); const list=await req('GET',`/api/${type}`,undefined,cookie); assert.equal(list.status,200,`${role} list ${type}`); assert.ok(!list.data.some(x=>x.id===fixture[type].id),`${role} list leaked ${type}`);}
 }
 for(const type of ['readings']) { for(const [role,cookie] of [['other owner',owner2],['other tenant',b.cookie]]) {const detail=await req('GET',`/api/${type}/${a[type].id}`,undefined,cookie); assert.equal(detail.status,404,`${role} detail ${type}`); const list=await req('GET',`/api/${type}`,undefined,cookie); assert.ok(!list.data.some(x=>x.id===a[type].id),`${role} list leaked ${type}`);} }
 assert.equal((await req('GET',`/api/readings/${a.readings.id}`,undefined,staff)).status,200);
 assert.equal((await req('POST','/api/properties',{name:'attack'},owner1,{Origin:'https://evil.example'})).status,403);
 assert.equal((await req('POST','/api/properties',{name:'attack'},owner1,{'Sec-Fetch-Site':'cross-site'})).status,403);
});
