import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { useAuthStore } from '@/store/auth.store';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Bell, CalendarDays, CheckCircle2, ChevronLeft, ChevronRight, Clock3, ListTodo, Pencil, Plus, Repeat2, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  createSchedule,
  deleteSchedule,
  getCalendar,
  getSchedule,
  getScheduleItem,
  updateSchedule,
  type CalendarEntry,
  type ScheduleItem,
  type SchedulePayload,
} from '@/api/schedule.api';
import { getApiErrorMessage } from '@/lib/format';
import { completeTodo } from '@/api/todo.api';
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
  const ownerId = useAuthStore(state => state.user?.userId);
  return <ScheduleWorkspace key={ownerId ?? 'anonymous'} />;
}

function ScheduleWorkspace() {
  const client = useQueryClient();
  const [params, setParams] = useSearchParams();
  const ownerId = useAuthStore(state => state.user?.userId);
  const storageKey = `fittrack:schedule:${ownerId ?? 'anonymous'}`;
  const [view, setView] = useState<CalendarView>(() => { try { const value = localStorage.getItem(storageKey + ':view'); return ['DAY', 'WEEK', 'MONTH', 'LIST'].includes(value ?? '') ? value as CalendarView : 'WEEK'; } catch { return 'WEEK'; } });
  const [focusDate, setFocusDate] = useState(startOfDay(new Date()));
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<EventDraft>(emptyDraft);
  const editorRef = useRef<HTMLDivElement>(null);
  const handledLink = useRef('');
  const [savedDraft, setSavedDraft] = useState(() => readEventDraft(storageKey + ':draft'));
  const deepLinkId = params.get('event');
  const detailQuery = useQuery({ queryKey: ['schedule-detail', deepLinkId], queryFn: () => getScheduleItem(deepLinkId!), enabled: Boolean(deepLinkId), retry: false });
  const revealEditor = () => requestAnimationFrame(() => { editorRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }); editorRef.current?.querySelector('input')?.focus({ preventScroll: true }); });
  const clearSavedDraft = () => { try { localStorage.removeItem(storageKey + ':draft'); } catch { /* Browser storage can be disabled. */ } setSavedDraft(null); };
  useEffect(() => { try { localStorage.setItem(storageKey + ':view', view); } catch { /* Optional preference. */ } }, [storageKey, view]);
  useEffect(() => {
    if (!ownerId || editingId || savedDraft) return;
    try { if (draft.title.trim()) localStorage.setItem(storageKey + ':draft', JSON.stringify({ savedAt: Date.now(), draft })); else localStorage.removeItem(storageKey + ':draft'); } catch { /* Saving the event remains available. */ }
  }, [storageKey, ownerId, draft, editingId, savedDraft]);
  const range = useMemo(() => calendarRange(view, focusDate), [view, focusDate]);
  const calendarQuery = useQuery({ queryKey: ['calendar', range.from, range.to], queryFn: () => getCalendar(range.from, range.to) });
  const schedulesQuery = useQuery({ queryKey: ['schedule', range.from, range.to], queryFn: () => getSchedule(range.from, range.to) });
  const refresh = () => {
    void client.invalidateQueries({ queryKey: ['calendar'] });
    void client.invalidateQueries({ queryKey: ['schedule'] });
  };
  const saveMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string | null; payload: SchedulePayload }) => id ? updateSchedule(id, payload) : createSchedule(payload),
    onSuccess: () => { refresh(); if (!editingId && !savedDraft) clearSavedDraft(); setEditingId(null); setDraft(emptyDraft()); toast.success('Đã lưu sự kiện'); },
    onError: error => toast.error(getApiErrorMessage(error, 'Không thể lưu sự kiện')),
  });
  const removeMutation = useMutation({
    mutationFn: deleteSchedule,
    onSuccess: () => { refresh(); toast.success('Đã xóa sự kiện'); },
    onError: error => toast.error(getApiErrorMessage(error, 'Không thể xóa sự kiện')),
  });
  const completeMutation = useMutation({
    mutationFn: completeTodo,
    onSuccess: () => {
      void client.invalidateQueries({ queryKey: ['calendar'] });
      void client.invalidateQueries({ queryKey: ['todos'] });
      void client.invalidateQueries({ queryKey: ['dashboard-today'] });
      toast.success('Đã hoàn thành công việc');
    },
    onError: error => toast.error(getApiErrorMessage(error, 'Không thể hoàn thành công việc')),
  });
  const entries = calendarQuery.data ?? [];
  const conflictRange = useMemo(() => draft.startAt ? { from: isoLocal(startOfDay(new Date(draft.startAt))), to: isoLocal(addDays(startOfDay(new Date(draft.endAt || draft.startAt)), 1)) } : null, [draft.startAt, draft.endAt]);
  const conflictQuery = useQuery({ queryKey: ['calendar', 'event-conflicts', conflictRange?.from, conflictRange?.to], queryFn: () => getCalendar(conflictRange!.from, conflictRange!.to), enabled: Boolean(conflictRange && draft.title.trim() && (!draft.endAt || draft.endAt >= draft.startAt)), retry: false });
  const conflicts = (conflictQuery.data ?? []).filter(item => item.sourceType === 'EVENT' && item.sourceId !== editingId && new Date(item.startAt).getTime() < new Date(draft.endAt || draft.startAt).getTime() && new Date(item.endAt || item.startAt).getTime() > new Date(draft.startAt).getTime());
  const newEvent = (day: Date) => { setSavedDraft(readEventDraft(storageKey + ':draft')); setEditingId(null); const start = new Date(day); start.setHours(9, 0, 0, 0); const end = new Date(start); end.setHours(10); setDraft({ ...emptyDraft(), startAt: inputDateTime(isoLocal(start)), endAt: inputDateTime(isoLocal(end)) }); revealEditor(); };

  const loadEvent = (item: ScheduleItem) => {
    setSavedDraft(readEventDraft(storageKey + ':draft'));
    setEditingId(item.id);
    setDraft({
      title: item.title, description: item.description ?? '', category: item.category,
      startAt: inputDateTime(item.startAt), endAt: inputDateTime(item.endAt), repeatRule: item.repeatRule,
      repeatInterval: String(item.repeatInterval ?? 1), repeatEndAt: inputDateTime(item.repeatEndAt),
      daysOfWeek: item.daysOfWeek?.split(',').filter(Boolean) ?? [], reminderMinutes: String(item.reminderMinutes),
      reminderEnabled: item.reminderEnabled,
    });
    revealEditor();
  };
  const editEvent = (sourceId: string) => { const item = schedulesQuery.data?.find(schedule => schedule.id === sourceId); if (item) loadEvent(item); else void getScheduleItem(sourceId).then(loadEvent).catch(error => toast.error(getApiErrorMessage(error, 'Không thể mở sự kiện'))); };
  useEffect(() => {
    const key = deepLinkId ? `event:${deepLinkId}` : params.get('action') === 'new' ? 'new' : '';
    if (!key || handledLink.current === key || (deepLinkId && !detailQuery.isSuccess && !detailQuery.isError)) return;
    handledLink.current = key;
    if (deepLinkId && detailQuery.isError) toast.error('Không tìm thấy sự kiện hoặc bạn không có quyền xem.');
    else requestAnimationFrame(() => { if (deepLinkId && detailQuery.data) { loadEvent(detailQuery.data); setFocusDate(startOfDay(new Date(detailQuery.data.startAt))); } else newEvent(focusDate); });
    const next = new URLSearchParams(params); next.delete('action'); next.delete('event'); setParams(next, { replace: true });
  });
  const save = () => {
    if (!draft.title.trim() || !draft.startAt) return;
    if (draft.endAt && draft.endAt <= draft.startAt) { toast.error('Giờ kết thúc phải sau giờ bắt đầu.'); return; }
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
    {savedDraft && !editingId && <div className="flex flex-wrap items-center gap-3 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm"><span className="flex-1">Bạn có bản nháp sự kiện trên thiết bị này.{draft.title.trim() && ' Bản đang nhập chỉ tự lưu sau khi bạn bỏ bản nháp cũ.'}</span><Button size="sm" variant="outline" disabled={Boolean(draft.title.trim())} title="Khôi phục khi form đang trống để giữ nội dung đang nhập" onClick={() => { setDraft(savedDraft); setSavedDraft(null); revealEditor(); }}>Khôi phục</Button><Button size="sm" variant="ghost" onClick={clearSavedDraft}>Bỏ bản nháp cũ</Button></div>}
    <Button className="h-auto min-h-10 max-w-full whitespace-normal py-2 text-left" variant="outline" onClick={() => newEvent(focusDate)}><Plus className="mr-2 size-4" />Sự kiện mới cho ngày {fullDate(focusDate)}</Button>
    <Card>
      <CardHeader className="gap-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div><CardTitle className="flex items-center gap-2"><CalendarDays className="size-5 text-emerald-700" />Lịch cá nhân</CardTitle><p className="mt-1 text-sm text-muted-foreground">{range.label}</p></div>
          <div className="flex items-center gap-1"><Button variant="outline" size="icon" onClick={() => setFocusDate(shiftFocus(view, focusDate, -1))} aria-label="Kỳ trước"><ChevronLeft className="size-4" /></Button><Button variant="outline" onClick={() => setFocusDate(startOfDay(new Date()))}>Hôm nay</Button><Button variant="outline" size="icon" onClick={() => setFocusDate(shiftFocus(view, focusDate, 1))} aria-label="Kỳ sau"><ChevronRight className="size-4" /></Button></div>
        </div>
        <div className="flex flex-wrap gap-2">{([['DAY', 'Ngày'], ['WEEK', 'Tuần'], ['MONTH', 'Tháng'], ['LIST', 'Danh sách']] as const).map(([value, label]) => <button key={value} onClick={() => setView(value)} className={`rounded-full border px-3 py-1.5 text-xs font-semibold ${view === value ? 'border-emerald-700 bg-emerald-700 text-white' : 'bg-background text-muted-foreground'}`}>{label}</button>)}</div>
      </CardHeader>
      <CardContent>
        {calendarQuery.isLoading ? <p className="py-16 text-center text-sm text-muted-foreground">Đang tải lịch...</p> : calendarQuery.isError ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">Không thể tải lịch hợp nhất. Hãy thử lại.</p> : <CalendarBody onCreate={newEvent} view={view} focusDate={focusDate} entries={entries} onEdit={editEvent} onDelete={id => removeMutation.mutate(id)} onComplete={id => completeMutation.mutate(id)} completingId={completeMutation.isPending ? completeMutation.variables : undefined} />}
      </CardContent>
    </Card>
    <div ref={editorRef} className="scroll-mt-24">{conflicts.length > 0 && <p role="status" className="mb-3 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">Khung giờ này trùng {conflicts.length} sự kiện: {conflicts.map(item => item.title).join(', ')}. Bạn vẫn có thể lưu nếu đây là chủ ý.</p>}{conflictQuery.isError && draft.startAt && <p className="mb-3 text-sm text-amber-800">Chưa kiểm tra được lịch trùng. Hãy kiểm tra lịch trước khi lưu.</p>}<EventEditor draft={draft} editing={Boolean(editingId)} pending={saveMutation.isPending} onChange={setDraft} onSave={save} onCancel={() => { setEditingId(null); setDraft(emptyDraft()); }} /></div>
  </div>;
}

function CalendarBody({ view, focusDate, entries, onEdit, onDelete, onComplete, completingId, onCreate }: { view: CalendarView; focusDate: Date; entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completingId?: string; onCreate: (day: Date) => void }) {
  if (view === 'MONTH') return <MonthView onCreate={onCreate} focusDate={focusDate} entries={entries} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completingId={completingId} />;
  if (view === 'WEEK') return <WeekView onCreate={onCreate} focusDate={focusDate} entries={entries} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completingId={completingId} />;
  const filtered = view === 'DAY' ? entries.filter(item => dateKey(new Date(item.startAt)) === dateKey(focusDate)) : entries;
  return <EntryList entries={filtered} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completingId={completingId} empty={view === 'DAY' ? 'Ngày này chưa có công việc hoặc sự kiện.' : 'Chưa có lịch trong khoảng đang xem.'} />;
}

function WeekView({ focusDate, entries, onEdit, onDelete, onComplete, completingId, onCreate }: { focusDate: Date; entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completingId?: string; onCreate: (day: Date) => void }) {
  const monday = startOfWeek(focusDate);
  return <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-7">{Array.from({ length: 7 }, (_, index) => addDays(monday, index)).map(day => {
    const dayEntries = entries.filter(item => dateKey(new Date(item.startAt)) === dateKey(day));
    const today = dateKey(day) === dateKey(new Date());
    return <div key={dateKey(day)} className={`min-h-44 rounded-2xl border p-3 ${today ? 'border-emerald-300 bg-emerald-50/50' : 'bg-background'}`}><div className="mb-3 flex items-center justify-between"><span className="text-xs font-semibold uppercase text-muted-foreground">{new Intl.DateTimeFormat('vi-VN', { weekday: 'short' }).format(day)}</span><span className={`grid size-7 place-items-center rounded-full text-sm font-bold ${today ? 'bg-emerald-700 text-white' : ''}`}>{day.getDate()}</span></div><div className="space-y-2">{dayEntries.length === 0 ? <p className="text-xs text-muted-foreground/60">Trống</p> : dayEntries.map(entry => <CompactEntry key={entry.occurrenceId} entry={entry} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completing={completingId === entry.sourceId} />)}</div><Button className="mt-3 w-full" size="sm" variant="outline" onClick={() => onCreate(day)}><Plus className="mr-1 size-3" />Sự kiện</Button></div>;
  })}</div>;
}

function MonthView({ focusDate, entries, onEdit, onDelete, onComplete, completingId, onCreate }: { focusDate: Date; entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completingId?: string; onCreate: (day: Date) => void }) {
  const [selectedDate, setSelectedDate] = useState(dateKey(focusDate));
  const selected = selectedDate.slice(0, 7) === dateKey(focusDate).slice(0, 7) ? selectedDate : dateKey(focusDate);
  const first = new Date(focusDate.getFullYear(), focusDate.getMonth(), 1);
  const gridStart = addDays(first, -((first.getDay() + 6) % 7));
  return <div className="space-y-4">
    <p className="text-sm text-muted-foreground">Chạm một ngày để xem và xử lý công việc bên dưới.</p>
    <div>
      <div className="mb-2 grid grid-cols-7 gap-1 text-center text-xs font-semibold text-muted-foreground">{['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map(day => <span key={day}>{day}</span>)}</div>
      <div className="grid grid-cols-7 gap-1">{Array.from({ length: 42 }, (_, index) => addDays(gridStart, index)).map(day => {
        const key = dateKey(day);
        const dayEntries = entries.filter(item => dateKey(new Date(item.startAt)) === key);
        const outside = day.getMonth() !== focusDate.getMonth();
        return <button type="button" key={key} disabled={outside} aria-pressed={selected === key} aria-label={fullDate(day) + ': ' + dayEntries.length + ' mục'} onClick={() => setSelectedDate(key)} className={`min-h-12 min-w-0 rounded-lg border px-0.5 py-2 text-center focus-visible:outline-2 focus-visible:outline-emerald-700 sm:min-h-24 sm:p-2 ${selected === key ? 'border-emerald-600 bg-emerald-50 ring-1 ring-emerald-600' : outside ? 'bg-muted/30 text-muted-foreground/50' : 'bg-background'}`}>
          <span className="text-xs font-semibold">{day.getDate()}</span>
          {dayEntries.length > 0 && <><span className="mt-1 block text-[10px] text-emerald-800 sm:hidden">{dayEntries.length} mục</span><div className="mt-1 hidden space-y-1 sm:block">{dayEntries.slice(0, 3).map(entry => <div key={entry.occurrenceId} className={`truncate rounded px-1 py-1 text-left text-[10px] ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-800' : 'bg-emerald-100 text-emerald-800'} ${isCompletedTodo(entry) ? 'line-through opacity-60' : ''}`}>{timeLabel(entry.startAt)} {entry.title}</div>)}{dayEntries.length > 3 && <span className="text-[10px]">+{dayEntries.length - 3} mục</span>}</div></>}
        </button>;
      })}</div>
    </div>
<Button variant="outline" onClick={() => onCreate(new Date(selected + 'T00:00:00'))}><Plus className="mr-1 size-4" />Thêm sự kiện ngày đang chọn</Button>
    <EntryList entries={entries.filter(item => dateKey(new Date(item.startAt)) === selected)} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completingId={completingId} empty={fullDate(new Date(selected + 'T00:00:00')) + ': Chưa có công việc hoặc sự kiện.'} />
  </div>;
}
function EntryList({ entries, onEdit, onDelete, onComplete, completingId, empty }: { entries: CalendarEntry[]; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completingId?: string; empty: string }) {
  if (entries.length === 0) return <div className="rounded-2xl border border-dashed p-10 text-center"><CalendarDays className="mx-auto size-8 text-muted-foreground/40" /><p className="mt-3 font-medium">{empty}</p></div>;
  const groups = entries.reduce<Record<string, CalendarEntry[]>>((result, item) => {
    const key = dateKey(new Date(item.startAt));
    (result[key] ??= []).push(item);
    return result;
  }, {});
  return <div className="space-y-5">{Object.entries(groups).map(([day, items]) => <section key={day}><h3 className="mb-2 text-sm font-semibold">{fullDate(new Date(`${day}T00:00:00`))}</h3><div className="space-y-2">{items.map(entry => <EntryCard key={entry.occurrenceId} entry={entry} onEdit={onEdit} onDelete={onDelete} onComplete={onComplete} completing={completingId === entry.sourceId} />)}</div></section>)}</div>;
}

function CompactEntry({ entry, onEdit, onDelete, onComplete, completing }: { entry: CalendarEntry; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completing: boolean }) {
  const completed = isCompletedTodo(entry);
  return <div className={`group w-full rounded-lg p-2 text-left text-xs ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-900' : 'bg-emerald-100 text-emerald-900'} ${completed ? 'opacity-60' : ''}`}><button type="button" onClick={() => entry.sourceType === 'EVENT' && onEdit(entry.sourceId)} className="w-full text-left"><span className="font-semibold">{timeLabel(entry.startAt)}</span><span className={`mt-0.5 block line-clamp-2 ${completed ? 'line-through' : ''}`}>{entry.title}</span></button><CarryOverBadge entry={entry} />{canCompleteTodo(entry) && <button type="button" disabled={completing} onClick={() => onComplete(entry.sourceId)} className="mt-2 flex min-h-10 w-full items-center justify-center gap-1 rounded-md bg-white/70 px-2 py-1 font-semibold hover:bg-white disabled:opacity-50"><CheckCircle2 className="size-3.5" />{completing ? 'Đang lưu...' : 'Đánh dấu xong'}</button>}{entry.sourceType === 'WORKOUT' && <Link className="inline-flex rounded-lg border px-3 py-2 text-sm font-semibold" to={'/workouts?appointment='+entry.sourceId}>{entry.status==='DONE'?'Đã tập':'Mở buổi tập'}</Link>}{entry.sourceType === 'EVENT' && <button type="button" onClick={() => onDelete(entry.sourceId)} className="mt-1 min-h-10 rounded-md px-2 text-red-600 hover:bg-red-50">Xóa</button>}</div>;
}

function EntryCard({ entry, onEdit, onDelete, onComplete, completing }: { entry: CalendarEntry; onEdit: (id: string) => void; onDelete: (id: string) => void; onComplete: (id: string) => void; completing: boolean }) {
  const completed = isCompletedTodo(entry);
  return <div className={`flex flex-wrap items-start gap-3 rounded-2xl border p-3 sm:flex-nowrap sm:p-4 ${completed ? 'bg-muted/30 opacity-70' : ''}`}><div className={`grid size-11 shrink-0 place-items-center rounded-xl ${entry.sourceType === 'TODO' ? 'bg-violet-100 text-violet-800' : 'bg-emerald-100 text-emerald-800'}`}>{completed ? <CheckCircle2 className="size-5" /> : entry.sourceType === 'TODO' ? <ListTodo className="size-5" /> : <CalendarDays className="size-5" />}</div><div className="min-w-0 flex-1 basis-[calc(100%-4rem)] sm:basis-0"><div className="flex flex-wrap items-center gap-2"><p className={`break-words font-semibold ${completed ? 'line-through' : ''}`}>{entry.title}</p><Badge variant="outline">{entry.sourceType === 'TODO' ? 'Việc cần làm' : 'Sự kiện'}</Badge><CarryOverBadge entry={entry} />{completed && <Badge className="bg-emerald-100 text-emerald-800">Đã hoàn thành</Badge>}{entry.recurring && <Badge className="bg-violet-100 text-violet-800"><Repeat2 className="mr-1 size-3" />Lặp lại</Badge>}</div><p className="mt-1 flex items-center gap-1 text-sm text-muted-foreground"><Clock3 className="size-3.5" />{timeLabel(entry.startAt)}{entry.endAt ? ` – ${timeLabel(entry.endAt)}` : ''}</p>{entry.description && <p className="mt-1 break-words text-sm text-muted-foreground">{entry.description}</p>}</div>{canCompleteTodo(entry) && <Button type="button" size="sm" variant="outline" disabled={completing} onClick={() => onComplete(entry.sourceId)}><CheckCircle2 className="mr-1 size-4" />{completing ? 'Đang lưu...' : 'Hoàn thành'}</Button>}{entry.sourceType === 'WORKOUT' && <Link className="inline-flex rounded-lg border px-3 py-2 text-sm font-semibold" to={'/workouts?appointment='+entry.sourceId}>{entry.status==='DONE'?'Đã tập':'Mở buổi tập'}</Link>}{entry.sourceType === 'EVENT' && <div className="flex"><button onClick={() => onEdit(entry.sourceId)} className="min-h-11 min-w-11 rounded-lg p-2 text-muted-foreground hover:bg-emerald-50 hover:text-emerald-700" aria-label="Sửa sự kiện"><Pencil className="size-4" /></button><button onClick={() => onDelete(entry.sourceId)} className="rounded-lg p-2 text-muted-foreground hover:bg-red-50 hover:text-red-600" aria-label="Xóa sự kiện"><Trash2 className="size-4" /></button></div>}</div>;
}

function isCompletedTodo(entry: CalendarEntry) {
  return (entry.sourceType === 'TODO' || entry.sourceType === 'WORKOUT') && entry.status === 'DONE';
}

function CarryOverBadge({ entry }: { entry: CalendarEntry }) {
  if (!entry.carryOver || !entry.originalStartAt) return null;
  const original = new Date(entry.originalStartAt);
  if (!Number.isFinite(original.getTime())) return null;
  return <Badge variant="outline" className="mt-1 max-w-full whitespace-normal border-amber-300 bg-amber-50 text-[10px] text-amber-900">Chuyển tiếp từ {new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit' }).format(original)}</Badge>;
}

function canCompleteTodo(entry: CalendarEntry) {
  return entry.sourceType === 'TODO' && (entry.status === 'OPEN' || entry.status === 'IN_PROGRESS');
}

function EventEditor({ draft, editing, pending, onChange, onSave, onCancel }: { draft: EventDraft; editing: boolean; pending: boolean; onChange: (draft: EventDraft) => void; onSave: () => void; onCancel: () => void }) {
  const set = <K extends keyof EventDraft>(key: K, value: EventDraft[K]) => onChange({ ...draft, [key]: value });
  const unit = draft.repeatRule === 'DAILY' ? 'ngày' : draft.repeatRule === 'WEEKLY' ? 'tuần' : draft.repeatRule === 'MONTHLY' ? 'tháng' : 'năm';
  return <Card className="border-emerald-200"><CardHeader><CardTitle className="flex items-center gap-2"><Plus className="size-5 text-emerald-700" />{editing ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện'}</CardTitle><p className="text-sm text-muted-foreground">Công việc cần hoàn thành hãy tạo ở Todo; form này dành cho cuộc hẹn và khung giờ cố định.</p></CardHeader><CardContent className="grid gap-4 lg:grid-cols-2"><Field label="Tên sự kiện"><Input value={draft.title} onChange={event => set('title', event.target.value)} placeholder="Ví dụ: Khám sức khỏe định kỳ" /></Field><Field label="Nhóm"><select value={draft.category} onChange={event => set('category', event.target.value as ScheduleItem['category'])} className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"><option value="PERSONAL">Cá nhân</option><option value="WORK">Công việc</option><option value="HEALTH">Sức khỏe</option><option value="STUDY">Học tập</option><option value="MEAL">Bữa ăn</option></select></Field><Field label="Bắt đầu"><Input type="datetime-local" value={draft.startAt} onChange={event => set('startAt', event.target.value)} /></Field><Field label="Kết thúc (tùy chọn)"><Input type="datetime-local" value={draft.endAt} onChange={event => set('endAt', event.target.value)} /></Field><Field label="Mô tả"><Input value={draft.description} onChange={event => set('description', event.target.value)} placeholder="Địa điểm hoặc nội dung cần chuẩn bị" /></Field><details className="space-y-4 rounded-xl border p-3 lg:col-span-2"><summary className="cursor-pointer text-sm font-semibold">Nâng cao: lặp lại và thông báo</summary><Field label="Lặp lại"><div className="grid grid-cols-[1fr_6rem] gap-2"><select value={draft.repeatRule} onChange={event => set('repeatRule', event.target.value as ScheduleItem['repeatRule'])} className="h-10 rounded-lg border border-input bg-background px-3 text-sm"><option value="NONE">Không lặp</option><option value="DAILY">Hàng ngày</option><option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option></select><Input type="number" min={1} max={365} disabled={draft.repeatRule === 'NONE'} value={draft.repeatInterval} onChange={event => set('repeatInterval', event.target.value)} /></div>{draft.repeatRule !== 'NONE' && <p className="mt-1 text-xs text-muted-foreground">Mỗi {draft.repeatInterval || 1} {unit}</p>}</Field>{draft.repeatRule === 'WEEKLY' && <div className="lg:col-span-2"><Label>Xuất hiện vào thứ</Label><div className="mt-2 flex flex-wrap gap-2">{weekDays.map(([value, label]) => <button key={value} type="button" onClick={() => set('daysOfWeek', draft.daysOfWeek.includes(value) ? draft.daysOfWeek.filter(day => day !== value) : [...draft.daysOfWeek, value])} className={`rounded-lg border px-3 py-1.5 text-xs font-semibold ${draft.daysOfWeek.includes(value) ? 'border-emerald-700 bg-emerald-700 text-white' : ''}`}>{label}</button>)}</div></div>}{draft.repeatRule !== 'NONE' && <Field label="Kết thúc lặp (để trống nếu không giới hạn)"><Input type="datetime-local" value={draft.repeatEndAt} onChange={event => set('repeatEndAt', event.target.value)} /></Field>}<div className="rounded-xl border bg-muted/30 p-3"><div className="flex items-center justify-between"><span className="flex items-center gap-2 text-sm font-medium"><Bell className="size-4" />Thông báo trước</span><input type="checkbox" checked={draft.reminderEnabled} onChange={event => set('reminderEnabled', event.target.checked)} /></div><div className="mt-2 flex items-center gap-2"><Input type="number" min={0} max={10080} value={draft.reminderMinutes} disabled={!draft.reminderEnabled} onChange={event => set('reminderMinutes', event.target.value)} /><span className="text-sm text-muted-foreground">phút</span></div></div></details><p className="text-xs text-muted-foreground lg:col-span-2">Bản nháp sự kiện mới được lưu trên trình duyệt này theo tài khoản trong tối đa 7 ngày.</p><div className="flex gap-2 lg:col-span-2"><Button className="flex-1" onClick={onSave} disabled={!draft.title.trim() || !draft.startAt || pending}>{pending ? 'Đang lưu...' : editing ? 'Lưu thay đổi' : 'Tạo sự kiện'}</Button>{editing && <Button variant="outline" onClick={onCancel}>Hủy</Button>}</div></CardContent></Card>;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) { return <div className="min-w-0 space-y-1.5 [&_input]:min-w-0 [&_select]:min-w-0"><Label>{label}</Label>{children}</div>; }
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
function readEventDraft(key: string): EventDraft | null {
  try {
    const raw = localStorage.getItem(key); if (!raw) return null;
    const parsed = JSON.parse(raw);
    const draft = parsed?.draft as EventDraft | undefined;
    const valid = draft && Object.entries(emptyDraft()).every(([name, value]) => Array.isArray(value) ? Array.isArray(draft[name as keyof EventDraft]) : typeof draft[name as keyof EventDraft] === typeof value) && draft.daysOfWeek.every(day => typeof day === 'string');
    if (!valid || typeof parsed.savedAt !== 'number' || Date.now() - parsed.savedAt > 7 * 86_400_000) { localStorage.removeItem(key); return null; }
    return draft!;
  } catch { return null; }
}
