import {useRef,useState} from 'react';
import {useQuery,useQueryClient} from '@tanstack/react-query';
import {useAuthStore} from '../store/auth.store';
import {canUseFeature} from '../lib/feature-access';
import {getWorkoutPlansPage} from '../api/workout-plan.api';
import {getNutritionConvenience} from '../api/nutrition.api';
import {acceptTemplateShare,createTemplateShare,listTemplateShares,previewTemplateShare,revokeTemplateShare,type ShareKind,type SharePreview} from '../api/template-sharing.api';
import {getApiErrorMessage as apiError} from '../lib/format';
const getApiErrorMessage=(e:unknown)=>apiError(e,'Không thể xử lý. Vui lòng thử lại.');

const labels:Record<ShareKind,string>={WORKOUT_PLAN:'Giáo án',MEAL_COLLECTION:'Bữa ăn / công thức',MEAL_WEEK:'Thực đơn tuần'};
const field='w-full rounded-xl border bg-white p-3';
function templateLines(template:unknown,names:Record<string,string>={}):string[]{
 if(Array.isArray(template))return template.flatMap((v)=>templateLines(v,names));
 if(!template||typeof template!=='object')return [];
 const t=template as Record<string,unknown>;
 const title=String(t.name??'');
 const lines=title?[`${t.dayOffset!==undefined?`Ngày ${Number(t.dayOffset)+1} · `:''}${title}`]:[];
 if(Array.isArray(t.days))for(const day of t.days)lines.push(...templateLines(day,names));
 if(Array.isArray(t.exercises))for(const e of t.exercises as Record<string,unknown>[])lines.push(`  ${names[String(e.exerciseId)]??'Bài tập không còn khả dụng'} · ${e.targetSets} hiệp × ${e.targetReps} lần · ${e.targetWeight} kg · nghỉ ${e.restSeconds??'—'} giây${e.groupType?` · ${e.groupType==='SUPERSET'?'Nhóm liên hoàn':'Vòng tập'}`:''}`);
 if(Array.isArray(t.items))for(const i of t.items as Record<string,unknown>[])lines.push(`  ${names[String(i.foodId)]??'Thực phẩm không còn khả dụng'} · ${i.servingAmount} ${i.servingUnit==='SERVING'?'khẩu phần':i.servingUnit==='GRAM'?'g':'ml'}`);
 return lines;
}
export default function TemplateSharingPage(){
 const user=useAuthStore(s=>s.user),qc=useQueryClient();
 const fitness=canUseFeature(user,'fitnessEnabled'),health=canUseFeature(user,'healthEnabled');
 const kinds=(Object.keys(labels) as ShareKind[]).filter(k=>k==='WORKOUT_PLAN'?fitness:health);
 const [kind,setKind]=useState<ShareKind>(fitness?'WORKOUT_PLAN':'MEAL_COLLECTION'),[inbox,setInbox]=useState(true),[page,setPage]=useState(0),[sourcePage,setSourcePage]=useState(0),[sourceId,setSourceId]=useState(''),[recipient,setRecipient]=useState(''),[days,setDays]=useState(7),[week,setWeek]=useState(''),[preview,setPreview]=useState<SharePreview|null>(null),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
 const operation=useRef<{fingerprint:string;id:string}|null>(null);
 const shares=useQuery({queryKey:['template-shares',user?.userId,inbox,page],queryFn:()=>listTemplateShares(inbox,page),enabled:kinds.length>0});
 const plans=useQuery({queryKey:['share-plan-sources',user?.userId,sourcePage],queryFn:()=>getWorkoutPlansPage(sourcePage,20),enabled:kind==='WORKOUT_PLAN'&&fitness});
 const meals=useQuery({queryKey:['share-meal-sources',user?.userId],queryFn:getNutritionConvenience,enabled:kind==='MEAL_COLLECTION'&&health});
 async function run(action:()=>Promise<void>){if(busy)return;setBusy(true);setMessage('');try{await action();await qc.invalidateQueries({queryKey:['template-shares']});}catch(e){setMessage(getApiErrorMessage(e));}finally{setBusy(false);}}
 if(!kinds.length)return <p className="p-6">Bạn chưa có quyền chia sẻ mẫu luyện tập hoặc dinh dưỡng.</p>;
 const sources=kind==='WORKOUT_PLAN'?(plans.data?.content??[]):[...(meals.data?.savedMeals??[]),...(meals.data?.recipes??[])];
 return <main className="space-y-5 p-4 sm:p-6"><h1 className="text-2xl font-bold">Chia sẻ bản mẫu</h1><p>Chỉ gửi mẫu bạn chủ động chọn tới một tài khoản có quyền. Không gửi lịch sử tập, nhật ký đã ăn, số đo hay dữ liệu tài chính. Bản sao thuộc người nhận; thu hồi không xóa bản đã sao chép.</p>
 {message&&<p role="status" className="rounded-xl bg-amber-50 p-3">{message}</p>}
 <fieldset disabled={busy} className="space-y-5"><form className="grid gap-4 rounded-2xl border bg-white p-4 sm:grid-cols-2" onSubmit={e=>{e.preventDefault();if(!confirm('Gửi bản mẫu này tới email đã nhập? Người nhận có thể giữ bản sao độc lập.'))return;void run(async()=>{const payload={kind,sourceId,recipientEmail:recipient.trim(),expiresInDays:days};const fingerprint=JSON.stringify(payload);if(operation.current?.fingerprint!==fingerprint)operation.current={fingerprint,id:crypto.randomUUID()};await createTemplateShare({...payload,operationId:operation.current.id});operation.current=null;setMessage('Đã gửi bản mẫu.');});}}>
 <label>Loại mẫu<select className={field} value={kind} onChange={e=>{setKind(e.target.value as ShareKind);setSourceId('');setSourcePage(0);}}>{kinds.map(k=><option key={k} value={k}>{labels[k]}</option>)}</select></label>
 <label>Email tài khoản người nhận<input required type="email" maxLength={254} className={field} value={recipient} onChange={e=>setRecipient(e.target.value)}/></label>
 {kind==='MEAL_WEEK'?<label>Thứ Hai của tuần muốn chia sẻ<input required type="date" className={field} value={sourceId} onChange={e=>{const value=e.target.value;if(value&&new Date(`${value}T12:00:00`).getDay()!==1){setMessage('Chọn ngày thứ Hai.');return;}setSourceId(value);}}/></label>:<label>Bản mẫu của bạn<select aria-label="Bản mẫu của bạn" required className={field} value={sourceId} onChange={e=>setSourceId(e.target.value)}><option value="">Chọn bản mẫu</option>{sources.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select>{kind==='WORKOUT_PLAN'&&<span className="flex gap-3"><button type="button" disabled={sourcePage===0} onClick={()=>{setSourcePage(p=>p-1);setSourceId('');}}>Trước</button>Trang {sourcePage+1}<button type="button" disabled={sourcePage+1>=(plans.data?.totalPages??0)} onClick={()=>{setSourcePage(p=>p+1);setSourceId('');}}>Sau</button></span>}</label>}
 <label>Hiệu lực (ngày)<input required type="number" min={1} max={30} className={field} value={days} onChange={e=>setDays(Number(e.target.value))}/></label><button className="rounded-xl bg-emerald-800 p-3 text-white" disabled={!sourceId}>Gửi bản mẫu</button></form>
 {(plans.error||meals.error)&&<p role="alert">{getApiErrorMessage(plans.error??meals.error)}</p>}
 <div className="flex gap-4"><button onClick={()=>{setInbox(true);setPage(0);setPreview(null);}} aria-pressed={inbox}>Được chia sẻ</button><button onClick={()=>{setInbox(false);setPage(0);setPreview(null);}} aria-pressed={!inbox}>Đã gửi</button><button onClick={()=>void shares.refetch()}>Làm mới</button></div>
 {shares.isLoading&&<p>Đang tải…</p>}{shares.error&&<p role="alert">{getApiErrorMessage(shares.error)}</p>}
 <div className="grid gap-4 lg:grid-cols-2">{shares.data?.content.map(s=><article key={s.id} className="space-y-3 rounded-2xl border bg-white p-4"><h2 className="font-bold">{s.title}</h2><p>{labels[s.kind]} · {inbox?`Từ ${s.ownerName}`:`Tới ${s.recipientName}`}</p><p>Hết hạn: {s.expiresAt.replace('T',' ')} · {!s.active?'Đã thu hồi':s.copiedAt?'Đã sao chép':'Chưa sao chép'}</p><div className="flex gap-4"><button onClick={()=>void run(async()=>setPreview(await previewTemplateShare(s.id)))}>Xem mẫu</button>{!inbox&&s.active&&<button onClick={()=>{if(confirm('Thu hồi quyền truy cập? Bản đã sao chép vẫn được giữ.'))void run(async()=>{await revokeTemplateShare(s);setPreview(null);});}}>Thu hồi</button>}</div></article>)}</div>
 {shares.data?.content.length===0&&<p>Chưa có bản mẫu.</p>}<div className="flex gap-4"><button disabled={page===0} onClick={()=>setPage(p=>p-1)}>Trước</button>{page+1}/{Math.max(1,shares.data?.totalPages??0)}<button disabled={page+1>=(shares.data?.totalPages??0)} onClick={()=>setPage(p=>p+1)}>Sau</button></div>
 {preview&&<section className="space-y-4 rounded-2xl border bg-white p-4"><h2 className="font-bold">{preview.share.title}</h2><ul>{templateLines(preview.template,preview.itemNames).map((line,i)=><li className="whitespace-pre-wrap py-1" key={i}>{line}</li>)}</ul>{preview.unavailableItems.length>0&&<p role="alert">Có {preview.unavailableItems.length} món / bài tập không còn khả dụng. Nhờ người gửi cập nhật và chia sẻ lại.</p>}{inbox&&<><p>Sao chép không tạo buổi tập hoàn thành hoặc ghi nhật ký ăn uống.</p>{preview.share.kind==='MEAL_WEEK'&&<label>Thứ Hai tuần đích<input type="date" className={field} value={week} onChange={e=>setWeek(e.target.value)}/></label>}<button className="rounded-xl bg-emerald-800 p-3 text-white" disabled={preview.unavailableItems.length>0||!preview.share.active||(preview.share.kind==='MEAL_WEEK'&&!week)} onClick={()=>{if(confirm('Tạo bản sao riêng trong tài khoản của bạn?'))void run(async()=>{await acceptTemplateShare(preview.share.id,preview.share.kind==='MEAL_WEEK'?week:undefined);setPreview(null);setMessage('Đã sao chép mẫu vào tài khoản của bạn.');});}}>Sao chép vào tài khoản của tôi</button></>}<button className="ml-4" onClick={()=>setPreview(null)}>Đóng</button></section>}
 </fieldset></main>;
}
