import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { catalogImportColumns, catalogImportHistory, commitCatalogImport, downloadCatalogFile, previewCatalogImport, type CatalogKind, type ImportBatch, type ImportSelection } from '@/api/catalog-import.api';

type Props = { kind: CatalogKind; open: boolean; onOpenChange: (open: boolean) => void; onImported: () => void };
const names: Record<string, string> = { id: 'ID cập nhật', name: 'Tên', muscleGroup: 'Nhóm cơ chính', equipment: 'Dụng cụ', description: 'Hướng dẫn', imageUrl: 'URL ảnh HTTPS', unit: 'Đơn vị khẩu phần', basis: 'Cơ sở dinh dưỡng', servingSizeGrams: 'Khối lượng khẩu phần (g)', calories: 'Năng lượng (kcal)', protein: 'Đạm (g)', carbs: 'Carb (g)', fat: 'Béo (g)', fiber: 'Xơ (g)', sugar: 'Đường (g)', sodium: 'Natri (mg)', potassium: 'Kali (mg)', calcium: 'Canxi (mg)', iron: 'Sắt (mg)', vitaminC: 'Vitamin C (mg)', water: 'Nước (ml)', barcode: 'Mã vạch', dataSourceType: 'Loại nguồn', dataSourceName: 'Nguồn dữ liệu' };
const message = (error: unknown) => {
  const candidate = error as { response?: { data?: { message?: string } }; message?: string };
  return candidate.response?.data?.message ?? candidate.message ?? 'Không thể xử lý lô nhập. Vui lòng thử lại.';
};
export function CatalogImportDialog({ kind, open, onOpenChange, onImported }: Props) {
  const [file, setFile] = useState<File | null>(null);
  const [text, setText] = useState('');
  const [mapping, setMapping] = useState<Record<string, string>>({});
  const [ignoredColumns, setIgnoredColumns] = useState('');
  const [batch, setBatch] = useState<ImportBatch | null>(null);
  const [selections, setSelections] = useState<ImportSelection[]>([]);
  const [busy, setBusy] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [historyOpen, setHistoryOpen] = useState(false);
  const history = useQuery({ queryKey: ['catalog-import-history', kind], queryFn: () => catalogImportHistory(kind), enabled: open && historyOpen });
  const selected = selections.filter(s => s.action !== 'SKIP').length;
  const resetPreview = () => { setBatch(null); setSelections([]); setConfirmed(false); };
  const preview = async () => {
    setBusy(true); try { const result = await previewCatalogImport(kind, file, text, mapping); setBatch(result); setSelections(result.rows.map(row => ({ number: row.number, action: row.suggestedAction, clearFields: [] }))); setConfirmed(false); }
    catch (error) { toast.error(message(error)); } finally { setBusy(false); }
  };
  const commit = async () => {
    if (!batch || !confirmed || selected === 0) return;
    setBusy(true); try { const result = await commitCatalogImport(batch.id, selections); setBatch(result); toast.success(`Đã xử lý ${selected} dòng. Lịch sử lô nhập đã được lưu.`); onImported(); void history.refetch(); }
    catch (error) { toast.error(message(error)); } finally { setBusy(false); }
  };
  const download = async (path: string, filename: string) => { try { await downloadCatalogFile(path, filename); } catch (error) { toast.error(message(error)); } };
  return <Dialog open={open} onOpenChange={value => { if (!busy) onOpenChange(value); }}>
    <DialogContent className="flex max-h-[92dvh] w-[calc(100%-1rem)] max-w-5xl flex-col overflow-hidden sm:max-w-5xl">
      <DialogHeader><DialogTitle>Nhập hàng loạt {kind === 'FOOD' ? 'thực phẩm' : 'bài tập'}</DialogTitle><DialogDescription>Kiểm tra và xác nhận dữ liệu trước khi ghi vào kho.</DialogDescription></DialogHeader>
      <div className="min-h-0 space-y-4 overflow-y-auto pr-1">
        <p className="text-sm text-muted-foreground">Tối đa 500 dòng / 2 MB. Chọn Excel .xlsx, CSV UTF-8 hoặc dán bảng có dòng tiêu đề. Nhập dữ liệu dạng giá trị, không dùng công thức.</p>
        <div className="flex flex-wrap gap-2">{(['csv', 'xlsx'] as const).map(format => <Button key={format} variant="outline" disabled={busy} onClick={() => void download(`${kind}/template?format=${format}`, `${kind}-template.${format}`)}>Tải mẫu {format.toUpperCase()}</Button>)}<Button variant="outline" disabled={busy} onClick={() => void download(`${kind}/export?format=xlsx`, `${kind}-export.xlsx`)}>Xuất kho kèm ID để cập nhật</Button><Button variant="outline" onClick={() => setHistoryOpen(!historyOpen)}>Lịch sử nhập</Button></div>
        {historyOpen && <div className="rounded-xl border p-3 text-sm"><p className="font-medium">30 lô gần nhất của bạn</p>{history.isLoading ? <p>Đang tải…</p> : history.isError ? <p>Không tải được lịch sử.</p> : history.data?.length ? history.data.map(item => <div key={item.id} className="mt-2 flex flex-wrap items-center justify-between gap-2 border-t pt-2"><span>{new Date(item.createdAt).toLocaleString('vi-VN')} · {item.rowCount} dòng · {item.committedAt ? `${item.importedCount} đã nhập` : 'Đã xem trước'} · {item.errorCount} lỗi</span><Button size="sm" variant="outline" onClick={() => void download(`${item.id}/errors.csv`, 'dong-loi.csv')}>Tải dòng lỗi</Button></div>) : <p>Chưa có lịch sử.</p>}</div>}
        <label className="block space-y-1 text-sm"><span>Chọn file</span><Input type="file" accept=".csv,.xlsx" disabled={busy} onChange={event => { const next = event.target.files?.[0] ?? null; if (next && next.size > 2_000_000) { toast.error('File tối đa 2 MB'); event.target.value = ''; return; } setFile(next); resetPreview(); }} /></label>
        <label className="block space-y-1 text-sm"><span>Hoặc dán bảng từ Excel / Google Sheets</span><textarea className="min-h-28 w-full rounded-xl border p-3 font-mono text-xs" disabled={busy || !!file} value={text} onChange={event => { setText(event.target.value); resetPreview(); }} placeholder={catalogImportColumns[kind].join('\t')} /></label>
        {file && <Button size="sm" variant="ghost" disabled={busy} onClick={() => { setFile(null); resetPreview(); }}>Dùng bảng dán thay cho file</Button>}
        <details className="rounded-xl border p-3"><summary className="cursor-pointer text-sm font-medium">Ánh xạ tên cột tùy chỉnh</summary><p className="my-2 text-xs text-muted-foreground">Nếu dùng đúng file mẫu thì để trống. Nhập tiêu đề cột nguồn tương ứng mỗi trường.</p><div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">{catalogImportColumns[kind].map(column => <label key={column} className="text-xs">{names[column]} ({column})<Input disabled={busy} value={Object.entries(mapping).find(([, target]) => target === column)?.[0] ?? ''} placeholder="Tên cột nguồn" onChange={event => { const next = Object.fromEntries(Object.entries(mapping).filter(([, target]) => target !== column)); if (event.target.value) next[event.target.value] = column; setMapping(next); resetPreview(); }} /></label>)}</div></details>
        <label className="block space-y-1 text-sm"><span>Cột muốn bỏ qua rõ ràng (tên cách nhau bằng dấu phẩy)</span><Input disabled={busy} value={ignoredColumns} placeholder="Ví dụ: errors, ghi chú nội bộ" onChange={event => { setIgnoredColumns(event.target.value); const next = Object.fromEntries(Object.entries(mapping).filter(([, value]) => value !== '__IGNORE__')); event.target.value.split(',').map(value => value.trim()).filter(Boolean).forEach(key => { next[key] = '__IGNORE__'; }); setMapping(next); resetPreview(); }} /></label>
        {kind === 'FOOD' && <p className="rounded-xl bg-muted p-3 text-sm">Cột <b>basis</b>: PER_SERVING = theo khẩu phần; PER_100G = theo 100 g và bắt buộc khối lượng khẩu phần (servingSizeGrams). Vi chất trống được giữ là chưa biết. Không quy đổi g sang ml. Các trường vitamin/khoáng chất dùng đơn vị ghi trong ánh xạ.</p>}
        <p className="text-xs text-muted-foreground">Thêm mới: để trống ID. Cập nhật: dùng ID bản ghi hiện có; ô trống giữ giá trị cũ. Không tự duyệt hoặc bật lại bản ghi bị lưu trữ.</p>
        <Button disabled={busy || (!file && !text.trim())} onClick={() => void preview()}>{busy ? 'Đang xử lý…' : 'Kiểm tra và xem trước'}</Button>
        {batch && <section className="space-y-3"><p className="font-medium">{batch.rows.length} dòng · {batch.rows.filter(r => r.errors.length).length} dòng lỗi · {selected} dòng được chọn</p>
          {!batch.committedAt && <div className="flex flex-wrap gap-2"><Button size="sm" variant="outline" disabled={busy} onClick={() => { setSelections(selections.map(s => ({ ...s, action: 'SKIP' }))); setConfirmed(false); }}>Bỏ chọn tất cả</Button><Button size="sm" variant="outline" disabled={busy} onClick={() => { setSelections(selections.map(s => { const row = batch.rows.find(r => r.number === s.number); return row?.values.id && !row.errors.length && !row.warnings.length ? { ...s, action: 'UPDATE' } : s; })); setConfirmed(false); }}>Chọn cập nhật theo ID (không cảnh báo)</Button></div>}
          <div className="max-h-96 space-y-3 overflow-y-auto">{batch.rows.map(row => {
            const selection = selections.find(s => s.number === row.number);
            const output = row.after ?? row.values;
            return <article key={row.number} className="space-y-2 rounded-xl border p-3 text-sm">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <b>Dòng {row.number}: {row.values.name || '(Chưa có tên)'}</b>
                <select aria-label={`Thao tác dòng ${row.number}`} className="max-w-full rounded-lg border p-2" disabled={busy || !!batch.committedAt || !!row.errors.length} value={selection?.action ?? 'SKIP'} onChange={event => { setSelections(selections.map(s => s.number === row.number ? { ...s, action: event.target.value as ImportSelection['action'] } : s)); setConfirmed(false); }}>
                  <option value="SKIP">Bỏ qua</option>{row.values.id ? <option value="UPDATE">Cập nhật ID này</option> : <option value="CREATE">Thêm mới</option>}
                </select>
              </div>
              {row.errors.map(error => <p key={error} className="text-destructive">{error}</p>)}
              {row.warnings.map(warning => <p key={warning} className="text-amber-700">{warning}</p>)}
              <details><summary className="cursor-pointer text-xs">Xem dữ liệu {row.values.id ? 'cũ → mới' : 'sẽ nhập'}</summary>
                {row.values.basis === 'PER_100G' && <p className="mt-2 text-xs">Giá trị bên dưới đã quy đổi về một khẩu phần.</p>}
                <dl className="mt-2 grid gap-1 break-words text-xs">{Object.entries(output).filter(([field, value]) => value || selection?.clearFields.includes(field)).map(([field, value]) => <div key={field}>
                  <dt className="inline font-medium">{names[field] ?? field}: </dt>
                  <dd className="inline">{row.before[field] && (row.before[field] !== value || selection?.clearFields.includes(field)) ? `${row.before[field]} → ` : ''}{selection?.clearFields.includes(field) ? '(Xóa giá trị)' : value}</dd>
                </div>)}</dl>
              </details>
              {selection?.action === 'UPDATE' && !batch.committedAt && <details><summary className="cursor-pointer text-xs">Xóa rõ ràng trường tùy chọn</summary><div className="mt-2 flex flex-wrap gap-3">{(kind === 'FOOD' ? ['fiber', 'sugar', 'sodium', 'potassium', 'calcium', 'iron', 'vitaminC', 'water', 'barcode', 'dataSourceName', 'imageUrl'] : ['description', 'imageUrl']).map(field => <label key={field} className="flex items-center gap-1 text-xs">
                <input type="checkbox" disabled={busy} checked={selection.clearFields.includes(field)} onChange={event => { setSelections(selections.map(s => s.number === row.number ? { ...s, clearFields: event.target.checked ? [...s.clearFields, field] : s.clearFields.filter(v => v !== field) } : s)); setConfirmed(false); }} />{names[field]}
              </label>)}</div></details>}
            </article>;
          })}</div>
          <Button variant="outline" onClick={() => void download(`${batch.id}/errors.csv`, 'dong-loi.csv')}>Tải các dòng lỗi</Button>
          {!batch.committedAt && <label className="flex items-start gap-2 text-sm"><input type="checkbox" disabled={busy} checked={confirmed} onChange={event => setConfirmed(event.target.checked)} /><span>Tôi đã kiểm tra {selected} dòng và các cảnh báo trùng; xác nhận ghi thay đổi vào kho.</span></label>}
        </section>}
      </div>
      <div className="flex flex-wrap justify-end gap-2 border-t pt-3"><Button variant="outline" disabled={busy} onClick={() => onOpenChange(false)}>Đóng</Button><Button disabled={busy || !batch || !!batch.committedAt || !confirmed || selected === 0} onClick={() => void commit()}>{busy ? 'Đang xử lý…' : `Xác nhận nhập ${selected} dòng`}</Button></div>
    </DialogContent>
  </Dialog>;
}
export default CatalogImportDialog;
