import { useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, Pencil, Plus } from "lucide-react";
import { toast } from "sonner";
import {
  archiveAdminJournalPack,
  createAdminJournalPack,
  createAdminJournalPrompt,
  getAdminJournalPacks,
  getAdminJournalPrompts,
  updateAdminJournalPack,
  updateAdminJournalPrompt,
  type AdminJournalPack,
  type JournalCategory,
  type JournalDepth,
  type JournalPrompt,
} from "@/api/journal.api";
import DataPagination from "@/components/common/DataPagination";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

const categories: Array<[JournalCategory, string]> = [["OBSERVATION","Quan sát"],["SELF","Bản thân"],["MEMORY","Ký ức"],["IMAGINATION","Tưởng tượng"],["REFLECTION","Chiêm nghiệm"],["RELATIONSHIP","Mối quan hệ"],["FUTURE","Tương lai"],["QUIRKY","Khác lạ"]];
const depths: Array<[JournalDepth, string]> = [["LIGHT","Nhẹ nhàng"],["MEDIUM","Suy ngẫm"],["DEEP","Sâu sắc"]];

export default function AdminJournalPromptsPage() {
  const qc = useQueryClient();
  const [page,setPage]=useState(1); const [size,setSize]=useState(20); const [q,setQ]=useState("");
  const [editing,setEditing]=useState<JournalPrompt|null>(null); const [promptOpen,setPromptOpen]=useState(false);
  const [editingPack,setEditingPack]=useState<AdminJournalPack|null>(null); const [packOpen,setPackOpen]=useState(false);
  const list=useQuery({queryKey:["admin-journal-prompts",q,page,size],queryFn:()=>getAdminJournalPrompts({q,page:page-1,size})});
  const packs=useQuery({queryKey:["admin-journal-packs"],queryFn:getAdminJournalPacks});
  const refreshed=()=>{setPromptOpen(false);setPackOpen(false);void qc.invalidateQueries({queryKey:["admin-journal-prompts"]});void qc.invalidateQueries({queryKey:["admin-journal-packs"]});};

  return <div className="space-y-6">
    <div className="flex flex-wrap items-end justify-between gap-4"><PageHeader title="Câu hỏi nhật ký" description="Quản lý kho câu hỏi và các bộ chủ đề. Admin không thể xem nội dung nhật ký riêng của người dùng."/><div className="flex gap-2"><Button variant="outline" onClick={()=>{setEditingPack(null);setPackOpen(true)}}><Plus className="size-4"/>Thêm bộ câu hỏi</Button><Button onClick={()=>{setEditing(null);setPromptOpen(true)}}><Plus className="size-4"/>Thêm câu hỏi</Button></div></div>
    <Card><CardContent className="p-5"><h2 className="mb-4 text-lg font-semibold">Bộ câu hỏi</h2><div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">{packs.data?.map(pack=><div key={pack.id} className={`rounded-2xl border p-4 ${pack.active?"bg-white":"bg-slate-50 opacity-70"}`}><div className="flex items-start justify-between gap-2"><div><span className="text-2xl">{pack.icon||"📚"}</span><h3 className="font-semibold">{pack.name}</h3></div><Button size="icon" variant="ghost" aria-label="Sửa bộ câu hỏi" onClick={()=>{setEditingPack(pack);setPackOpen(true)}}><Pencil className="size-4"/></Button></div><p className="mt-2 text-sm text-slate-500">{pack.description}</p><p className="mt-2 text-xs text-slate-500">{pack.promptCount} câu · {pack.active?"Đang dùng":"Đã ẩn"}</p></div>)}</div></CardContent></Card>
    <Card><CardContent className="p-0"><div className="border-b p-4"><Input placeholder="Tìm câu hỏi..." value={q} onChange={e=>{setQ(e.target.value);setPage(1)}}/></div><div className="divide-y">{list.data?.content.map(prompt=><div key={prompt.id} className="flex items-start justify-between gap-4 p-4"><div><div className="mb-1 flex flex-wrap gap-2 text-xs text-slate-500"><span>{categories.find(x=>x[0]===prompt.category)?.[1]}</span><span>·</span><span>{depths.find(x=>x[0]===prompt.depth)?.[1]}</span>{prompt.pack&&<><span>·</span><span>{prompt.pack.icon} {prompt.pack.name}</span></>}<span className={prompt.active?"text-emerald-700":"text-red-600"}>· {prompt.active?"Đang dùng":"Đã ẩn"}</span></div><p className="font-medium">{prompt.content}</p></div><Button size="icon" variant="ghost" aria-label="Sửa câu hỏi" onClick={()=>{setEditing(prompt);setPromptOpen(true)}}><Pencil className="size-4"/></Button></div>)}</div>{list.data&&<DataPagination page={page} pageSize={size} totalItems={list.data.totalElements} totalPages={list.data.totalPages} onPageChange={setPage} onPageSizeChange={v=>{setSize(v);setPage(1)}}/>}</CardContent></Card>
    <PromptDialog key={`prompt-${editing?.id??"new"}-${promptOpen}`} open={promptOpen} prompt={editing} packs={packs.data??[]} onClose={()=>setPromptOpen(false)} onSaved={()=>{toast.success("Đã lưu câu hỏi");refreshed()}}/>
    <PackDialog key={`pack-${editingPack?.id??"new"}-${packOpen}`} open={packOpen} pack={editingPack} onClose={()=>setPackOpen(false)} onSaved={()=>{toast.success("Đã lưu bộ câu hỏi");refreshed()}}/>
  </div>;
}

function PromptDialog({open,prompt,packs,onClose,onSaved}:{open:boolean;prompt:JournalPrompt|null;packs:AdminJournalPack[];onClose:()=>void;onSaved:()=>void}) {
  const [content,setContent]=useState(prompt?.content??""); const [category,setCategory]=useState<JournalCategory>(prompt?.category??"REFLECTION"); const [depth,setDepth]=useState<JournalDepth>(prompt?.depth??"MEDIUM"); const [active,setActive]=useState(prompt?.active??true); const [packId,setPackId]=useState(prompt?.pack?.id??"");
  const mutation=useMutation({mutationFn:()=>{const payload={content,category,depth,active,packId:packId||null};return prompt?updateAdminJournalPrompt(prompt.id,payload):createAdminJournalPrompt(payload)},onSuccess:onSaved,onError:()=>toast.error("Chưa thể lưu câu hỏi")});
  const submit=(e:FormEvent)=>{e.preventDefault();mutation.mutate()};
  return <Dialog open={open} onOpenChange={value=>{if(!value)onClose()}}><DialogContent><form onSubmit={submit}><DialogHeader><DialogTitle>{prompt?"Sửa câu hỏi":"Thêm câu hỏi"}</DialogTitle></DialogHeader><div className="space-y-4 py-5"><textarea className="min-h-32 w-full rounded-xl border p-3" required maxLength={1000} value={content} onChange={e=>setContent(e.target.value)} placeholder="Nội dung câu hỏi..."/><div className="grid gap-3 sm:grid-cols-2"><select className="h-10 rounded-xl border bg-white px-3" value={category} onChange={e=>setCategory(e.target.value as JournalCategory)}>{categories.map(([v,l])=><option key={v} value={v}>{l}</option>)}</select><select className="h-10 rounded-xl border bg-white px-3" value={depth} onChange={e=>setDepth(e.target.value as JournalDepth)}>{depths.map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></div><select className="h-10 w-full rounded-xl border bg-white px-3" value={packId} onChange={e=>setPackId(e.target.value)}><option value="">Không thuộc bộ câu hỏi</option>{packs.filter(x=>x.active||x.id===packId).map(pack=><option key={pack.id} value={pack.id}>{pack.icon} {pack.name}</option>)}</select><label className="flex gap-2 text-sm"><input type="checkbox" checked={active} onChange={e=>setActive(e.target.checked)}/>Cho phép sử dụng</label></div><DialogFooter><Button type="button" variant="outline" onClick={onClose}>Hủy</Button><Button disabled={mutation.isPending||!content.trim()}>Lưu</Button></DialogFooter></form></DialogContent></Dialog>;
}

function PackDialog({open,pack,onClose,onSaved}:{open:boolean;pack:AdminJournalPack|null;onClose:()=>void;onSaved:()=>void}) {
  const [name,setName]=useState(pack?.name??""); const [description,setDescription]=useState(pack?.description??""); const [icon,setIcon]=useState(pack?.icon??"📚"); const [sortOrder,setSortOrder]=useState(pack?.sortOrder??0); const [active,setActive]=useState(pack?.active??true);
  const save=useMutation({mutationFn:()=>{const payload={name,description,icon,sortOrder,active};return pack?updateAdminJournalPack(pack.id,payload):createAdminJournalPack(payload)},onSuccess:onSaved,onError:()=>toast.error("Chưa thể lưu bộ câu hỏi")});
  const archive=useMutation({mutationFn:()=>archiveAdminJournalPack(pack!.id),onSuccess:onSaved,onError:()=>toast.error("Chưa thể ẩn bộ câu hỏi")});
  return <Dialog open={open} onOpenChange={value=>{if(!value)onClose()}}><DialogContent><form onSubmit={e=>{e.preventDefault();save.mutate()}}><DialogHeader><DialogTitle>{pack?"Sửa bộ câu hỏi":"Thêm bộ câu hỏi"}</DialogTitle></DialogHeader><div className="space-y-4 py-5"><Input required maxLength={120} value={name} onChange={e=>setName(e.target.value)} placeholder="Tên bộ câu hỏi"/><Input maxLength={500} value={description} onChange={e=>setDescription(e.target.value)} placeholder="Mô tả ngắn"/><div className="grid grid-cols-[1fr_2fr] gap-3"><Input maxLength={20} value={icon} onChange={e=>setIcon(e.target.value)} placeholder="Biểu tượng"/><Input type="number" min={0} value={sortOrder} onChange={e=>setSortOrder(Number(e.target.value))} placeholder="Thứ tự"/></div><label className="flex gap-2 text-sm"><input type="checkbox" checked={active} onChange={e=>setActive(e.target.checked)}/>Đang hoạt động</label></div><DialogFooter className="justify-between sm:justify-between">{pack?.active?<Button type="button" variant="outline" className="text-red-600" disabled={archive.isPending} onClick={()=>confirm("Ẩn bộ câu hỏi này? Các bài nhật ký cũ vẫn được giữ.")&&archive.mutate()}><Archive className="size-4"/>Ẩn bộ</Button>:<span/>}<div className="flex gap-2"><Button type="button" variant="outline" onClick={onClose}>Hủy</Button><Button disabled={save.isPending||!name.trim()}>Lưu</Button></div></DialogFooter></form></DialogContent></Dialog>;
}
