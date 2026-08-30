import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Bell, CalendarDays, ChevronLeft, ChevronRight, Clock3, ListTodo, Pencil, Plus, Repeat2, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  createSchedule,
  deleteSchedule,
  getCalendar,
  getSchedule,
  updateSchedule,
  type CalendarEntry,
  type ScheduleItem,
  type SchedulePayload,
} from '@/api/schedule.api';
import { getApiErrorMessage } from '@/lib/format';
import PageHeader from '@/components/PageHeader';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

type CalendarView = 'DAY' | 'WEEK' | 'MONTH' | 'LIST';
type EventDraft = {
  title: string;
  description: string;
  category: ScheduleItem['category'];
  startAt: string;
  endAt: string;
  repeatRule: ScheduleItem['repeatRule'];
  repeatInterval: string;
  repeatEndAt: string;
  daysOfWeek: string[];
  reminderMinutes: string;
  reminderEnabled: boolean;
};

const weekDays = [
  ['MONDAY', 'T2'], ['TUESDAY', 'T3'], ['WEDNESDAY', 'T4'], ['THURSDAY', 'T5'],
  ['FRIDAY', 'T6'], ['SATURDAY', 'T7'], ['SUNDAY', 'CN'],
] as const;

const emptyDraft = (): EventDraft => ({
  title: '', description: '', category: 'PERSONAL', startAt: '', endAt: '', repeatRule: 'NONE',
  repeatInterval: '1', repeatEndAt: '', daysOfWeek: [], reminderMinutes: '10', reminderEnabled: true,
});

export default function SchedulePage() {
  const client = useQueryClient();
  const [view, setView] = useState<CalendarView>('WEEK');
  const [focusDate, setFocusDate] = useState(startOfDay(new Date()));
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<EventDraft>(emptyDraft);
  const range = useMemo(() => calendarRange(view, focusDate), [view, focusDate]);
  const calendarQuery = useQuery({ queryKey: ['calendar', range.from, range.to], queryFn: () => getCalendar(range.from, range.to) });
  const schedulesQuery = useQuery({ queryKey: ['schedule'], queryFn: getSchedule });
  const refresh = () => {
    void client.invalidateQueries({ queryKey: ['calendar'] });
    void client.invalidateQueries({ queryKey: ['schedule'] });
  };
  const saveMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string | null; payload: SchedulePayload }) => id ? updateSchedule(id, payload) : createSchedule(payload),
    onSuccess: () => { refresh(); setEditingId(null); setDraft(emptyDraft()); toast.success('Đã lưu sự kiện'); },
    onError: error => toast.error(getApiErrorMessage(error, 'Không thể lưu sự kiện')),
  });
  const removeMutation = useMutation({
    mutationFn: deleteSchedule,
    onSuccess: () => { refresh(); toast.success('Đã xóa sự kiện'); },
    onError: error => toast.error(getApiErrorMessage(error, 'Không thể xóa sự kiện')),
  });
  const entries = calendarQuery.data ?? [];

  const editEvent = (sourceId: string) => {
    const item = schedulesQuery.data?.find(schedule => schedule.id === sourceId);
    if (!item) return;
    setEditingId(item.id);
    setDraft({
      title: item.title, description: item.description ?? '', category: item.category,
      startAt: inputDateTime(item.startAt), endAt: inputDateTime(item.endAt), repeatRule: item.repeatRule,
      repeatInterval: String(item.repeatInterval ?? 1), repeatEndAt: inputDateTime(item.repeatEndAt),
      daysOfWeek: item.daysOfWeek?.split(',').filter(Boolean) ?? [], reminderMinutes: String(item.reminderMinutes),
      reminderEnabled: item.reminderEnabled,
    });
  };
  const save = () => {
    if (!draft.title.trim() || !draft.startAt) return;
    saveMutation.mutate({ id: editingId, payload: {
      title: draft.title.trim(), description: draft.description.trim() || null, category: draft.category,
      startAt: localIso(draft.startAt)!, endAt: localIso(draft.endAt), repeatRule: draft.repeatRule,
      repeatInterval: Number(draft.repeatInterval) || 1, repeatEndAt: localIso(draft.repeatEndAt),
      daysOfWeek: draft.daysOfWeek.join(','), reminderMinutes: Number(draft.reminderMinutes) || 0,
      reminderEnabled: draft.reminderEnabled, enabled: true,
    } });
  };

  return <div className="space-y-6">
    <PageHeader title="Thời khóa biểu" description="Xem chung công việc đã lên giờ và các sự kiện; Todo vẫn là nơi quản lý việc cần hoàn thành." />
    <Card>
      <CardHeader className="gap-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div><CardTitle className="flex items-center gap-2"><CalendarDays className="size-5 text-emerald-700" />Lịch cá nhân</CardTitle><p className="mt-1 text-sm text-muted-foreground">{range.label}</p></div>
          <div className="flex items-center gap-1"><Button variant="outline" size="icon" onClick={() => setFocusDate(shiftFocus(view, focusDate, -1))} aria-label="Kỳ trước"><ChevronLeft className="size-4" /></Button><Button variant="outline" onClick={() => setFocusDate(startOfDay(new Date()))}>Hôm nay</Button><Button variant="outline" size="icon" onClick={() => setFocusDate(shiftFocus(view, focusDate, 1))} aria-label="Kỳ sau"><ChevronRight className="size-4" /></Button></div>
        </div>
        <div className="flex flex-wrap gap-2">{([['DAY', 'Ngày'], ['WEEK', 'Tuần'], ['MONTH', 'Tháng'], ['LIST', 'Danh sách']] as const).map(([value, label]) => <button key={value} onClick={() => setView(value)} className={`rounded-full border px-3 py-1.5 text-xs font-semibold ${view === value ? 'border-emerald-700 bg-emerald-700 text-white' : 'bg-background text-muted-foreground'}`}>{label}</button>)}</div>
      </CardHeader>
      <CardContent>
        {calendarQuery.isLoading ? <p className="py-16 text-center text-sm text-muted-foreground">Đang tải lịch...</p> : calendarQuery.isError ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">Không thể tải lịch hợp nhất. Hãy thử lại.</p> : <CalendarBody view={view} focusDate={focusDate} entries={entries} onEdit={editEvent} onDelete={id => removeMutation.mutate(id)} />}
      </CardContent>
    </Card>
    <EventEditor draft={draft} editing={Boolean(editingId)} pending={saveMutation.isPending} onChange={setDraft} onSave={save} onCancel={() => { setEditingId(null); setDraft(emptyDraft()); }} />
  </div>;
}

function CalendarBody({ view, focusDate, entries, onEdit, onDelete }: { view: CalendarView; focusDate: Date; entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void }) {
  if (view === 'MONTH') return <MonthView focusDate={focusDate} entries={entries} />;
  if (view === 'WEEK') return <WeekView focusDate={focusDate} entries={entries} onEdit={onEdit} onDelete={onDelete} />;
  const filtered = view === 'DAY' ? entries.filter(item => dateKey(new Date(item.startAt)) === dateKey(focusDate)) : entries;
  return <EntryList entries={filtered} onEdit={onEdit} onDelete={onDelete} empty={view === 'DAY' ? 'Ngày này chưa có công việc hoặc sự kiện.' : 'Chưa có lịch trong khoảng đang xem.'} />;
}

function WeekView({ focusDate, entries, onEdit, onDelete }: { focusDate: Date; entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void }) {
  const monday = startOfWeek(focusDate);
  return <div className="grid gap-3 lg:grid-cols-7">{Array.from({ length: 7 }, (_, index) => addDays(monday, index)).map(day => {
    const dayEntries = entries.filter(item => dateKey(new Date(item.startAt)) === dateKey(day));
    const today = dateKey(day) === dateKey(new Date());
    return <div key={dateKey(day)} className={`min-h-44 rounded-2xl border p-3 ${today ? 'border-emerald-300 bg-emerald-50/50' : 'bg-background'}`}><div className="mb-3 flex items-center justify-between"><span className="text-xs font-semibold uppercase text-muted-foreground">{new Intl.DateTimeFormat('vi-VN', { weekday: 'short' }).format(day)}</span><span className={`grid size-7 place-items-center rounded-full text-sm font-bold ${today ? 'bg-emerald-700 text-white' : ''}`}>{day.getDate()}</span></div><div className="space-y-2">{dayEntries.length === 0 ? <p className="text-xs text-muted-foreground/60">Trống</p> : dayEntries.map(entry => <CompactEntry key={entry.occurrenceId} entry={entry} onEdit={onEdit} onDelete={onDelete} />)}</div></div>;
  })}</div>;
}

function MonthView({ focusDate, entries }: { focusDate: Date; entries: CalendarEntry[] }) {
  const first = new Date(focusDate.getFullYear(), focusDate.getMonth(), 1);
  const mondayIndex = (first.getDay() + 6) % 7;
  const gridStart = addDays(first, -mondayIndex);
  return <div><div className="mb-2 grid grid-cols-7 gap-1 text-center text-xs font-semibold text-muted-foreground">{['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map(day => <span key={day}>{day}</span>)}</div><div className="grid grid-cols-7 gap-1">{Array.from({ length: 42 }, (_, index) => addDays(gridStart, index)).map(day => {
    const dayEntries = entries.filter(item => dateKey(new Date(item.startAt)) === dateKey(day));
    const outside = day.getMonth() !== focusDate.getMonth();
    return <div key={dateKey(day)} className={`min-h-24 rounded-xl border p-2 ${outside ? 'bg-muted/30 text-muted-foreground' : 'bg-background'}`}><span className="text-xs font-semibold">{day.getDate()}</span><div className="mt-1 space-y-1">{dayEntries.slice(0, 3).map(entry => <div key={entry.occurrenceId} className={`truncate rounded px-1.5 py-1 text-[10px] font-medium ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-800' : 'bg-emerald-100 text-emerald-800'}`} title={entry.title}>{timeLabel(entry.startAt)} {entry.title}</div>)}{dayEntries.length > 3 && <p className="text-[10px] text-muted-foreground">+{dayEntries.length - 3} mục</p>}</div></div>;
  })}</div></div>;
}

function EntryList({ entries, onEdit, onDelete, empty }: { entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void; empty: string }) {
  if (entries.length === 0) return <div className="rounded-2xl border border-dashed p-10 text-center"><CalendarDays className="mx-auto size-8 text-muted-foreground/40" /><p className="mt-3 font-medium">{empty}</p></div>;
  const groups = entries.reduce<Record<string, CalendarEntry[]>>((result, item) => {
    const key = dateKey(new Date(item.startAt));
    (result[key] ??= []).push(item);
    return result;
  }, {});
  return <div className="space-y-5">{Object.entries(groups).map(([day, items]) => <section key={day}><h3 className="mb-2 text-sm font-semibold">{fullDate(new Date(`${day}T00:00:00`))}</h3><div className="space-y-2">{items.map(entry => <EntryCard key={entry.occurrenceId} entry={entry} onEdit={onEdit} onDelete={onDelete} />)}</div></section>)}</div>;
}

function CompactEntry({ entry, onEdit, onDelete }: { entry: CalendarEntry; onEdit: (id: string) => void; onDelete: (id: string) => void }) {
  return <button onClick={() => entry.sourceType === 'EVENT' && onEdit(entry.sourceId)} className={`group w-full rounded-lg p-2 text-left text-xs ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-900' : 'bg-emerald-100 text-emerald-900'}`}><span className="font-semibold">{timeLabel(entry.startAt)}</span><span className="mt-0.5 block line-clamp-2">{entry.title}</span>{entry.sourceType === 'EVENT' && <span onClick={event => { event.stopPropagation(); onDelete(entry.sourceId); }} className="mt-1 hidden text-red-600 group-hover:block">Xóa</span>}</button>;
}

function EntryCard({ entry, onEdit, onDelete }: { entry: CalendarEntry; onEdit: (id: string) => void; onDelete: (id: string) => void }) {
  return <div className="flex items-start gap-3 rounded-2xl border p-4"><div className={`grid size-11 shrink-0 place-items-center rounded-xl ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-800' : 'bg-emerald-100 text-emerald-800'}`}>{entry.sourceType === 'TODO' ? <ListTodo className="size-5" /> : <CalendarDays className="size-5" />}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><p className="font-semibold">{entry.title}</p><Badge variant="outline">{entry.sourceType === 'TODO' ? 'Việc cần làm' : 'Sự kiện'}</Badge>{entry.recurring && <Badge className="bg-violet-100 text-violet-800"><Repeat2 className="mr-1 size-3" />Lặp lại</Badge>}</div><p className="mt-1 flex items-center gap-1 text-sm text-muted-foreground"><Clock3 className="size-3.5" />{timeLabel(entry.startAt)}{entry.endAt ? ` – ${timeLabel(entry.endAt)}` : ''}</p>{entry.description && <p className="mt-1 text-sm text-muted-foreground">{entry.description}</p>}</div>{entry.sourceType === 'EVENT' && <div className="flex"><button onClick={() => onEdit(entry.sourceId)} className="rounded-lg p-2 text-muted-foreground hover:bg-emerald-50 hover:text-emerald-700" aria-label="Sửa sự kiện"><Pencil className="size-4" /></button><button onClick={() => onDelete(entry.sourceId)} className="rounded-lg p-2 text-muted-foreground hover:bg-red-50 hover:text-red-600" aria-label="Xóa sự kiện"><Trash2 className="size-4" /></button></div>}</div>;
}

function EventEditor({ draft, editing, pending, onChange, onSave, onCancel }: { draft: EventDraft; editing: boolean; pending: boolean; onChange: (draft: EventDraft) => void; onSave: () => void; onCancel: () => void }) {
  const set = <K extends keyof EventDraft>(key: K, value: EventDraft[K]) => onChange({ ...draft, [key]: value });
  const unit = draft.repeatRule === 'DAILY' ? 'ngày' : draft.repeatRule === 'WEEKLY' ? 'tuần' : draft.repeatRule === 'MONTHLY' ? 'tháng' : 'năm';
  return <Card className="border-emerald-200"><CardHeader><CardTitle className="flex items-center gap-2"><Plus className="size-5 text-emerald-700" />{editing ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện'}</CardTitle><p className="text-sm text-muted-foreground">Công việc cần hoàn thành hãy tạo ở Todo; form này dành cho cuộc hẹn và khung giờ cố định.</p></CardHeader><CardContent className="grid gap-4 lg:grid-cols-2"><Field label="Tên sự kiện"><Input value={draft.title} onChange={event => set('title', event.target.value)} placeholder="Ví dụ: Khám sức khỏe định kỳ" /></Field><Field label="Nhóm"><select value={draft.category} onChange={event => set('category', event.target.value as ScheduleItem['category'])} className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"><option value="PERSONAL">Cá nhân</option><option value="WORK">Công việc</option><option value="HEALTH">Sức khỏe</option><option value="STUDY">Học tập</option><option value="MEAL">Bữa ăn</option></select></Field><Field label="Bắt đầu"><Input type="datetime-local" value={draft.startAt} onChange={event => set('startAt', event.target.value)} /></Field><Field label="Kết thúc (tùy chọn)"><Input type="datetime-local" value={draft.endAt} onChange={event => set('endAt', event.target.value)} /></Field><Field label="Mô tả"><Input value={draft.description} onChange={event => set('description', event.target.value)} placeholder="Địa điểm hoặc nội dung cần chuẩn bị" /></Field><Field label="Lặp lại"><div className="grid grid-cols-[1fr_6rem] gap-2"><select value={draft.repeatRule} onChange={event => set('repeatRule', event.target.value as ScheduleItem['repeatRule'])} className="h-10 rounded-lg border border-input bg-background px-3 text-sm"><option value="NONE">Không lặp</option><option value="DAILY">Hàng ngày</option><option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option></select><Input type="number" min={1} max={365} disabled={draft.repeatRule === 'NONE'} value={draft.repeatInterval} onChange={event => set('repeatInterval', event.target.value)} /></div>{draft.repeatRule !== 'NONE' && <p className="mt-1 text-xs text-muted-foreground">Mỗi {draft.repeatInterval || 1} {unit}</p>}</Field>{draft.repeatRule === 'WEEKLY' && <div className="lg:col-span-2"><Label>Xuất hiện vào thứ</Label><div className="mt-2 flex flex-wrap gap-2">{weekDays.map(([value, label]) => <button key={value} type="button" onClick={() => set('daysOfWeek', draft.daysOfWeek.includes(value) ? draft.daysOfWeek.filter(day => day !== value) : [...draft.daysOfWeek, value])} className={`rounded-lg border px-3 py-1.5 text-xs font-semibold ${draft.daysOfWeek.includes(value) ? 'border-emerald-700 bg-emerald-700 text-white' : ''}`}>{label}</button>)}</div></div>}{draft.repeatRule !== 'NONE' && <Field label="Kết thúc lặp (để trống nếu không giới hạn)"><Input type="datetime-local" value={draft.repeatEndAt} onChange={event => set('repeatEndAt', event.target.value)} /></Field>}<div className="rounded-xl border bg-muted/30 p-3"><div className="flex items-center justify-between"><span className="flex items-center gap-2 text-sm font-medium"><Bell className="size-4" />Thông báo trước</span><input type="checkbox" checked={draft.reminderEnabled} onChange={event => set('reminderEnabled', event.target.checked)} /></div><div className="mt-2 flex items-center gap-2"><Input type="number" min={0} max={10080} value={draft.reminderMinutes} disabled={!draft.reminderEnabled} onChange={event => set('reminderMinutes', event.target.value)} /><span className="text-sm text-muted-foreground">phút</span></div></div><div className="flex gap-2 lg:col-span-2"><Button className="flex-1" onClick={onSave} disabled={!draft.title.trim() || !draft.startAt || pending}>{pending ? 'Đang lưu...' : editing ? 'Lưu thay đổi' : 'Tạo sự kiện'}</Button>{editing && <Button variant="outline" onClick={onCancel}>Hủy</Button>}</div></CardContent></Card>;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) { return <div className="space-y-1.5"><Label>{label}</Label>{children}</div>; }
function localIso(value: string) { return value ? `${value}:00` : null; }
function inputDateTime(value: string | null) { return value ? value.slice(0, 16) : ''; }
function startOfDay(value: Date) { return new Date(value.getFullYear(), value.getMonth(), value.getDate()); }
function addDays(value: Date, days: number) { const result = new Date(value); result.setDate(result.getDate() + days); return result; }
function startOfWeek(value: Date) { const result = startOfDay(value); result.setDate(result.getDate() - ((result.getDay() + 6) % 7)); return result; }
function dateKey(value: Date) { return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}-${String(value.getDate()).padStart(2, '0')}`; }
function isoLocal(value: Date) { return `${dateKey(value)}T${String(value.getHours()).padStart(2, '0')}:${String(value.getMinutes()).padStart(2, '0')}:00`; }
function timeLabel(value: string) { return new Intl.DateTimeFormat('vi-VN', { hour: '2-digit', minute: '2-digit' }).format(new Date(value)); }
function fullDate(value: Date) { return new Intl.DateTimeFormat('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' }).format(value); }
function calendarRange(view: CalendarView, focus: Date) {
  let from: Date; let to: Date;
  if (view === 'DAY') { from = startOfDay(focus); to = addDays(from, 1); }
  else if (view === 'WEEK') { from = startOfWeek(focus); to = addDays(from, 7); }
  else if (view === 'MONTH') { from = new Date(focus.getFullYear(), focus.getMonth(), 1); to = new Date(focus.getFullYear(), focus.getMonth() + 1, 1); }
  else { from = startOfDay(focus); to = addDays(from, 90); }
  return { from: isoLocal(from), to: isoLocal(to), label: view === 'DAY' ? fullDate(from) : `${new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit' }).format(from)} – ${new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(addDays(to, -1))}` };
}
function shiftFocus(view: CalendarView, focus: Date, direction: number) { const result = new Date(focus); if (view === 'DAY') result.setDate(result.getDate() + direction); else if (view === 'WEEK') result.setDate(result.getDate() + direction * 7); else if (view === 'MONTH') result.setMonth(result.getMonth() + direction); else result.setDate(result.getDate() + direction * 90); return result; }
