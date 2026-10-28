import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { searchNutritionFoods, type Food } from '@/api/nutrition.api';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
export default function PantryFoodPicker({selected,onSelect}:{selected:{id:string;name:string}|null;onSelect:(food:Food)=>void}) {
 const [keyword,setKeyword]=useState('');const [page,setPage]=useState(0);
 const foods=useQuery({queryKey:['pantry-food-search',keyword,page],queryFn:()=>searchNutritionFoods(keyword,page)});
 return <div className="space-y-2 rounded-xl border p-3"><p className="font-medium">Thực phẩm đã chọn: {selected?.name||'Chưa chọn'}</p><label>Tìm trong kho thực phẩm<Input value={keyword} placeholder="Tên thực phẩm…" onChange={e=>{setKeyword(e.target.value);setPage(0);}} /></label>
 {foods.isPending&&<p role="status">Đang tìm…</p>}{foods.isError&&<p role="alert">Không tải được thực phẩm. <Button type="button" onClick={()=>void foods.refetch()}>Thử lại</Button></p>}
 <div className="grid max-h-48 gap-2 overflow-y-auto sm:grid-cols-2">{foods.data?.content.map(f=><Button type="button" variant={f.id===selected?.id?'default':'outline'} className="h-auto min-h-10 whitespace-normal text-left" key={f.id} onClick={()=>onSelect(f)}>{f.name} · {f.unit}</Button>)}</div>
 {foods.data?.content.length===0&&<p>Không tìm thấy thực phẩm được duyệt.</p>}<div className="flex items-center gap-2"><Button type="button" variant="outline" disabled={!page||foods.isFetching} onClick={()=>setPage(p=>p-1)}>Trước</Button><span>Trang {page+1}</span><Button type="button" variant="outline" disabled={!foods.data||foods.data.last||foods.isFetching} onClick={()=>setPage(p=>p+1)}>Sau</Button></div></div>;
}
