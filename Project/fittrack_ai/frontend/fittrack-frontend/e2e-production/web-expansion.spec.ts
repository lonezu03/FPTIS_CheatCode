import {test,expect,type Page} from '@playwright/test';
async function mock(page:Page,admin=true){
 const writes:string[]=[];
 await page.route('**/api/**',async route=>{
  const request=route.request(),url=new URL(request.url()),path=url.pathname;
  if(request.method()!=='GET'&&!path.endsWith('/auth/refresh'))writes.push(path);
  const user={id:'u',userId:'u',token:'test',role:admin?'ADMIN':'USER',fullName:'Kiểm thử',email:'test@example.invalid',fitnessEnabled:true,healthEnabled:admin,todoEnabled:admin,financeEnabled:admin};
  const empty={content:[],totalPages:0,totalElements:0,page:0,number:0,size:15,last:true,counts:{today:0,overdue:0,upcoming:0,done:0,all:0}};
  let json:unknown=empty;
  if(path.endsWith('/auth/refresh')||path.endsWith('/users/me'))json=user;
  else if(path.endsWith('/notifications'))json={unreadCount:0,notifications:[]};
  else if(path.endsWith('/pantry/suggestions')||path.endsWith('/workout-plans'))json=[];
  else if(path.endsWith('/focus/active'))json=null;
  else if(path.endsWith('/week-cost'))json={week:'2026-10-26',referenceDate:'2026-10-28',currency:'VND',knownSubtotal:0,pricedLines:0,totalLines:0,coverage:0,items:[]};
  else if(path.endsWith('/personal-reports/monthly'))json={month:'2026-10-01',through:'2026-10-28',timezone:'Asia/Ho_Chi_Minh',sections:['TRAINING'],training:{sessions:0,trainingDays:0,workingSets:0,volumeKgReps:0},nutrition:null,habits:null,finance:null,focus:null,disclaimer:'Không gồm nhật ký riêng.'};
  await route.fulfill({json});
 });return writes;
}
test('new web screens fit phone widths and opening them does not write data',async({page})=>{
 const errors:string[]=[];page.on('pageerror',e=>errors.push(e.message));const writes=await mock(page);
 for(const width of [320,390]){
  await page.setViewportSize({width,height:844});
  for(const [path,title] of [['/pantry','Thực phẩm đang có'],['/purchase-prices','Giá mua thực phẩm'],['/finance/shared','Chi tiêu chung'],['/focus','Chế độ tập trung'],['/training-comparison','So sánh tập luyện'],['/reports/monthly','Báo cáo cá nhân theo tháng']]){
   await page.goto(path);await expect(page.getByRole('heading',{name:title,exact:true}).last()).toBeVisible();
   expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`${path} at ${width}`).toBe(true);
  }
 }
 expect(writes).toEqual([]);expect(errors).toEqual([]);
});
test('monthly report offers only permitted sections on a fitness-only account',async({page})=>{
 await mock(page,false);await page.setViewportSize({width:390,height:844});await page.goto('/reports/monthly');await expect(page.getByRole('checkbox',{name:'Luyện tập',exact:true})).toBeVisible();await expect(page.getByRole('checkbox',{name:'Dinh dưỡng',exact:true})).toHaveCount(0);await expect(page.getByRole('checkbox',{name:'Thu chi cá nhân',exact:true})).toHaveCount(0);await page.getByRole('checkbox',{name:'Luyện tập',exact:true}).check();await page.getByRole('button',{name:'Xem báo cáo',exact:true}).click();await expect(page.getByText('Luyện tập thực tế',{exact:true})).toBeVisible();
});
