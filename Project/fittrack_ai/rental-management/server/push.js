const crypto = require('node:crypto');

// Push is best-effort. The in-app notification and its outbox row commit together.
module.exports = function initPush(db, fail, options = {}) {
 db.exec(`CREATE TABLE IF NOT EXISTS push_devices (
   token TEXT PRIMARY KEY, userId INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
   sessionHash TEXT NOT NULL REFERENCES auth_sessions(tokenHash) ON DELETE CASCADE,
   platform TEXT NOT NULL CHECK(platform IN ('ANDROID','IOS')), updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
 CREATE TABLE IF NOT EXISTS push_outbox (
   notificationId INTEGER PRIMARY KEY REFERENCES notifications(id) ON DELETE CASCADE,
   createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
 CREATE TRIGGER IF NOT EXISTS enqueue_notification_push AFTER INSERT ON notifications BEGIN
   INSERT INTO push_outbox(notificationId) VALUES(NEW.id);
 END;`);
 let sender = options.sender || null;
 if (!sender && process.env.FCM_ENABLED === 'true') {
  try {
   const { initializeApp, applicationDefault, getApps } = require('firebase-admin/app');
   const { getMessaging } = require('firebase-admin/messaging');
   const app = getApps().find(x=>x.name==='rental-push') || initializeApp({credential:applicationDefault(), projectId:process.env.FIREBASE_PROJECT_ID || undefined},'rental-push');
   sender = message => getMessaging(app).send(message);
  } catch { console.error('Firebase push unavailable; in-app notifications remain enabled.'); }
 }
 function sessionHash(req) {
  const cookie=(req.headers.cookie||'').split(';').map(x=>x.trim()).find(x=>x.startsWith('rental_session='))?.slice(15);
  if(!cookie || !/^[a-f0-9]{64}$/.test(cookie)) return null;
  return crypto.createHash('sha256').update(cookie).digest('hex');
 }
 async function handle(req,res,url,user,body,json) {
  if(url.pathname!=='/api/push/devices') return false;
  if(!['POST','DELETE'].includes(req.method)) fail('Ph\u01b0\u01a1ng th\u1ee9c kh\u00f4ng h\u1ed7 tr\u1ee3',405);
  const x=await body(req);
  if(typeof x.token!=='string' || x.token.length<16 || x.token.length>4096 || /\s/.test(x.token)) fail('Token thi\u1ebft b\u1ecb kh\u00f4ng h\u1ee3p l\u1ec7');
  const hash=sessionHash(req);
  if(!hash) fail('Vui l\u00f2ng \u0111\u0103ng nh\u1eadp',401);
  if(req.method==='DELETE') {
   db.prepare('DELETE FROM push_devices WHERE token=? AND userId=? AND sessionHash=?').run(x.token,user.id,hash);
   json(res,200,{ok:true}); return true;
  }
  if(!['ANDROID','IOS'].includes(x.platform)) fail('N\u1ec1n t\u1ea3ng kh\u00f4ng h\u1ee3p l\u1ec7');
  db.prepare(`INSERT INTO push_devices(token,userId,sessionHash,platform) VALUES(?,?,?,?)
   ON CONFLICT(token) DO UPDATE SET userId=excluded.userId,sessionHash=excluded.sessionHash,platform=excluded.platform,updatedAt=CURRENT_TIMESTAMP`).run(x.token,user.id,hash,x.platform);
  json(res,200,{ok:true}); return true;
 }
 let running=false;
 async function drain() {
  if(running) return;
  db.prepare("DELETE FROM push_outbox WHERE createdAt < datetime('now','-7 days')").run();
  if(!sender) return;
  running=true;
  try {
   const pending=db.prepare('SELECT o.notificationId,n.recipientId FROM push_outbox o JOIN notifications n ON n.id=o.notificationId ORDER BY o.notificationId LIMIT 100').all();
   for(const item of pending) {
    const devices=db.prepare(`SELECT d.token FROM push_devices d JOIN auth_sessions s ON s.tokenHash=d.sessionHash JOIN auth_users u ON u.id=d.userId
      WHERE d.userId=? AND s.expiresAt>? AND u.active=1`).all(item.recipientId,Date.now());
    // Delete before dispatch: a push is a hint, and failure must not affect the inbox.
    db.prepare('DELETE FROM push_outbox WHERE notificationId=?').run(item.notificationId);
    for(const device of devices) {
     try { await sender({token:device.token, notification:{title:'Nh\u00e0 tr\u1ecd',body:'B\u1ea1n c\u00f3 th\u00f4ng b\u00e1o m\u1edbi.'}, data:{type:'NOTIFICATION',notificationId:String(item.notificationId)}}); }
     catch(e) { if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(e?.code)) db.prepare('DELETE FROM push_devices WHERE token=?').run(device.token); }
    }
   }
  } finally {running=false;}
 }
 const timer=setInterval(()=>{drain().catch(()=>{});},5000); timer.unref();
 return {handle,drain};
};
