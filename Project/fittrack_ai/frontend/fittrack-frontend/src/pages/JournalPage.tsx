import { useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BookHeart, Clock3, History, Library, Pencil, Plus, RefreshCw, Save, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  createJournalEntry, deleteJournalEntry, getJournalEntries, getJournalPrompts,
  getJournalSettings, getJournalToday, skipJournalPrompt, updateJournalEntry,
  updateJournalSettings, type JournalEntry, type JournalMood, type JournalOrigin,
} from "@/api/journal.api";
import DataPagination from "@/components/common/DataPagination";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

const moods: Array<{ value: JournalMood; icon: string; label: string }> = [
  { value: "VERY_LOW", icon: "😞", label: "Rất tệ" }, { value: "LOW", icon: "🙁", label: "Không ổn" },
  { value: "NEUTRAL", icon: "😐", label: "Bình thường" }, { value: "GOOD", icon: "🙂", label: "Tốt" },
  { value: "VERY_GOOD", icon: "😊", label: "Rất tốt" },
];
const categories: Record<string, string> = { OBSERVATION: "Quan sát", SELF: "Bản thân", MEMORY: "Ký ức", IMAGINATION: "Tưởng tượng", REFLECTION: "Chiêm nghiệm", RELATIONSHIP: "Mối quan hệ", FUTURE: "Tương lai", QUIRKY: "Khác lạ" };
const depths: Record<string, string> = { LIGHT: "Nhẹ nhàng", MEDIUM: "Suy ngẫm", DEEP: "Sâu sắc" };

export default function JournalPage() {
  const qc = useQueryClient();
  const [tab, setTab] = useState<"today" | "history" | "library">("today");
  const [body, setBody] = useState("");
  const [mood, setMood] = useState<JournalMood | null>(null);
  const [freeOpen, setFreeOpen] = useState(false);
  const [editing, setEditing] = useState<JournalEntry | null>(null);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState("");
  const [origin, setOrigin] = useState<JournalOrigin | "">("");

  const today = useQuery({ queryKey: ["journal-today"], queryFn: getJournalToday });
  const history = useQuery({ queryKey: ["journal-entries", search, origin, page, pageSize], queryFn: () => getJournalEntries({ q: search, origin: origin || undefined, page: page - 1, size: pageSize }), enabled: tab === "history" });
  const library = useQuery({ queryKey: ["journal-prompts"], queryFn: () => getJournalPrompts({ page: 0, size: 100 }), enabled: tab === "library" });
  const settings = useQuery({ queryKey: ["journal-settings"], queryFn: getJournalSettings });
  const refresh = () => { qc.invalidateQueries({ queryKey: ["journal-today"] }); qc.invalidateQueries({ queryKey: ["journal-entries"] }); };
  const saveToday = useMutation({ mutationFn: () => createJournalEntry({ origin: "PROMPT", promptId: today.data!.prompt.id, body, mood }), onSuccess: () => { toast.success("Đã lưu trang nhật ký hôm nay"); setBody(""); refresh(); }, onError: () => toast.error("Chưa thể lưu nhật ký") });
  const skip = useMutation({ mutationFn: skipJournalPrompt, onSuccess: () => { setBody(""); qc.invalidateQueries({ queryKey: ["journal-today"] }); }, onError: () => toast.error("Chưa thể đổi câu hỏi") });
  const remove = useMutation({ mutationFn: deleteJournalEntry, onSuccess: () => { toast.success("Đã xóa bài viết"); refresh(); } });

  return <div className="space-y-6">
    <PageHeader title="Nhật ký" description="Một không gian riêng để ghi lại suy nghĩ, ký ức và những điều bạn muốn hiểu rõ hơn về chính mình." />
    <div className="flex flex-wrap gap-2 rounded-2xl border bg-white p-2">
      <Tab active={tab === "today"} onClick={() => setTab("today")} icon={BookHeart}>Hôm nay</Tab>
      <Tab active={tab === "history"} onClick={() => setTab("history")} icon={History}>Lịch sử</Tab>
      <Tab active={tab === "library"} onClick={() => setTab("library")} icon={Library}>Kho câu hỏi</Tab>
      <Button className="ml-auto" variant="outline" onClick={() => { setEditing(null); setFreeOpen(true); }}><Plus className="size-4" /> Viết tự do</Button>
    </div>

    {tab === "today" && <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_21rem]">
      <Card className="overflow-hidden border-emerald-100 bg-gradient-to-br from-white to-emerald-50/70"><CardContent className="space-y-5 p-6 md:p-8">
        {today.isLoading ? <p>Đang chọn câu hỏi dành cho bạn...</p> : today.data && <>
          <div className="flex flex-wrap gap-2 text-xs"><span className="rounded-full bg-emerald-100 px-3 py-1 font-medium text-emerald-800">{categories[today.data.prompt.category]}</span><span className="rounded-full bg-white px-3 py-1 text-slate-600">{depths[today.data.prompt.depth]}</span></div>
          <h2 className="max-w-3xl text-2xl font-semibold leading-snug md:text-3xl">{today.data.prompt.content}</h2>
          {today.data.answered ? <div className="rounded-2xl border border-emerald-200 bg-white p-5"><p className="mb-2 text-sm font-semibold text-emerald-700">Bạn đã viết hôm nay</p><p className="whitespace-pre-wrap leading-7">{today.data.entry?.body}</p></div> : <>
            <textarea className="min-h-56 w-full resize-y rounded-2xl border border-slate-200 bg-white p-4 outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100" placeholder="Hãy viết điều đầu tiên xuất hiện trong đầu bạn..." value={body} maxLength={20000} onChange={(e) => setBody(e.target.value)} />
            <MoodPicker value={mood} onChange={setMood} />
            <div className="flex flex-wrap justify-between gap-3"><Button variant="outline" disabled={skip.isPending} onClick={() => skip.mutate()}><RefreshCw className="size-4" /> Đổi câu hỏi</Button><Button disabled={!body.trim() || saveToday.isPending} onClick={() => saveToday.mutate()}><Save className="size-4" /> Lưu nhật ký</Button></div>
          </>}
        </>}
      </CardContent></Card>
      <ReminderCard value={settings.data} pending={settings.isLoading} onSave={(enabled, time) => updateJournalSettings({ reminderEnabled: enabled, reminderTime: time }).then(() => { qc.invalidateQueries({ queryKey: ["journal-settings"] }); toast.success("Đã cập nhật nhắc nhở"); })} />
    </div>}

    {tab === "history" && <Card><CardContent className="p-0"><div className="grid gap-3 border-b p-4 md:grid-cols-[1fr_13rem]"><Input placeholder="Tìm trong tiêu đề, nội dung, câu hỏi..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} /><select className="h-10 rounded-xl border bg-white px-3" value={origin} onChange={(e) => { setOrigin(e.target.value as JournalOrigin | ""); setPage(1); }}><option value="">Tất cả bài viết</option><option value="PROMPT">Theo câu hỏi</option><option value="FREEFORM">Viết tự do</option></select></div>
      <div className="divide-y">{history.data?.content.map((entry) => <article key={entry.id} className="group p-5"><div className="flex items-start justify-between gap-4"><div className="min-w-0"><div className="mb-2 flex flex-wrap items-center gap-2 text-xs text-slate-500"><span>{new Date(entry.entryDate + "T00:00:00").toLocaleDateString("vi-VN")}</span><span>·</span><span>{entry.origin === "PROMPT" ? "Theo câu hỏi" : "Viết tự do"}</span>{entry.mood && <span>{moods.find((m) => m.value === entry.mood)?.icon}</span>}</div><h3 className="font-semibold">{entry.title || entry.prompt?.content || "Một trang nhật ký"}</h3><p className="mt-2 line-clamp-3 whitespace-pre-wrap text-sm leading-6 text-slate-600">{entry.body}</p></div><div className="flex gap-1"><Button size="icon" variant="ghost" onClick={() => { setEditing(entry); setFreeOpen(true); }}><Pencil className="size-4" /></Button><Button size="icon" variant="ghost" className="text-red-600" onClick={() => confirm("Xóa bài nhật ký này?") && remove.mutate(entry.id)}><Trash2 className="size-4" /></Button></div></div></article>)}{history.data?.content.length === 0 && <p className="p-10 text-center text-slate-500">Chưa có bài viết phù hợp.</p>}</div>
      {history.data && <DataPagination page={page} pageSize={pageSize} totalItems={history.data.totalElements} totalPages={history.data.totalPages} onPageChange={setPage} onPageSizeChange={(v) => { setPageSize(v); setPage(1); }} />}</CardContent></Card>}

    {tab === "library" && <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{library.data?.content.map((p) => <Card key={p.id}><CardContent className="space-y-3 p-5"><div className="flex gap-2 text-xs"><span className="rounded-full bg-emerald-50 px-2.5 py-1 text-emerald-700">{categories[p.category]}</span><span className="rounded-full bg-slate-100 px-2.5 py-1 text-slate-600">{depths[p.depth]}</span></div><p className="font-medium leading-6">{p.content}</p></CardContent></Card>)}</div>}
    <EntryDialog open={freeOpen} entry={editing} onClose={() => setFreeOpen(false)} onSaved={() => { setFreeOpen(false); refresh(); }} />
  </div>;
}

function Tab({ active, onClick, icon: Icon, children }: { active: boolean; onClick: () => void; icon: typeof BookHeart; children: React.ReactNode }) { return <button className={`flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-medium ${active ? "bg-emerald-100 text-emerald-800" : "text-slate-600 hover:bg-slate-50"}`} onClick={onClick}><Icon className="size-4" />{children}</button>; }
function MoodPicker({ value, onChange }: { value: JournalMood | null; onChange: (v: JournalMood | null) => void }) { return <div><p className="mb-2 text-sm font-medium">Bạn đang cảm thấy thế nào? <span className="font-normal text-slate-400">(không bắt buộc)</span></p><div className="flex flex-wrap gap-2">{moods.map((m) => <button key={m.value} title={m.label} onClick={() => onChange(value === m.value ? null : m.value)} className={`rounded-xl border px-3 py-2 text-xl ${value === m.value ? "border-emerald-500 bg-emerald-50" : "bg-white"}`}>{m.icon}</button>)}</div></div>; }

function ReminderCard({ value, pending, onSave }: { value?: { reminderEnabled: boolean; reminderTime: string }; pending: boolean; onSave: (enabled: boolean, time: string) => Promise<unknown> }) { const [enabled, setEnabled] = useState<boolean | null>(null); const [time, setTime] = useState(""); const actualEnabled = enabled ?? value?.reminderEnabled ?? false; const actualTime = time || value?.reminderTime?.slice(0, 5) || "21:30"; return <Card><CardContent className="space-y-4 p-5"><div className="flex items-center gap-2"><Clock3 className="size-5 text-emerald-700" /><h3 className="font-semibold">Nhắc viết nhật ký</h3></div><p className="text-sm leading-6 text-slate-600">Một lời nhắc nhẹ nhàng, chỉ vào giờ bạn chọn.</p><label className="flex items-center gap-3 text-sm"><input type="checkbox" checked={actualEnabled} onChange={(e) => setEnabled(e.target.checked)} /> Bật nhắc nhở</label><Input type="time" value={actualTime} disabled={!actualEnabled} onChange={(e) => setTime(e.target.value)} /><Button className="w-full" variant="outline" disabled={pending} onClick={() => onSave(actualEnabled, actualTime)}>Lưu nhắc nhở</Button></CardContent></Card>; }

function EntryDialog({ open, entry, onClose, onSaved }: { open: boolean; entry: JournalEntry | null; onClose: () => void; onSaved: () => void }) { const [title, setTitle] = useState(""); const [body, setBody] = useState(""); const [mood, setMood] = useState<JournalMood | null>(null); const [busy, setBusy] = useState(false); const initialize = (next: boolean) => { if (next) { setTitle(entry?.title ?? ""); setBody(entry?.body ?? ""); setMood(entry?.mood ?? null); } else onClose(); }; const submit = async (e: FormEvent) => { e.preventDefault(); setBusy(true); try { const payload = { origin: entry?.origin ?? "FREEFORM" as JournalOrigin, promptId: entry?.prompt?.id, entryDate: entry?.entryDate, title, body, mood }; if (entry) await updateJournalEntry(entry.id, payload); else await createJournalEntry(payload); toast.success(entry ? "Đã cập nhật bài viết" : "Đã lưu bài viết"); onSaved(); } catch { toast.error("Chưa thể lưu bài viết"); } finally { setBusy(false); } }; return <Dialog open={open} onOpenChange={initialize}><DialogContent className="max-w-2xl"><form onSubmit={submit}><DialogHeader><DialogTitle>{entry ? "Chỉnh sửa trang nhật ký" : "Viết tự do"}</DialogTitle></DialogHeader><div className="space-y-4 py-5"><Input placeholder="Tiêu đề (không bắt buộc)" value={title} maxLength={200} onChange={(e) => setTitle(e.target.value)} /><textarea className="min-h-64 w-full rounded-2xl border p-4 outline-none focus:border-emerald-500" required maxLength={20000} placeholder="Hôm nay bạn muốn ghi lại điều gì?" value={body} onChange={(e) => setBody(e.target.value)} /><MoodPicker value={mood} onChange={setMood} /></div><DialogFooter><Button type="button" variant="outline" onClick={onClose}>Hủy</Button><Button disabled={busy || !body.trim()}><Save className="size-4" /> Lưu bài viết</Button></DialogFooter></form></DialogContent></Dialog>; }
