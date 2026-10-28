import { useRef, useState, type FormEvent } from 'react';
import axios from 'axios';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import PageHeader from '@/components/PageHeader';
import { mondayOf, planningDateText as dateText, planningPlus as plus } from '@/lib/meal-planning-dates';
import { getNutritionConvenience, searchNutritionFoods, type ServingUnit } from '@/api/nutrition.api';
import { addGrocery, checkGrocery, consumePlannedMeal, copyMealWeek, deleteGrocery, getGroceries, getMealWeekSummary, listPlannedMeals, regenerateGroceries, removePlannedMeal, savePlannedMeal, type PlannedMeal, type PlannedMealInput } from '@/api/meal-planning.api';

const types: Record<string, string> = { BREAKFAST: 'Bữa sáng', LUNCH: 'Bữa trưa', DINNER: 'Bữa tối', SNACK: 'Bữa phụ' };
const units: Record<string, string> = { SERVING: 'Khẩu phần', GRAM: 'g', ML: 'ml' };
function message(error: unknown) { return axios.isAxiosError(error) ? error.response?.data?.message || 'Không kết nối được máy chủ. Dữ liệu đang nhập vẫn được giữ.' : 'Không lưu được dữ liệu'; }
type DraftItem = { foodId: string; foodName: string; servingAmount: number; servingUnit: ServingUnit };

export default function MealPlanningPage() {
  const client = useQueryClient();
  const [week, setWeek] = useState(() => mondayOf(dateText(new Date())));
  const [page, setPage] = useState(0);
  const [target, setTarget] = useState('');
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<PlannedMeal | null>(null);
  const [form, setForm] = useState<PlannedMealInput>({ date: week, mealType: 'BREAKFAST', name: '' });
  const [items, setItems] = useState<DraftItem[]>([]);
  const [search, setSearch] = useState('');
  const [searchPage, setSearchPage] = useState(0);
  const [manual, setManual] = useState({ name: '', amount: 1, unit: 'phần' });
  const copyIds = useRef<Record<string, string>>({});
  const meals = useQuery({ queryKey: ['meal-planning', week, page], queryFn: () => listPlannedMeals(week, plus(week, 6), page) });
  const groceries = useQuery({ queryKey: ['groceries', week], queryFn: () => getGroceries(week) });
  const summary = useQuery({ queryKey: ['meal-planning', 'summary', week], queryFn: () => getMealWeekSummary(week) });
  const convenience = useQuery({ queryKey: ['nutrition-convenience'], queryFn: getNutritionConvenience, enabled: open });
  const foods = useQuery({ queryKey: ['planning-foods', search, searchPage], queryFn: () => searchNutritionFoods(search, searchPage), enabled: open && !form.collectionId });
  const mutation = useMutation({
    mutationFn: (action: () => Promise<unknown>) => action(),
    onSuccess: () => { void client.invalidateQueries({ queryKey: ['meal-planning'] }); void client.invalidateQueries({ queryKey: ['groceries'] }); void client.invalidateQueries({ queryKey: ['nutrition'] }); },
    onError: (error) => toast.error(message(error)),
  });
  const run = (action: () => Promise<unknown>) => mutation.mutate(action);
  const version = groceries.data?.version ?? 0;
  const busy = mutation.isPending;
  const start = (meal?: PlannedMeal) => {
    setEditing(meal ?? null); setForm(meal ? { version: meal.version, date: meal.date, mealType: meal.mealType, name: meal.name, notes: meal.notes ?? '' } : { date: week, mealType: 'BREAKFAST', name: '', servings: 1 });
    setItems(meal?.items.map(i => ({ foodId: i.foodId, foodName: i.foodName, servingAmount: i.servingAmount, servingUnit: i.servingUnit })) ?? []); setOpen(true);
  };
  const save = (event: FormEvent) => {
    event.preventDefault();
    if (!form.collectionId && !items.length) { toast.error('Chọn ít nhất một thực phẩm'); return; }
    run(async () => { await savePlannedMeal({ ...form, items: items.map(({ foodId, servingAmount, servingUnit }) => ({ foodId, servingAmount, servingUnit })) }, editing?.id); setOpen(false); toast.success('Đã lưu bữa ăn dự kiến, chưa ghi vào nhật ký'); });
  };
  return <div className="space-y-5">
    <PageHeader title="Thực đơn tuần & mua thực phẩm" description="Lên kế hoạch trước khi ăn. Chỉ ghi nhật ký khi bạn xác nhận đã ăn; không tự xác nhận ngày đầy đủ." />
    <div className="flex flex-wrap items-end gap-3 rounded-2xl border bg-card p-4">
      <label className="space-y-1">Tuần bắt đầu (thứ Hai)<Input aria-label="Tuần bắt đầu" type="date" value={week} onChange={e => { setWeek(mondayOf(e.target.value || dateText(new Date()))); setPage(0); }} /></label>
      <Button onClick={() => start()}>Thêm bữa dự kiến</Button>
      <label>Tuần đích<Input type="date" value={target} onChange={e => setTarget(e.target.value ? mondayOf(e.target.value) : '')} /></label>
      <Button variant="outline" disabled={busy || !target || target === week} onClick={() => { if (!window.confirm('Sao chép mẫu ăn sang tuần đích? Không ghi nhật ký và không thay các bữa đã có.')) return; const key = `${week}/${target}`; copyIds.current[key] ??= crypto.randomUUID(); run(async () => { await copyMealWeek(week, target, copyIds.current[key]); toast.success('Đã sao chép mẫu tuần'); }); }}>Sao chép tuần</Button>
    </div>
    <section className="space-y-2 rounded-2xl border bg-emerald-50 p-4"><h2 className="font-semibold">Tổng dinh dưỡng dự kiến cả tuần</h2>
      {summary.data ? <><p>{summary.data.plannedMealCount} bữa · {summary.data.totals.calories.toFixed(0)} kcal · {summary.data.totals.protein.toFixed(1)} g đạm · {summary.data.totals.carbs.toFixed(1)} g tinh bột · {summary.data.totals.fat.toFixed(1)} g béo</p><p className="text-sm">Vi chất có dữ liệu: {summary.data.totals.knownMicronutrientValues}/{summary.data.totals.possibleMicronutrientValues}. Bao gồm mọi trang của tuần, không phải lượng đã ăn hoặc trung bình nhật ký.</p></> : summary.isError ? <p role="alert">{message(summary.error)} <Button variant="outline" onClick={() => void summary.refetch()}>Tải lại tổng tuần</Button></p> : <p>Đang tổng hợp kế hoạch…</p>}
    </section>
    {meals.isPending && <p role="status">Đang tải thực đơn…</p>}
    {meals.isError && <div role="alert">{message(meals.error)} <Button variant="outline" onClick={() => void meals.refetch()}>Thử lại</Button></div>}
    <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">{meals.data?.content.map(meal => <article className="space-y-3 rounded-2xl border bg-card p-4" key={meal.id}>
      <p className="text-sm text-muted-foreground">{meal.date} · {types[meal.mealType]}</p><h2 className="font-semibold">{meal.name}</h2>
      {meal.notes && <p className="text-sm break-words">{meal.notes}</p>}
      <ul className="text-sm">{meal.items.map((item, i) => <li key={i}>{item.foodName} · {item.servingAmount} {units[item.servingUnit]}</li>)}</ul>
      <p className="text-sm">Dự kiến: {meal.totals.calories.toFixed(0)} kcal · {meal.totals.protein.toFixed(1)} g đạm · {meal.totals.carbs.toFixed(1)} g tinh bột · {meal.totals.fat.toFixed(1)} g béo</p>
      <p className="text-xs text-muted-foreground">Snapshot khi lập/sửa kế hoạch · Vi chất có dữ liệu: {meal.totals.knownMicronutrientValues}/{meal.totals.possibleMicronutrientValues}. Thiếu thông tin không phải bằng 0.</p>
      {meal.loggedMealId ? <p className="font-medium text-primary">Đã ghi nhật ký (không tự đánh dấu ngày đầy đủ)</p> : <div className="flex flex-wrap gap-2">
        <Button size="sm" disabled={busy || meal.date > dateText(new Date())} onClick={() => { if (window.confirm('Xác nhận thực sự đã ăn toàn bộ bữa này? Nhật ký sẽ tính lại theo kho thực phẩm hiện tại, có thể khác snapshot dự kiến. Chỉ ghi một lần.')) run(() => consumePlannedMeal(meal)); }}>Đã ăn → ghi nhật ký</Button>
        <Button size="sm" variant="outline" disabled={busy} onClick={() => start(meal)}>Sửa</Button>
        <Button size="sm" variant="destructive" disabled={busy} onClick={() => { if (window.confirm('Xóa bữa dự kiến?')) run(() => removePlannedMeal(meal)); }}>Xóa</Button>
      </div>}
    </article>)}</div>
    {meals.data?.totalElements === 0 && <p className="rounded-2xl border border-dashed p-6">Chưa có bữa dự kiến trong tuần. Thêm thực phẩm hoặc lấy từ bữa ăn/công thức đã lưu.</p>}
    <div className="flex gap-3 items-center"><Button variant="outline" disabled={!page || meals.isFetching} onClick={() => setPage(p => p - 1)}>Trước</Button><span>Trang {page + 1}/{Math.max(1, meals.data?.totalPages ?? 1)}</span><Button variant="outline" disabled={meals.isFetching || !meals.data || meals.data.last} onClick={() => setPage(p => p + 1)}>Sau</Button></div>
    <section className="space-y-3 rounded-2xl border bg-card p-4"><h2 className="text-xl font-semibold">Danh sách mua thực phẩm</h2>
      <p className="text-sm text-muted-foreground">Cộng gộp cùng thực phẩm và đơn vị. Không tự suy nguyên liệu món chế biến sẵn; không đổi gram thành ml. Tạo lại giữ mục tự thêm và trạng thái đã mua.</p>
      {groceries.isError ? <p role="alert">{message(groceries.error)} <Button onClick={() => void groceries.refetch()}>Thử lại</Button></p> : <>
        <Button variant="outline" disabled={busy || groceries.isPending} onClick={() => run(() => regenerateGroceries(week, version))}>Tạo lại từ thực đơn cả tuần</Button>
        <div className="max-h-96 overflow-y-auto space-y-2">{groceries.data?.items.map(item => <div key={item.id} className="flex gap-3 items-center rounded-xl border p-3">
          <input type="checkbox" aria-label={`Đã mua ${item.name}`} checked={item.checked} disabled={busy} onChange={e => run(() => checkGrocery(week, version, item, e.target.checked))} />
          <div className="min-w-0 flex-1"><span className={item.checked ? 'line-through' : ''}>{item.name} · {Number(item.amount.toFixed(3))} {units[item.unit] ?? item.unit}</span><p className="text-xs text-muted-foreground">{item.manual ? 'Tự thêm' : item.stale ? 'Đã mua · kế hoạch thay đổi, kiểm tra lại số lượng / nhu cầu' : 'Từ thực đơn'}</p></div>
          <Button size="sm" variant="destructive" disabled={busy} onClick={() => run(() => deleteGrocery(week, version, item.id))}>Xóa</Button>
        </div>)}</div>
        <form className="grid gap-2 sm:grid-cols-4" onSubmit={e => { e.preventDefault(); run(async () => { await addGrocery(week, version, manual.name, manual.amount, manual.unit); setManual({ name: '', amount: 1, unit: 'phần' }); }); }}>
          <label>Tên mục tự thêm<Input required maxLength={160} value={manual.name} onChange={e => setManual({ ...manual, name: e.target.value })} /></label>
          <label>Số lượng<Input required type="number" min="0.001" max="1000000" step="any" value={manual.amount} onChange={e => setManual({ ...manual, amount: Number(e.target.value) })} /></label>
          <label>Đơn vị<Input required maxLength={30} value={manual.unit} onChange={e => setManual({ ...manual, unit: e.target.value })} /></label>
          <Button className="self-end" disabled={busy || groceries.isPending}>Thêm mục mua</Button>
        </form>
      </>}
    </section>
    <Dialog open={open} onOpenChange={v => { if (!busy) setOpen(v); }}><DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-3xl"><DialogHeader><DialogTitle>{editing ? 'Sửa bữa dự kiến' : 'Thêm bữa dự kiến'}</DialogTitle><DialogDescription>Lưu snapshot dự kiến, không ghi nhận là đã ăn. Sửa sẽ tính lại dinh dưỡng từ kho hiện tại.</DialogDescription></DialogHeader>
      <form onSubmit={save} className="space-y-4"><div className="grid gap-3 sm:grid-cols-2">
        <label>Ngày dự kiến<Input required type="date" min="2000-01-01" max="2100-12-31" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })} /></label>
        <label>Loại bữa<select className="h-10 w-full rounded-xl border px-3" value={form.mealType} onChange={e => setForm({ ...form, mealType: e.target.value })}>{Object.entries(types).map(([key, label]) => <option value={key} key={key}>{label}</option>)}</select></label>
        <label>Tên bữa<Input required maxLength={160} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>Ghi chú<Input maxLength={1000} value={form.notes ?? ''} onChange={e => setForm({ ...form, notes: e.target.value })} /></label>
      </div>
      <label className="block">Lấy từ bữa ăn / công thức đã lưu<select className="h-10 w-full rounded-xl border px-3" value={form.collectionId ?? ''} onChange={e => setForm({ ...form, collectionId: e.target.value || undefined })}><option value="">Chọn thực phẩm riêng</option>{[...(convenience.data?.savedMeals ?? []), ...(convenience.data?.recipes ?? [])].map(c => <option key={c.id} value={c.id}>{c.name} · {c.caloriesPerServing.toFixed(0)} kcal/phần</option>)}</select></label>
      {convenience.isError && <p role="alert">Không tải được bữa đã lưu. Bạn vẫn có thể chọn thực phẩm riêng.</p>}
      {form.collectionId ? <label className="block">Số khẩu phần cần lên kế hoạch<Input required type="number" min="0.001" max="1000" step="any" value={form.servings ?? 1} onChange={e => setForm({ ...form, servings: Number(e.target.value) })} /></label> : <>
        <label className="block">Tìm thực phẩm<Input value={search} onChange={e => { setSearch(e.target.value); setSearchPage(0); }} placeholder="Tên món…" /></label>
        {foods.isError && <p role="alert">{message(foods.error)}</p>}
        <div className="grid max-h-40 grid-cols-1 overflow-y-auto gap-2 sm:grid-cols-2">{foods.data?.content.map(f => <Button type="button" key={f.id} variant="outline" className="h-auto whitespace-normal justify-start py-2" disabled={items.length >= 100} onClick={() => setItems(current => [...current, { foodId: f.id, foodName: f.name, servingAmount: 1, servingUnit: 'SERVING' }])}>+ {f.name} · {f.unit}</Button>)}</div>
        <div className="flex gap-2"><Button type="button" size="sm" variant="outline" disabled={!searchPage || foods.isFetching} onClick={() => setSearchPage(p => p - 1)}>Trang trước</Button><Button type="button" size="sm" variant="outline" disabled={foods.isFetching || !foods.data || foods.data.last} onClick={() => setSearchPage(p => p + 1)}>Trang sau</Button></div>
        <div className="space-y-3">{items.map((item, index) => <div key={index} className="grid grid-cols-2 gap-2 rounded-xl border p-3 sm:grid-cols-4"><p className="col-span-2 font-medium sm:col-span-1">{item.foodName}</p><label>Số lượng<Input required aria-label={`Số lượng ${item.foodName}`} type="number" step="any" min="0.001" max="100000" value={item.servingAmount} onChange={e => setItems(current => current.map((v, i) => i === index ? { ...v, servingAmount: Number(e.target.value) } : v))} /></label><label>Đơn vị<select className="h-10 w-full rounded-xl border" value={item.servingUnit} onChange={e => setItems(current => current.map((v, i) => i === index ? { ...v, servingUnit: e.target.value as ServingUnit } : v))}>{Object.entries(units).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></label><Button type="button" variant="destructive" className="self-end" onClick={() => setItems(current => current.filter((_, i) => i !== index))}>Bỏ món</Button></div>)}</div>
        <p className="text-xs text-muted-foreground">Gram/ml chỉ dùng khi kho đã khai báo khẩu phần đúng loại. Máy chủ sẽ từ chối đổi gram sang ml.</p>
      </>}
      <Button disabled={busy}>{busy ? 'Đang lưu…' : 'Lưu kế hoạch'}</Button></form>
    </DialogContent></Dialog>
  </div>;
}
