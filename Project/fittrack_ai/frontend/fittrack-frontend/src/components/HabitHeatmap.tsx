import {useQuery} from '@tanstack/react-query';
import api from '@/api/axios';
import {getApiErrorMessage} from '@/lib/format';
type Cell={day:string;status:string;scheduled:boolean};
type Calendar={cells:Cell[];done:number;eligibleDays:number;currentStreak:number;longestStreak:number;completionRate:number|null;historyVerified:boolean};
const labels:Record<string,string>={DONE:'Đã làm',SKIPPED:'Bỏ qua',MISSED:'Chưa làm',PENDING:'Hôm nay chưa xong',REST:'Ngày nghỉ',UNKNOWN:'Lịch cũ chưa xác minh',BEFORE_START:'Chưa bắt đầu',FUTURE:'Tương lai'};
const colors:Record<string,string>={DONE:'bg-emerald-600',SKIPPED:'bg-amber-400',MISSED:'bg-rose-300',PENDING:'bg-sky-300',REST:'bg-slate-100',UNKNOWN:'bg-slate-300',BEFORE_START:'bg-white',FUTURE:'bg-slate-50'};
export default function HabitHeatmap({id,from,to,revision}:{id:string;from:string;to:string;revision:string}){
 const query=useQuery({queryKey:['habit-calendar',id,from,to,revision],queryFn:async()=>(await api.get<Calendar>(`/todos/habits/${id}/calendar`,{params:{from,to}})).data});
 if(query.isPending)return <p role="status">Đang tải bản đồ thói quen…</p>;
 if(query.error)return <p role="alert">{getApiErrorMessage(query.error,'Không tải được bản đồ thói quen')} <button onClick={()=>void query.refetch()}>Thử lại</button></p>;
 const c=query.data;
 return <section className="space-y-3 rounded-xl bg-slate-50 p-3"><h3 className="font-semibold">Bản đồ thói quen trong khoảng đã chọn</h3><p className="text-sm">Đã làm {c.done}/{c.eligibleDays} ngày đến hạn · Tỷ lệ: {c.completionRate==null?'Chưa đủ dữ liệu':`${c.completionRate.toFixed(0)}%`} · Chuỗi cuối khoảng: {c.currentStreak} · Dài nhất: {c.longestStreak}</p><p className="text-xs text-slate-600">Ngày nghỉ không ngắt chuỗi. Hôm nay chưa hoàn thành chưa tính thất bại. Đổi lịch áp dụng từ ngày mai.</p>{!c.historyVerified&&<p className="text-sm text-amber-800">Một phần lịch cũ chưa xác minh, không dùng để tính tỷ lệ hoặc chuỗi chính xác.</p>}<div className="flex max-w-full flex-wrap gap-1" aria-label="Lịch màu thói quen">{c.cells.map(cell=><span key={cell.day} tabIndex={0} title={`${cell.day}: ${labels[cell.status]}`} aria-label={`${cell.day}: ${labels[cell.status]}`} className={`h-5 w-5 rounded border border-slate-200 ${colors[cell.status]??'bg-slate-300'}`}/>)}</div><div className="flex flex-wrap gap-3 text-xs">{['DONE','SKIPPED','MISSED','PENDING','REST','UNKNOWN'].map(status=><span key={status}><span className={`mr-1 inline-block h-3 w-3 rounded ${colors[status]}`}/>{labels[status]}</span>)}</div></section>;
}
