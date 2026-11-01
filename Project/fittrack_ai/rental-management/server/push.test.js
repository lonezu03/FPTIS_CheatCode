const {test}=require('node:test');
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {DatabaseSync}=require('node:sqlite');
const initPush=require('./push');

test('push follows sessions and failures do not affect inbox',async()=>{
 const db=new DatabaseSync(':memory:'); db.exec(`PRAGMA foreign_keys=ON;
 CREATE TABLE auth_users(id INTEGER PRIMARY KEY,active INTEGER);
 CREATE TABLE auth_sessions(tokenHash TEXT PRIMARY KEY,userId INTEGER,expiresAt INTEGER);
 CREATE TABLE notifications(id INTEGER PRIMARY KEY,recipientId INTEGER,title TEXT,message TEXT);
 INSERT INTO auth_users VALUES(1,1),(2,1);`);
 const raw='a'.repeat(64); const hash=crypto.createHash('sha256').update(raw).digest('hex');
 db.prepare('INSERT INTO auth_sessions VALUES(?,?,?)').run(hash,1,Date.now()+100000);
 const sent=[]; const push=initPush(db,(message,status=400)=>{const e=new Error(message);e.status=status;throw e;},{sender:async message=>{sent.push(message); if(message.data.notificationId==='4') throw new Error('network failure');}});
 const call=async(method,input,userId=1)=>{let output;await push.handle({method,headers:{cookie:`rental_session=${raw}`}},{},{pathname:'/api/push/devices'},{id:userId},async()=>input,(_r,_s,x)=>{output=x;});return output;};
 const token='device-token-123456789';
 await call('POST',{token,platform:'ANDROID'});
 db.prepare("INSERT INTO notifications VALUES(1,1,'private','private')").run();
 await push.drain();
 assert.equal(sent.length,1); assert.equal(sent[0].data.notificationId,'1'); assert.ok(!JSON.stringify(sent[0]).includes('private'));
 db.prepare("INSERT INTO notifications VALUES(4,1,'retry','retry')").run(); await push.drain(); assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications WHERE id=4').get().n,1); sent.length=1;
 db.prepare("INSERT INTO notifications VALUES(2,2,'other','other')").run(); await push.drain(); assert.equal(sent.length,1);
 await call('DELETE',{token},2); assert.equal(db.prepare('SELECT COUNT(*) n FROM push_devices').get().n,1);
 db.prepare('DELETE FROM auth_sessions WHERE tokenHash=?').run(hash);
 assert.equal(db.prepare('SELECT COUNT(*) n FROM push_devices').get().n,0);
 db.prepare("INSERT INTO notifications VALUES(3,1,'after logout','x')").run(); await push.drain(); assert.equal(sent.length,1);
 assert.equal(db.prepare('SELECT COUNT(*) n FROM notifications').get().n,4);
});
