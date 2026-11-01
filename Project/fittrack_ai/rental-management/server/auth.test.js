const test = require('node:test');
const assert = require('node:assert/strict');
const { DatabaseSync } = require('node:sqlite');
const { initAuth } = require('./auth');

test('bootstrap claims legacy data and enforces owner, staff and tenant scopes', async () => {
 const db = new DatabaseSync(':memory:');
 db.exec('PRAGMA foreign_keys=ON; CREATE TABLE properties(id INTEGER PRIMARY KEY,name TEXT); CREATE TABLE tenants(id INTEGER PRIMARY KEY,name TEXT); CREATE TABLE rooms(id INTEGER PRIMARY KEY,propertyId INTEGER); CREATE TABLE contracts(id INTEGER PRIMARY KEY,roomId INTEGER,tenantId INTEGER); INSERT INTO properties VALUES(1,\'A\'); INSERT INTO tenants VALUES(1,\'T\'); INSERT INTO rooms VALUES(1,1); INSERT INTO contracts VALUES(1,1,1);');
 const auth=initAuth(db);
 async function call(path,method,input,cookie='') { const req={method,headers:{cookie}}; const res={headers:{},setHeader(k,v){this.headers[k]=v;}}; let result; await auth.handle(req,res,new URL(path,'http://localhost'),async()=>input,(_,status,data)=>{result={status,data,cookie:res.headers['Set-Cookie']?.split(';')[0]};}); return result; }
 const first=await call('/api/auth/bootstrap','POST',{username:'owner',password:'long-password'}); assert.equal(first.status,201); const owner=auth.authenticate({headers:{cookie:first.cookie}}); assert.equal(auth.canProperty(owner,1,'rooms'),true); assert.equal(auth.canTenant(owner,1),true);
 await assert.rejects(call('/api/auth/bootstrap','POST',{username:'other',password:'long-password'}),e=>e.status===409);
 const staff=await call('/api/users','POST',{username:'staff',password:'long-password',role:'STAFF',grants:[{propertyId:1,permissions:['readings']}]},first.cookie);
 const login=await call('/api/auth/login','POST',{username:'staff',password:'long-password'}); const staffUser=auth.authenticate({headers:{cookie:login.cookie}}); assert.equal(staff.data.role,'STAFF'); assert.equal(auth.canProperty(staffUser,1,'readings'),true); assert.equal(auth.canProperty(staffUser,1,'payments'),false);
 const tenant=await call('/api/users','POST',{username:'tenant',password:'long-password',role:'TENANT',tenantId:1},first.cookie); assert.equal(tenant.data.tenantId,1);
 const other=await call('/api/users','POST',{username:'owner2',password:'long-password',role:'OWNER'},first.cookie); assert.equal(auth.canProperty(other.data,1,'rooms'),false);
 await call('/api/users/'+staff.data.id,'PUT',{active:false},first.cookie); assert.equal(auth.authenticate({headers:{cookie:login.cookie}}),undefined);
 for(let i=0;i<5;i++) await assert.rejects(call('/api/auth/login','POST',{username:'staff',password:'wrong-password'}),e=>e.status===401);
 await assert.rejects(call('/api/auth/login','POST',{username:'staff',password:'long-password'}),e=>e.status===429);
 db.close();
});
