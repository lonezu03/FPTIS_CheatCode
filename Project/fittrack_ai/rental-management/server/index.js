const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');

const root = path.resolve(__dirname, '..');
const dataDir = process.env.DATA_DIR || path.join(root, 'data');
fs.mkdirSync(dataDir, { recursive: true });
const db = new DatabaseSync(path.join(dataDir, 'rental.sqlite'));
db.exec(`PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS properties (id INTEGER PRIMARY KEY, name TEXT NOT NULL, address TEXT NOT NULL DEFAULT '');
CREATE TABLE IF NOT EXISTS rooms (id INTEGER PRIMARY KEY, propertyId INTEGER NOT NULL REFERENCES properties(id), name TEXT NOT NULL, rent INTEGER NOT NULL DEFAULT 0, deposit INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'VACANT', UNIQUE(propertyId,name));
CREATE TABLE IF NOT EXISTS tenants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '', identityNumber TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '');
CREATE TABLE IF NOT EXISTS contracts (id INTEGER PRIMARY KEY, roomId INTEGER NOT NULL REFERENCES rooms(id), tenantId INTEGER NOT NULL REFERENCES tenants(id), startDate TEXT NOT NULL, endDate TEXT NOT NULL DEFAULT '', rent INTEGER NOT NULL, deposit INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'ACTIVE');
CREATE UNIQUE INDEX IF NOT EXISTS one_active_contract ON contracts(roomId) WHERE status = 'ACTIVE';
CREATE TABLE IF NOT EXISTS readings (id INTEGER PRIMARY KEY, roomId INTEGER NOT NULL REFERENCES rooms(id), month TEXT NOT NULL, electricPrevious REAL NOT NULL, electricCurrent REAL NOT NULL, waterPrevious REAL NOT NULL, waterCurrent REAL NOT NULL, electricRate INTEGER NOT NULL, waterRate INTEGER NOT NULL, UNIQUE(roomId,month));
CREATE TABLE IF NOT EXISTS invoices (id INTEGER PRIMARY KEY, roomId INTEGER NOT NULL REFERENCES rooms(id), contractId INTEGER NOT NULL REFERENCES contracts(id), month TEXT NOT NULL, rent INTEGER NOT NULL, electricAmount INTEGER NOT NULL, waterAmount INTEGER NOT NULL, serviceAmount INTEGER NOT NULL DEFAULT 0, discount INTEGER NOT NULL DEFAULT 0, total INTEGER NOT NULL, dueDate TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '', UNIQUE(roomId,month));
CREATE TABLE IF NOT EXISTS payments (id INTEGER PRIMARY KEY, invoiceId INTEGER NOT NULL REFERENCES invoices(id), amount INTEGER NOT NULL, paidAt TEXT NOT NULL, method TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '');`);

const auth = require('./auth').initAuth(db);
const business = require('./business')(db, auth, fail);
const push = require('./push')(db, fail);

const schemas = {
 properties: { required:['name'], fields:['name','address'], defaults:{address:''} },
 rooms: { required:['propertyId','name','rent'], fields:['propertyId','name','rent','deposit','status'], defaults:{deposit:0,status:'VACANT'}, enums:{status:['VACANT','OCCUPIED','MAINTENANCE']} },
 tenants: { required:['name'], fields:['name','phone','identityNumber','note'], defaults:{phone:'',identityNumber:'',note:''} },
 contracts: { required:['roomId','tenantId','startDate','rent'], fields:['roomId','tenantId','startDate','endDate','rent','deposit','status'], defaults:{endDate:'',deposit:0,status:'ACTIVE'}, enums:{status:['ACTIVE','ENDED']} },
 readings: { required:['roomId','month','electricPrevious','electricCurrent','waterPrevious','waterCurrent','electricRate','waterRate'], fields:['roomId','month','electricPrevious','electricCurrent','waterPrevious','waterCurrent','electricRate','waterRate'], defaults:{} },
 invoices: { required:['roomId','contractId','month'], fields:['roomId','contractId','month','rent','electricAmount','waterAmount','serviceAmount','discount','total','dueDate','note'], defaults:{serviceAmount:0,discount:0,dueDate:'',note:''} },
 payments: { required:['invoiceId','amount','paidAt'], fields:['invoiceId','amount','paidAt','method','note'], defaults:{method:'',note:''} }
};
const numeric = new Set(['propertyId','roomId','tenantId','contractId','invoiceId','rent','deposit','electricPrevious','electricCurrent','waterPrevious','waterCurrent','electricRate','waterRate','electricAmount','waterAmount','serviceAmount','discount','total','amount']);
const meterFields = new Set(['electricPrevious','electricCurrent','waterPrevious','waterCurrent']);
const dates = new Set(['startDate','endDate','dueDate','paidAt']);
function fail(message, status=400) { const e = new Error(message); e.status=status; throw e; }
function prepare(type, input, existing) {
 const schema=schemas[type]; const data={...schema.defaults,...existing};
 for (const key of schema.fields) if (Object.hasOwn(input,key)) data[key]=input[key];
 for (const key of schema.required) if (data[key] === undefined || data[key] === null || data[key] === '') fail(`Thiếu ${key}`);
 for (const key of schema.fields) {
  const value=data[key]; if (value === undefined) continue;
  if (numeric.has(key)) { if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value > Number.MAX_SAFE_INTEGER || (!meterFields.has(key) && !Number.isSafeInteger(value))) fail(`${key} phải là số không âm hợp lệ`); }
  else if (typeof value !== 'string') fail(`${key} phải là chuỗi`);
  else data[key]=value.trim();
  if (schema.enums?.[key] && !schema.enums[key].includes(data[key])) fail(`${key} không hợp lệ`);
  if (dates.has(key) && data[key] && (!/^\d{4}-\d{2}-\d{2}$/.test(data[key]) || Number.isNaN(Date.parse(data[key]+'T00:00:00Z')) || new Date(data[key]+'T00:00:00Z').toISOString().slice(0,10)!==data[key])) fail(`${key} phải có dạng ngày YYYY-MM-DD hợp lệ`);
 }
 for (const key of schema.required) if (data[key] === '') fail(`Thiếu ${key}`);
 if (data.month && !/^\d{4}-(0[1-9]|1[0-2])$/.test(data.month)) fail('Tháng phải có dạng YYYY-MM');
 if (type==='contracts' && data.endDate && data.endDate < data.startDate) fail('Ngày kết thúc phải sau ngày bắt đầu');
 if (type==='contracts') {
  if (data.status==='ENDED' && !data.endDate) fail('Hợp đồng đã kết thúc cần ngày kết thúc');
  const overlap=db.prepare("SELECT 1 FROM contracts WHERE roomId=? AND id<>? AND startDate<=? AND (endDate='' OR endDate>=?) LIMIT 1").get(data.roomId,existing?.id || 0,data.endDate || '9999-12-31',data.startDate);
  if (overlap) fail('Thời gian hợp đồng trùng với hợp đồng khác của phòng',409);
  if (existing && data.tenantId!==existing.tenantId && db.prepare('SELECT 1 FROM invoices WHERE contractId=? LIMIT 1').get(existing.id)) fail('Không thể đổi người thuê của hợp đồng đã có hóa đơn',409);
 }
 if (type==='readings' && (data.electricCurrent < data.electricPrevious || data.waterCurrent < data.waterPrevious)) fail('Chỉ số mới không được nhỏ hơn chỉ số cũ');
 if (type==='payments' && data.amount <= 0) fail('Số tiền thanh toán phải lớn hơn 0');
 if (type==='invoices') {
  const contract=db.prepare('SELECT * FROM contracts WHERE id = ?').get(data.contractId);
  if (!contract || contract.roomId !== data.roomId) fail('Hợp đồng không thuộc phòng đã chọn');
  if (contract.startDate.slice(0,7)>data.month || (contract.endDate && contract.endDate.slice(0,7)<data.month)) fail('Tháng hóa đơn nằm ngoài thời gian hợp đồng');
  const reading=db.prepare('SELECT * FROM readings WHERE roomId = ? AND month = ?').get(data.roomId,data.month);
  if (!existing) { if (!reading) fail('Cần nhập chỉ số điện nước của phòng cho tháng này trước khi tạo hóa đơn'); data.rent=contract.rent; data.electricAmount=Math.round((reading.electricCurrent-reading.electricPrevious)*reading.electricRate); data.waterAmount=Math.round((reading.waterCurrent-reading.waterPrevious)*reading.waterRate); }
  data.total=data.rent+data.electricAmount+data.waterAmount+data.serviceAmount-data.discount;
  if (!Number.isSafeInteger(data.total) || data.total<0) fail('Tổng tiền không hợp lệ');
  if (existing && data.total < (db.prepare('SELECT COALESCE(SUM(amount),0) AS paid FROM payments WHERE invoiceId=?').get(existing.id).paid)) fail('Tổng tiền không được nhỏ hơn số đã thanh toán');
 }
 if (type==='payments') {
  const invoice=db.prepare('SELECT total FROM invoices WHERE id=?').get(data.invoiceId); if (!invoice) fail('Không tìm thấy hóa đơn');
  const paid=db.prepare('SELECT COALESCE(SUM(amount),0) AS paid FROM payments WHERE invoiceId=? AND id<>?').get(data.invoiceId,existing?.id || 0).paid;
  if (paid+data.amount>invoice.total) fail('Số tiền vượt công nợ hóa đơn');
 }
 return Object.fromEntries(schema.fields.filter(k=>data[k]!==undefined).map(k=>[k,data[k]]));
}
function invoiceRows(id) {
 const sql=`SELECT i.*, COALESCE(SUM(p.amount),0) AS paid, CASE WHEN COALESCE(SUM(p.amount),0)>=i.total THEN 'PAID' WHEN COALESCE(SUM(p.amount),0)>0 THEN 'PARTIAL' ELSE 'UNPAID' END AS status FROM invoices i LEFT JOIN payments p ON p.invoiceId=i.id ${id?'WHERE i.id=?':''} GROUP BY i.id ORDER BY i.id DESC`;
 return id ? db.prepare(sql).get(id) : db.prepare(sql).all();
}
function row(type,id) { return type==='invoices'?invoiceRows(id):db.prepare(`SELECT * FROM ${type} WHERE id=?`).get(id); }
function syncRooms() { db.exec("UPDATE rooms SET status='OCCUPIED' WHERE id IN (SELECT roomId FROM contracts WHERE status='ACTIVE'); UPDATE rooms SET status='VACANT' WHERE status='OCCUPIED' AND id NOT IN (SELECT roomId FROM contracts WHERE status='ACTIVE')"); }
function json(res,status,data) { res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'}); res.end(JSON.stringify(data)); }
async function body(req) { let text=''; for await (const chunk of req) { text+=chunk; if (text.length>1000000) fail('Dữ liệu quá lớn',413); } try { const value=JSON.parse(text || '{}'); if (!value || Array.isArray(value) || typeof value!=='object') fail('Dữ liệu không hợp lệ'); return value; } catch(e) { if(e.status) throw e; fail('JSON không hợp lệ'); } }
function propertyOf(type, item) {
 if (!item) return null;
 if(type==='properties') return item.id;
 if(type==='rooms') return item.propertyId;
 if(type==='contracts' || type==='readings' || type==='invoices') return db.prepare('SELECT propertyId FROM rooms WHERE id=?').get(item.roomId)?.propertyId;
 if(type==='payments') return db.prepare('SELECT r.propertyId FROM invoices i JOIN rooms r ON r.id=i.roomId WHERE i.id=?').get(item.invoiceId)?.propertyId;
 return null;
}
const permissions={properties:'rooms',rooms:'rooms',tenants:'contracts',contracts:'contracts',readings:'readings',invoices:'invoices',payments:'payments'};
function accessible(user,type,item,write=false) {
 if(!item) return false;
 if(user.role==='TENANT') {
  if(write) return false;
  if(type==='tenants') return item.id===user.tenantId;
  if(type==='contracts') return item.tenantId===user.tenantId;
  if(type==='invoices') return !!db.prepare('SELECT 1 FROM contracts WHERE id=? AND tenantId=?').get(item.contractId,user.tenantId);
  if(type==='payments') return !!db.prepare('SELECT 1 FROM invoices i JOIN contracts c ON c.id=i.contractId WHERE i.id=? AND c.tenantId=?').get(item.invoiceId,user.tenantId);
  if(type==='rooms') return !!db.prepare("SELECT 1 FROM contracts WHERE roomId=? AND tenantId=? AND status='ACTIVE'").get(item.id,user.tenantId);
  if(type==='properties') return !!db.prepare("SELECT 1 FROM contracts c JOIN rooms r ON r.id=c.roomId WHERE r.propertyId=? AND c.tenantId=? AND c.status='ACTIVE'").get(item.id,user.tenantId);
  if(type==='readings') return !!db.prepare('SELECT 1 FROM invoices i JOIN contracts c ON c.id=i.contractId WHERE i.roomId=? AND i.month=? AND c.tenantId=?').get(item.roomId,item.month,user.tenantId);
  return false;
 }
 if(type==='tenants') {
  if(item.ownerId!==user.ownerId) return false;
  if(user.role==='OWNER') return true;
  return db.prepare('SELECT r.propertyId FROM contracts c JOIN rooms r ON r.id=c.roomId WHERE c.tenantId=?').all(item.id).some(r=>auth.canProperty(user,r.propertyId,'contracts'));
 }
 const prop=propertyOf(type,item);
 return !!prop && auth.canProperty(user,prop,permissions[type]);
}
const server=http.createServer(async(req,res)=>{ try {
 const url=new URL(req.url,'http://localhost');
 if(url.pathname.startsWith('/api/') && ['POST','PUT','PATCH','DELETE'].includes(req.method)) {
  if(req.headers['sec-fetch-site']==='cross-site') fail('Nguồn yêu cầu không hợp lệ',403);
  if(req.headers.origin) { let origin; try { origin=new URL(req.headers.origin); } catch { fail('Nguồn yêu cầu không hợp lệ',403); } if(origin.host!==req.headers.host || !['http:','https:'].includes(origin.protocol)) fail('Nguồn yêu cầu không hợp lệ',403); }
  if(!/^application\/json(?:\s*;|$)/i.test(req.headers['content-type']||'')) fail('Cần Content-Type application/json',415);
 }
 if (await auth.handle(req,res,url,body,json)) return;
 let user;
 if(url.pathname.startsWith('/api/')) { user=auth.authenticate(req); if(!user) fail('Vui lòng đăng nhập',401); if(await push.handle(req,res,url,user,body,json)) return; if(await business(req,res,url,user,body,json)) return; }
 if (url.pathname==='/api/dashboard' && req.method==='GET') {
  if(user.role==='TENANT') fail('Không có quyền',403);
  const roomList=db.prepare('SELECT * FROM rooms').all().filter(r=>accessible(user,'rooms',r));
  const invoices=invoiceRows().filter(r=>accessible(user,'invoices',r));
  const month=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Ho_Chi_Minh',year:'numeric',month:'2-digit'}).format(new Date());
  const revenue=db.prepare('SELECT * FROM payments').all().filter(r=>r.paidAt.startsWith(month)&&accessible(user,'payments',r)).reduce((n,r)=>n+r.amount,0);
  const occupied=roomList.filter(r=>r.status==='OCCUPIED').length;
  return json(res,200,{roomsTotal:roomList.length,roomsOccupied:occupied,roomsVacant:roomList.filter(r=>r.status==='VACANT').length,monthlyRevenue:revenue,outstanding:invoices.reduce((n,i)=>n+i.total-i.paid,0),occupancyRate:roomList.length?Math.round(100*occupied/roomList.length):0});
 }
 const match=url.pathname.match(/^\/api\/(properties|rooms|tenants|contracts|readings|invoices|payments)(?:\/(\d+))?\/?$/);
 if (match) {
  const [,type,idText]=match; const id=idText?Number(idText):null;
  if(req.method==='GET') { if(id) {const item=row(type,id); if(!item || !accessible(user,type,item)) fail('Không tìm thấy dữ liệu',404); return json(res,200,item);} return json(res,200,(type==='invoices'?invoiceRows():db.prepare(`SELECT * FROM ${type} ORDER BY id DESC`).all()).filter(item=>accessible(user,type,item))); }
  if(req.method==='POST' && !id || req.method==='PUT' && id) {
   const existing=id?row(type,id):null; if(id&&!existing) fail('Không tìm thấy dữ liệu',404);
   if(type==='payments' && id) fail('Không thể sửa khoản thanh toán đã ghi',409);
   const input=await body(req); if(user.role==='TENANT') fail('Không có quyền',403);
   if(existing && !accessible(user,type,existing,true)) fail('Không tìm thấy dữ liệu',404);
   if(!id && (type==='properties'||type==='tenants') && user.role!=='OWNER') fail('Không có quyền',403);
   const data=prepare(type,input,existing);
   if(!['properties','tenants'].includes(type) && !accessible(user,type,{...data,id:existing?.id},true)) fail('Không có quyền với dữ liệu này',403);
   if(type==='contracts' && !db.prepare('SELECT 1 FROM tenants WHERE id=? AND ownerId=?').get(data.tenantId,user.ownerId)) fail('Người thuê không hợp lệ',400);
   if(type==='properties'||type==='tenants') data.ownerId=user.ownerId;
   const keys=Object.keys(data);
   if(type==='invoices' && existing && db.prepare('SELECT 1 FROM payments WHERE invoiceId=? AND component IS NOT NULL').get(id)) fail('H\u00f3a \u0111\u01a1n \u0111\u00e3 ph\u00e2n b\u1ed5 thanh to\u00e1n kh\u00f4ng th\u1ec3 s\u1eeda',409);
   if(type==='invoices' && existing?.paid && (data.roomId!==existing.roomId || data.contractId!==existing.contractId || data.month!==existing.month)) fail('Không thể đổi phòng, hợp đồng hoặc tháng của hóa đơn đã thanh toán',409);
   if(type==='contracts' && existing && db.prepare('SELECT 1 FROM invoices WHERE contractId=? AND (roomId<>? OR month<substr(?,1,7) OR (?<>\'\' AND month>substr(?,1,7))) LIMIT 1').get(id,data.roomId,data.startDate,data.endDate,data.endDate)) fail('Không thể thay đổi phòng hoặc thời hạn vì hợp đồng đã có hóa đơn',409);
   if(type==='rooms') { const active=db.prepare("SELECT 1 FROM contracts WHERE roomId=? AND status='ACTIVE'").get(id || 0); if(active && data.status!=='OCCUPIED') fail('Phòng có hợp đồng đang hiệu lực phải ở trạng thái đang thuê',409); if(!active && data.status==='OCCUPIED') fail('Phòng cần hợp đồng đang hiệu lực để chuyển sang đang thuê',409); }
   db.exec('BEGIN'); try {
    let resultId=id;
    if(id) db.prepare(`UPDATE ${type} SET ${keys.map(k=>`${k}=?`).join(',')} WHERE id=?`).run(...keys.map(k=>data[k]),id);
    else resultId=Number(db.prepare(`INSERT INTO ${type} (${keys.join(',')}) VALUES (${keys.map(()=>'?').join(',')})`).run(...keys.map(k=>data[k])).lastInsertRowid);
    if(type==='contracts') syncRooms();
    if(type==='invoices' && !id) { const c=db.prepare('SELECT tenantId FROM contracts WHERE id=?').get(data.contractId); const recipients=db.prepare("SELECT id FROM auth_users WHERE tenantId=? AND ownerId=? AND role='TENANT' AND active=1").all(c.tenantId,user.ownerId); for(const recipient of recipients) db.prepare('INSERT INTO notifications(recipientId,title,message) VALUES(?,?,?)').run(recipient.id,'H\u00f3a \u0111\u01a1n m\u1edbi',`H\u00f3a \u0111\u01a1n th\u00e1ng ${data.month} \u0111\u00e3 \u0111\u01b0\u1ee3c t\u1ea1o.`); }
    db.exec('COMMIT'); return json(res,id?200:201,row(type,resultId));
   } catch(e) {db.exec('ROLLBACK'); throw e;}
  }
  if(req.method==='DELETE' && id) { const existing=row(type,id); if(!existing || !accessible(user,type,existing,true)) fail('Không tìm thấy dữ liệu',404); if(type==='payments') fail('Không thể xóa khoản thanh toán đã ghi',409); db.exec('BEGIN'); try { const result=db.prepare(`DELETE FROM ${type} WHERE id=?`).run(id); if(!result.changes) fail('Không tìm thấy dữ liệu',404); if(type==='contracts') syncRooms(); db.exec('COMMIT'); res.writeHead(204); return res.end(); } catch(e) {db.exec('ROLLBACK'); throw e;} }
  fail('Phương thức không được hỗ trợ',405);
 }
 if(url.pathname.startsWith('/api/')) fail('Không tìm thấy API',404);
 if(req.method!=='GET' && req.method!=='HEAD') fail('Phương thức không được hỗ trợ',405);
 const publicDir=path.join(root,'dist'); const relative=decodeURIComponent(url.pathname).replace(/^\/+/, '') || 'index.html'; let file=path.resolve(publicDir,relative);
 if (!file.startsWith(publicDir+path.sep)) fail('Không tìm thấy trang',404);
 if (!fs.existsSync(path.join(publicDir,'index.html'))) fail('Chưa có giao diện đã build. Hãy chạy npm run build.',503);
 if (!fs.existsSync(file) && !path.extname(relative)) file=path.join(publicDir,'index.html');
 const ext=path.extname(file); const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'application/javascript; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.ico':'image/x-icon'};
 if(!fs.existsSync(file) || !fs.statSync(file).isFile()) fail('Không tìm thấy trang',404);
 res.writeHead(200,{'Content-Type':types[ext]||'application/octet-stream'}); if(req.method==='HEAD') return res.end(); fs.createReadStream(file).pipe(res);
 } catch(e) { const message=e.code?.startsWith('SQLITE_CONSTRAINT')||String(e.message).includes('constraint failed')?'Dữ liệu trùng hoặc đang được sử dụng':e.message; if(!res.headersSent) json(res,e.status|| (message!==e.message?409:500),{error:message}); else res.destroy(); }
});
server.listen(Number(process.env.PORT)||3001, process.env.HOST || '127.0.0.1',()=>console.log(`Nhà trọ: http://localhost:${Number(process.env.PORT)||3001}`));
