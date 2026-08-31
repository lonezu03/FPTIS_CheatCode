import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  AlertTriangle,
  Bell,
  CalendarClock,
  Check,
  Circle,
  Clock3,
  ListChecks,
  Pencil,
  Plus,
  Repeat2,
  SkipForward,
  ChefHat,
  Timer,
  Trash2,
} from 'lucide-react';
import { toast } from 'sonner';
import { completeTodo, createTodo, deleteTodo, getTodos, skipTodo, updateTodo, type Todo, type TodoCategory, type TodoPayload } from '@/api/todo.api';
import { getApiErrorMessage } from '@/lib/format';
import PageHeader from '@/components/PageHeader';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

const categories: Array<{ value: TodoCategory; label: string }> = [
  { value: 'WORK', label: 'Công việc' },
  { value: 'STUDY', label: 'Học tập' },
  { value: 'PERSONAL', label: 'Cá nhân' },
  { value: 'HEALTH', label: 'Sức khỏe' },
  { value: 'FINANCE', label: 'Tài chính' },
  { value: 'SHOPPING', label: 'Mua sắm' },
];
const weekDays: Array<{ value: string; label: string }> = [
  { value: 'MONDAY', label: 'T2' }, { value: 'TUESDAY', label: 'T3' }, { value: 'WEDNESDAY', label: 'T4' },
  { value: 'THURSDAY', label: 'T5' }, { value: 'FRIDAY', label: 'T6' }, { value: 'SATURDAY', label: 'T7' }, { value: 'SUNDAY', label: 'CN' },
];

type View = 'ALL' | 'TODAY' | 'OVERDUE' | 'UPCOMING';
type StatusFilter = 'ALL' | 'OPEN' | 'IN_PROGRESS' | 'DONE';
type Draft = {
  title: string;
  description: string;
  priority: Todo['priority'];
  category: TodoCategory;
  startAt: string;
  dueAt: string;
  estimatedMinutes: string;
  reminderAt: string;
  reminderEnabled: boolean;
  recurrenceRule: Todo['recurrenceRule'];
  recurrenceInterval: string;
  daysOfWeek: string[];
  recurrenceBasis: Todo['recurrenceBasis'];
  recurrenceEndAt: string;
  recurrenceMaxOccurrences: string;
  subtasks: Array<{ title: string; completed: boolean; sortOrder: number }>;
};

const emptyDraft = (): Draft => ({
  title: '', description: '', priority: 'MEDIUM', category: 'PERSONAL', startAt: '', dueAt: '', estimatedMinutes: '',
  reminderAt: '', reminderEnabled: false, recurrenceRule: 'NONE', recurrenceInterval: '1', daysOfWeek: [],
  recurrenceBasis: 'SCHEDULED_DATE', recurrenceEndAt: '', recurrenceMaxOccurrences: '', subtasks: [],
});
const localIso = (value: string) => value ? `${value}:00` : null;
const inputDateTime = (value: string | null) => value ? value.slice(0, 16) : '';
const dateKey = (value: string | null) => value ? value.slice(0, 10) : '';
const formatDate = (value: string) => new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }).format(new Date(value));
const formatShortDate = (value: string | null) => value ? new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value)) : 'Chưa đặt lịch';
const todayKey = () => {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
};

export default function TodoPage() {
  const client = useQueryClient();
  const query = useQuery({ queryKey: ['todos'], queryFn: () => getTodos({ view: 'ALL' }) });
  const [view, setView] = useState<View>('TODAY');
  const [status, setStatus] = useState<StatusFilter>('ALL');
  const [category, setCategory] = useState<'ALL' | TodoCategory>('ALL');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [quickAdd, setQuickAdd] = useState('');
  const [renderNow] = useState(() => Date.now());

  const refresh = () => void client.invalidateQueries({ queryKey: ['todos'] });
  const createMutation = useMutation({
    mutationFn: createTodo,
    onSuccess: () => { setDraft(emptyDraft()); refresh(); toast.success('Đã thêm công việc'); },
    onError: (error: unknown) => toast.error(getApiErrorMessage(error, 'Không thể thêm công việc')),
  });
  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: TodoPayload }) => updateTodo(id, payload),
    onSuccess: () => { setEditingId(null); setDraft(emptyDraft()); refresh(); toast.success('Đã cập nhật công việc'); },
    onError: (error: unknown) => toast.error(getApiErrorMessage(error, 'Không thể cập nhật công việc')),
  });
  const toggleMutation = useMutation({
    mutationFn: ({ todo, nextStatus }: { todo: Todo; nextStatus: Todo['status'] }) => nextStatus === 'DONE' ? completeTodo(todo.id) : updateTodo(todo.id, todoPayload(todo, nextStatus)),
    onSuccess: refresh,
    onError: (error: unknown) => toast.error(getApiErrorMessage(error, 'Không thể cập nhật trạng thái')),
  });
  const skipMutation = useMutation({
    mutationFn: (todo: Todo) => skipTodo(todo.id),
    onSuccess: () => { refresh(); toast.success('Đã bỏ qua lần này; lịch lặp tiếp theo vẫn được giữ'); },
    onError: (error: unknown) => toast.error(getApiErrorMessage(error, 'Không thể bỏ qua lần này')),
  });
  const removeMutation = useMutation({
    mutationFn: deleteTodo,
    onSuccess: () => { refresh(); toast.success('Đã xóa công việc'); },
    onError: (error: unknown) => toast.error(getApiErrorMessage(error, 'Không thể xóa công việc')),
  });

  const allTodos = useMemo(() => query.data ?? [], [query.data]);
  const counts = useMemo(() => {
    const today = todayKey();
    return {
      today: allTodos.filter(item => dateKey(item.dueAt ?? item.startAt) === today).length,
      overdue: allTodos.filter(item => item.status !== 'DONE' && item.status !== 'ARCHIVED' && item.dueAt && new Date(item.dueAt).getTime() < renderNow).length,
      upcoming: allTodos.filter(item => dateKey(item.dueAt ?? item.startAt) > today).length,
      done: allTodos.filter(item => item.status === 'DONE').length,
    };
  }, [allTodos, renderNow]);
  const todos = useMemo(() => allTodos.filter(item => {
    const scheduledDate = dateKey(item.dueAt ?? item.startAt);
    const today = todayKey();
    const matchesView = view === 'ALL'
      || (view === 'TODAY' && scheduledDate === today)
      || (view === 'OVERDUE' && item.status !== 'DONE' && item.status !== 'ARCHIVED' && Boolean(item.dueAt) && new Date(item.dueAt as string).getTime() < renderNow)
      || (view === 'UPCOMING' && scheduledDate > today);
    const matchesStatus = status === 'ALL' || item.status === status;
    const matchesCategory = category === 'ALL' || item.category === category;
    return matchesView && matchesStatus && matchesCategory;
  }), [allTodos, category, renderNow, status, view]);

  const beginEdit = (todo: Todo) => {
    setEditingId(todo.id);
    setDraft({
      title: todo.title, description: todo.description ?? '', priority: todo.priority, category: todo.category,
      startAt: inputDateTime(todo.startAt), dueAt: inputDateTime(todo.dueAt), estimatedMinutes: todo.estimatedMinutes?.toString() ?? '',
      reminderAt: inputDateTime(todo.reminderAt), reminderEnabled: todo.reminderEnabled, recurrenceRule: todo.recurrenceRule,
      recurrenceInterval: todo.recurrenceInterval.toString(), daysOfWeek: todo.daysOfWeek, subtasks: todo.subtasks.map(item => ({ title: item.title, completed: item.completed, sortOrder: item.sortOrder })),
      recurrenceBasis: todo.recurrenceBasis ?? 'SCHEDULED_DATE', recurrenceEndAt: inputDateTime(todo.recurrenceEndAt),
      recurrenceMaxOccurrences: todo.recurrenceMaxOccurrences?.toString() ?? '',
    });
  };
  const resetEditor = () => { setEditingId(null); setDraft(emptyDraft()); };
  const save = () => {
    const payload: TodoPayload = {
      title: draft.title.trim(), description: draft.description.trim() || null, status: editingId ? allTodos.find(item => item.id === editingId)?.status ?? 'OPEN' : 'OPEN',
      priority: draft.priority, category: draft.category, startAt: localIso(draft.startAt), dueAt: localIso(draft.dueAt),
      estimatedMinutes: draft.estimatedMinutes ? Number(draft.estimatedMinutes) : null, reminderAt: localIso(draft.reminderAt), reminderEnabled: draft.reminderEnabled,
      recurrenceRule: draft.recurrenceRule, recurrenceInterval: Number(draft.recurrenceInterval) || 1, daysOfWeek: draft.daysOfWeek.join(','),
      recurrenceBasis: draft.recurrenceBasis, recurrenceEndAt: localIso(draft.recurrenceEndAt),
      recurrenceMaxOccurrences: draft.recurrenceMaxOccurrences ? Number(draft.recurrenceMaxOccurrences) : null,
      subtasks: draft.subtasks.map((item, index) => ({ ...item, title: item.title.trim(), sortOrder: index })).filter(item => item.title),
    };
    if (!payload.title) return;
    if (editingId) updateMutation.mutate({ id: editingId, payload }); else createMutation.mutate(payload);
  };
  const pending = createMutation.isPending || updateMutation.isPending;
  const applyQuickAdd = () => {
    if (!quickAdd.trim()) return;
    setEditingId(null);
    setDraft(parseQuickTodo(quickAdd));
    toast.success('Đã tách thông tin. Hãy kiểm tra lại rồi bấm Tạo công việc.');
  };

  return <div className="space-y-6">
    <PageHeader title="Việc cần làm" description="Lập kế hoạch rõ ràng hơn với lịch, nhắc việc, lặp lại và checklist con." />
    <Card className="border-violet-200 bg-violet-50/40"><CardContent className="flex flex-col gap-3 p-4 sm:flex-row sm:items-center"><span className="grid size-10 shrink-0 place-items-center rounded-xl bg-violet-100 text-violet-700"><ChefHat className="size-5" /></span><div className="min-w-0 flex-1"><Label htmlFor="todo-quick-add">Thêm nhanh bằng câu tự nhiên</Label><Input id="todo-quick-add" value={quickAdd} onChange={event => setQuickAdd(event.target.value)} onKeyDown={event => event.key === 'Enter' && applyQuickAdd()} className="mt-1" placeholder="Ví dụ: Rửa xe mỗi 3 tuần sau khi hoàn thành, lúc 9 giờ sáng" /></div><Button variant="outline" onClick={applyQuickAdd}>Phân tích</Button></CardContent></Card>
    <div className="grid gap-3 sm:grid-cols-4">
      <MetricCard label="Hôm nay" value={counts.today} icon={<CalendarClock className="size-4" />} tone="emerald" />
      <MetricCard label="Quá hạn" value={counts.overdue} icon={<AlertTriangle className="size-4" />} tone="red" />
      <MetricCard label="Sắp tới" value={counts.upcoming} icon={<Clock3 className="size-4" />} tone="blue" />
      <MetricCard label="Đã hoàn thành" value={counts.done} icon={<Check className="size-4" />} tone="violet" />
    </div>
    <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_25rem]">
      <Card>
        <CardHeader className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3"><div><CardTitle>Personal Task Planner</CardTitle><p className="mt-1 text-sm text-muted-foreground">Deadline không thay thế cho giờ bắt đầu, thời lượng hay lời nhắc.</p></div><Button onClick={resetEditor} variant="outline"><Plus className="mr-2 size-4" />Việc mới</Button></div>
          <div className="flex flex-wrap gap-2">{([['TODAY', `Hôm nay (${counts.today})`], ['OVERDUE', `Quá hạn (${counts.overdue})`], ['UPCOMING', `Sắp tới (${counts.upcoming})`], ['ALL', `Tất cả (${allTodos.length})`]] as const).map(([value, label]) => <button key={value} onClick={() => setView(value)} className={`rounded-full border px-3 py-1.5 text-xs font-semibold transition ${view === value ? 'border-emerald-600 bg-emerald-600 text-white' : 'bg-background text-muted-foreground hover:border-emerald-300'}`}>{label}</button>)}</div>
          <div className="flex flex-wrap gap-2"><select value={status} onChange={event => setStatus(event.target.value as StatusFilter)} className="h-9 rounded-lg border border-input bg-background px-3 text-xs"><option value="ALL">Mọi trạng thái</option><option value="OPEN">Chưa làm</option><option value="IN_PROGRESS">Đang làm</option><option value="DONE">Đã xong</option></select><select value={category} onChange={event => setCategory(event.target.value as 'ALL' | TodoCategory)} className="h-9 rounded-lg border border-input bg-background px-3 text-xs"><option value="ALL">Mọi danh mục</option>{categories.map(item => <option key={item.value} value={item.value}>{item.label}</option>)}</select></div>
        </CardHeader>
        <CardContent className="space-y-3">
          {query.isLoading ? <p className="py-10 text-center text-sm text-muted-foreground">Đang tải công việc...</p> : query.isError ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">Không thể tải danh sách công việc.</p> : todos.length === 0 ? <div className="rounded-2xl border border-dashed p-10 text-center"><Circle className="mx-auto size-9 text-muted-foreground/40" /><p className="mt-3 font-medium">Chưa có công việc trong chế độ này</p><p className="mt-1 text-sm text-muted-foreground">Tạo việc mới hoặc đổi bộ lọc để xem kế hoạch khác.</p></div> : todos.map(todo => <TodoCard key={todo.id} todo={todo} now={renderNow} onEdit={() => beginEdit(todo)} onToggle={() => toggleMutation.mutate({ todo, nextStatus: todo.status === 'DONE' ? 'OPEN' : 'DONE' })} onSkip={() => skipMutation.mutate(todo)} onDelete={() => removeMutation.mutate(todo.id)} />)}
        </CardContent>
      </Card>
      <TodoEditor draft={draft} editing={Boolean(editingId)} pending={pending} onChange={setDraft} onSave={save} onCancel={resetEditor} />
    </div>
  </div>;
}

function MetricCard({ label, value, icon, tone }: { label: string; value: number; icon: React.ReactNode; tone: 'emerald' | 'red' | 'blue' | 'violet' }) {
  const tones = { emerald: 'bg-emerald-50 text-emerald-700', red: 'bg-red-50 text-red-700', blue: 'bg-blue-50 text-blue-700', violet: 'bg-violet-50 text-violet-700' };
  return <Card><CardContent className="flex items-center justify-between p-4"><div><p className="text-xs font-medium text-muted-foreground">{label}</p><p className="mt-1 text-2xl font-semibold tracking-tight">{value}</p></div><span className={`rounded-xl p-2 ${tones[tone]}`}>{icon}</span></CardContent></Card>;
}

function TodoCard({ todo, now, onEdit, onToggle, onSkip, onDelete }: { todo: Todo; now: number; onEdit: () => void; onToggle: () => void; onSkip: () => void; onDelete: () => void }) {
  const doneCount = todo.subtasks.filter(item => item.completed).length;
  const overdue = todo.status !== 'DONE' && todo.dueAt && new Date(todo.dueAt).getTime() < now;
  return <div className={`group rounded-2xl border p-4 transition ${todo.status === 'DONE' ? 'bg-muted/50 opacity-75' : overdue ? 'border-red-200 bg-red-50/30' : 'bg-card hover:border-emerald-200 hover:shadow-sm'}`}>
    <div className="flex items-start gap-3"><button className="mt-0.5 rounded-full text-emerald-600" onClick={onToggle} aria-label={todo.status === 'DONE' ? 'Mở lại công việc' : 'Đánh dấu hoàn thành'}>{todo.status === 'DONE' ? <Check className="size-5" /> : <Circle className="size-5" />}</button><button className="min-w-0 flex-1 text-left" onClick={onEdit}><div className="flex flex-wrap items-center gap-2"><p className={`font-semibold ${todo.status === 'DONE' || todo.status === 'SKIPPED' ? 'line-through' : ''}`}>{todo.title}</p><Badge variant={todo.priority === 'HIGH' ? 'destructive' : 'secondary'}>{priorityLabel(todo.priority)}</Badge><Badge variant="outline">{categoryLabel(todo.category)}</Badge>{todo.status === 'IN_PROGRESS' && <Badge className="bg-blue-100 text-blue-700 hover:bg-blue-100">Đang làm</Badge>}{todo.status === 'SKIPPED' && <Badge variant="outline">Đã bỏ qua</Badge>}</div>{todo.description && <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{todo.description}</p>}<div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">{todo.startAt && <span className="flex items-center gap-1"><CalendarClock className="size-3.5" /> Bắt đầu {formatDate(todo.startAt)}</span>}{todo.dueAt && <span className={`flex items-center gap-1 ${overdue ? 'font-semibold text-red-600' : ''}`}><Clock3 className="size-3.5" /> Hạn {formatDate(todo.dueAt)}</span>}{todo.estimatedMinutes && <span className="flex items-center gap-1"><Timer className="size-3.5" /> {todo.estimatedMinutes} phút</span>}{todo.reminderEnabled && <span className="flex items-center gap-1 text-amber-600"><Bell className="size-3.5" /> Nhắc {formatShortDate(todo.reminderAt)}</span>}{todo.recurrenceRule !== 'NONE' && <span className="flex items-center gap-1 text-violet-600"><Repeat2 className="size-3.5" /> {recurrenceLabel(todo)}</span>}{todo.subtasks.length > 0 && <span className="flex items-center gap-1"><ListChecks className="size-3.5" /> {doneCount}/{todo.subtasks.length} bước</span>}</div></button><div className="flex shrink-0 gap-1">{todo.recurrenceRule !== 'NONE' && todo.status !== 'DONE' && todo.status !== 'SKIPPED' && <button className="rounded-lg p-2 text-muted-foreground hover:bg-amber-50 hover:text-amber-700" onClick={onSkip} aria-label="Bỏ qua lần này" title="Bỏ qua lần này"><SkipForward className="size-4" /></button>}<button className="rounded-lg p-2 text-muted-foreground hover:bg-emerald-50 hover:text-emerald-700" onClick={onEdit} aria-label="Sửa công việc"><Pencil className="size-4" /></button><button className="rounded-lg p-2 text-muted-foreground hover:bg-red-50 hover:text-red-600" onClick={onDelete} aria-label="Xóa công việc"><Trash2 className="size-4" /></button></div></div>
  </div>;
}

function TodoEditor({ draft, editing, pending, onChange, onSave, onCancel }: { draft: Draft; editing: boolean; pending: boolean; onChange: (value: Draft) => void; onSave: () => void; onCancel: () => void }) {
  const update = <K extends keyof Draft>(key: K, value: Draft[K]) => onChange({ ...draft, [key]: value });
  const addSubtask = () => update('subtasks', [...draft.subtasks, { title: '', completed: false, sortOrder: draft.subtasks.length }]);
  const unit = draft.recurrenceRule === 'WEEKLY' ? 'tuần' : draft.recurrenceRule === 'MONTHLY' ? 'tháng' : draft.recurrenceRule === 'YEARLY' ? 'năm' : 'ngày';
  return <Card className="h-fit border-emerald-200 bg-gradient-to-b from-emerald-50/80 to-background">
    <CardHeader><CardTitle className="flex items-center gap-2"><Plus className="size-5 text-emerald-700" />{editing ? 'Chỉnh sửa công việc' : 'Thêm công việc'}</CardTitle><p className="text-sm text-muted-foreground">Deadline, giờ thực hiện và lời nhắc là ba mốc riêng biệt.</p></CardHeader>
    <CardContent className="space-y-4">
      <Field label="Tên công việc" htmlFor="todo-title"><Input id="todo-title" value={draft.title} onChange={event => update('title', event.target.value)} placeholder="Ví dụ: Học tiếng Nhật 30 phút" /></Field>
      <Field label="Mô tả / ghi chú" htmlFor="todo-description"><textarea id="todo-description" value={draft.description} onChange={event => update('description', event.target.value)} rows={3} className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500" placeholder="Kết quả cần đạt, tài liệu hoặc ghi chú..." /></Field>
      <div className="grid gap-3 sm:grid-cols-2"><Field label="Bắt đầu làm lúc" htmlFor="todo-start"><Input id="todo-start" type="datetime-local" value={draft.startAt} onChange={event => update('startAt', event.target.value)} /></Field><Field label="Hạn hoàn thành" htmlFor="todo-due"><Input id="todo-due" type="datetime-local" value={draft.dueAt} onChange={event => update('dueAt', event.target.value)} /></Field></div>
      <div className="grid gap-3 sm:grid-cols-2"><Field label="Thời lượng dự kiến (phút)" htmlFor="todo-duration"><Input id="todo-duration" type="number" min={1} max={1440} value={draft.estimatedMinutes} onChange={event => update('estimatedMinutes', event.target.value)} placeholder="Ví dụ: 45" /></Field><Field label="Mức ưu tiên" htmlFor="todo-priority"><select id="todo-priority" value={draft.priority} onChange={event => update('priority', event.target.value as Todo['priority'])} className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"><option value="HIGH">Cao</option><option value="MEDIUM">Trung bình</option><option value="LOW">Thấp</option></select></Field></div>
      <Field label="Danh mục" htmlFor="todo-category"><select id="todo-category" value={draft.category} onChange={event => update('category', event.target.value as TodoCategory)} className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm">{categories.map(item => <option key={item.value} value={item.value}>{item.label}</option>)}</select></Field>
      <div className="rounded-xl border bg-background/70 p-3"><div className="mb-2 flex items-center justify-between"><Label>Nhắc việc</Label><label className="flex items-center gap-2 text-xs text-muted-foreground"><input type="checkbox" checked={draft.reminderEnabled} onChange={event => update('reminderEnabled', event.target.checked)} /> Bật nhắc</label></div><Input type="datetime-local" value={draft.reminderAt} onChange={event => update('reminderAt', event.target.value)} disabled={!draft.reminderEnabled} /><p className="mt-2 text-xs text-muted-foreground">Chọn thời điểm FitTrack gửi thông báo, không phải deadline.</p></div>
      <div className="space-y-3 rounded-xl border bg-background/70 p-3">
        <Label>Lặp lại</Label>
        <div className="grid gap-2 sm:grid-cols-2"><select value={draft.recurrenceRule} onChange={event => update('recurrenceRule', event.target.value as Todo['recurrenceRule'])} className="h-10 rounded-lg border border-input bg-background px-3 text-sm"><option value="NONE">Không lặp</option><option value="DAILY">Hàng ngày</option><option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option><option value="CUSTOM">Tùy chỉnh theo ngày</option></select><Input type="number" min={1} max={365} value={draft.recurrenceInterval} onChange={event => update('recurrenceInterval', event.target.value)} disabled={draft.recurrenceRule === 'NONE'} placeholder="Chu kỳ" /></div>
        {draft.recurrenceRule !== 'NONE' && <><p className="text-xs text-muted-foreground">Lặp mỗi {draft.recurrenceInterval || 1} {unit}.</p><div className="grid gap-2 sm:grid-cols-2"><Field label="Tính lần tiếp theo từ"><select value={draft.recurrenceBasis} onChange={event => update('recurrenceBasis', event.target.value as Todo['recurrenceBasis'])} className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"><option value="SCHEDULED_DATE">Lịch cố định</option><option value="COMPLETION_DATE">Ngày hoàn thành</option></select></Field><Field label="Kết thúc vào ngày (tùy chọn)"><Input type="datetime-local" value={draft.recurrenceEndAt} onChange={event => update('recurrenceEndAt', event.target.value)} /></Field></div><Field label="Hoặc dừng sau số lần (tùy chọn)"><Input type="number" min={1} max={10000} value={draft.recurrenceMaxOccurrences} onChange={event => update('recurrenceMaxOccurrences', event.target.value)} placeholder="Ví dụ: 12 lần" /></Field></>}
        {draft.recurrenceRule === 'WEEKLY' && <div className="flex flex-wrap gap-1.5">{weekDays.map(day => <button type="button" key={day.value} onClick={() => update('daysOfWeek', draft.daysOfWeek.includes(day.value) ? draft.daysOfWeek.filter(item => item !== day.value) : [...draft.daysOfWeek, day.value])} className={`rounded-md border px-2 py-1 text-xs font-semibold ${draft.daysOfWeek.includes(day.value) ? 'border-violet-600 bg-violet-600 text-white' : 'bg-background text-muted-foreground'}`}>{day.label}</button>)}</div>}
      </div>
      <div className="rounded-xl border bg-background/70 p-3"><div className="mb-2 flex items-center justify-between"><Label>Checklist con</Label><Button type="button" variant="outline" size="sm" onClick={addSubtask}><Plus className="mr-1 size-3.5" />Thêm bước</Button></div>{draft.subtasks.length === 0 ? <p className="text-xs text-muted-foreground">Tách công việc lớn thành các bước nhỏ để dễ theo dõi.</p> : <div className="space-y-2">{draft.subtasks.map((item, index) => <div key={`${index}-${item.title}`} className="flex items-center gap-2"><input type="checkbox" checked={item.completed} onChange={event => update('subtasks', draft.subtasks.map((current, currentIndex) => currentIndex === index ? { ...current, completed: event.target.checked } : current))} /><Input value={item.title} onChange={event => update('subtasks', draft.subtasks.map((current, currentIndex) => currentIndex === index ? { ...current, title: event.target.value } : current))} placeholder={`Bước ${index + 1}`} /><button type="button" onClick={() => update('subtasks', draft.subtasks.filter((_, currentIndex) => currentIndex !== index))} className="rounded p-1 text-muted-foreground hover:text-red-600" aria-label="Xóa bước"><Trash2 className="size-4" /></button></div>)}</div>}</div>
      <div className="flex gap-2"><Button className="flex-1" disabled={!draft.title.trim() || pending} onClick={onSave}>{pending ? 'Đang lưu...' : editing ? 'Lưu thay đổi' : 'Tạo công việc'}</Button>{editing && <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>Hủy</Button>}</div>
    </CardContent>
  </Card>;
}

function Field({ label, htmlFor, children }: { label: string; htmlFor?: string; children: React.ReactNode }) { return <div className="space-y-1.5"><Label htmlFor={htmlFor}>{label}</Label>{children}</div>; }
function priorityLabel(priority: Todo['priority']) { return priority === 'HIGH' ? 'Ưu tiên cao' : priority === 'LOW' ? 'Thấp' : 'Trung bình'; }
function categoryLabel(category: TodoCategory) { return categories.find(item => item.value === category)?.label ?? 'Cá nhân'; }
function recurrenceLabel(todo: Todo) { const unit = todo.recurrenceRule === 'WEEKLY' ? 'tuần' : todo.recurrenceRule === 'MONTHLY' ? 'tháng' : todo.recurrenceRule === 'YEARLY' ? 'năm' : 'ngày'; return `Mỗi ${todo.recurrenceInterval} ${unit} · ${todo.recurrenceBasis === 'COMPLETION_DATE' ? 'từ lúc hoàn thành' : 'theo lịch'}`; }
function todoPayload(todo: Todo, status: Todo['status']): TodoPayload { return { title: todo.title, description: todo.description, status, priority: todo.priority, startAt: todo.startAt, dueAt: todo.dueAt, estimatedMinutes: todo.estimatedMinutes, category: todo.category, recurrenceRule: todo.recurrenceRule, recurrenceInterval: todo.recurrenceInterval, daysOfWeek: todo.daysOfWeek.join(','), recurrenceBasis: todo.recurrenceBasis, recurrenceEndAt: todo.recurrenceEndAt, recurrenceMaxOccurrences: todo.recurrenceMaxOccurrences, reminderAt: todo.reminderAt, reminderEnabled: todo.reminderEnabled, subtasks: todo.subtasks.map(item => ({ title: item.title, completed: item.completed, sortOrder: item.sortOrder })) }; }

function parseQuickTodo(input: string): Draft {
  const normalized = input.trim().replace(/\s+/g, ' ');
  const lower = normalized.toLocaleLowerCase('vi-VN');
  const duration = lower.match(/(\d+)\s*phút/);
  const customRepeat = lower.match(/mỗi\s+(\d+)\s*(ngày|tuần|tháng|năm)/);
  const time = lower.match(/lúc\s+(\d{1,2})(?::|h)?(\d{2})?\s*(giờ)?\s*(sáng|chiều|tối)?/);
  const remind = lower.match(/nhắc\s+trước\s+(\d+)\s*phút/);
  const base = emptyDraft();
  let recurrenceRule: Todo['recurrenceRule'] = 'NONE';
  let interval = '1';
  if (customRepeat) {
    interval = customRepeat[1];
    recurrenceRule = customRepeat[2] === 'tuần' ? 'WEEKLY' : customRepeat[2] === 'tháng' ? 'MONTHLY' : customRepeat[2] === 'năm' ? 'YEARLY' : 'DAILY';
  } else if (lower.includes('mỗi ngày') || lower.includes('hàng ngày')) recurrenceRule = 'DAILY';
  let startAt = '';
  let reminderAt = '';
  if (time) {
    const date = new Date();
    let hour = Number(time[1]);
    if ((time[4] === 'chiều' || time[4] === 'tối') && hour < 12) hour += 12;
    if (time[4] === 'sáng' && hour === 12) hour = 0;
    date.setHours(hour, Number(time[2] ?? 0), 0, 0);
    startAt = dateTimeInput(date);
    if (remind) reminderAt = dateTimeInput(new Date(date.getTime() - Number(remind[1]) * 60_000));
  }
  const title = normalized
    .replace(/,?\s*mỗi\s+\d+\s*(ngày|tuần|tháng|năm)/i, '')
    .replace(/,?\s*(mỗi ngày|hàng ngày)/i, '')
    .replace(/,?\s*sau khi hoàn thành/i, '')
    .replace(/,?\s*lúc\s+\d{1,2}(?::|h)?\d{0,2}\s*(giờ)?\s*(sáng|chiều|tối)?/i, '')
    .replace(/,?\s*nhắc\s+trước\s+\d+\s*phút/i, '')
    .trim();
  return { ...base, title: title || normalized, estimatedMinutes: duration?.[1] ?? '', startAt,
    reminderAt, reminderEnabled: Boolean(reminderAt), recurrenceRule, recurrenceInterval: interval,
    recurrenceBasis: lower.includes('sau khi hoàn thành') ? 'COMPLETION_DATE' : 'SCHEDULED_DATE' };
}

function dateTimeInput(value: Date) {
  return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}-${String(value.getDate()).padStart(2, '0')}T${String(value.getHours()).padStart(2, '0')}:${String(value.getMinutes()).padStart(2, '0')}`;
}
