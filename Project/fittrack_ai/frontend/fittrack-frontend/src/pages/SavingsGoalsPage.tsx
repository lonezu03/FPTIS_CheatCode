import { useEffect, useState, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getApiErrorMessage } from '@/lib/format';
import { savingsApi as api, type SavingsGoal, type SavingsOperation } from '../api/savings.api';
const input = 'w-full rounded-xl border p-3';
export default function SavingsGoalsPage() {
    const [page, setPage] = useState(0), [archived, setArchived] = useState(false), [busy, setBusy] = useState(false), [error, setError] = useState(''), [draft, setDraft] = useState<Partial<SavingsGoal> | null>(null), [selected, setSelected] = useState<SavingsGoal | null>(null), [history, setHistory] = useState<SavingsOperation[]>([]), [historyPage, setHistoryPage] = useState(0), [historyPages, setHistoryPages] = useState(0), [amount, setAmount] = useState(''), [type, setType] = useState<'ADD' | 'RELEASE'>('ADD'), [note, setNote] = useState('');
    const listing=useQuery({queryKey:['savings-goals',page,archived],queryFn:()=>api.list(page,archived)});
    const goals=listing.data?.content??[],pages=listing.data?.totalPages??0;
    const visibleError=error||(listing.error?getApiErrorMessage(listing.error,'Không tải được mục tiêu. Vui lòng thử lại.'):'');
    const historyGeneration=useRef(0);
    useEffect(()=>()=>{historyGeneration.current++;},[]);
    const operation = useRef<{
        key: string;
        fingerprint: string;
    } | null>(null);
    const fail=(e:unknown)=>setError(getApiErrorMessage(e,'Không thể xử lý. Vui lòng thử lại.'));
    const mutate = async (fn: () => Promise<unknown>) => { if (busy)
        return; setBusy(true); try {
        await fn();
        await listing.refetch();
        setError('');
    }
    catch (e) {
        fail(e);
    }
    finally {
        setBusy(false);
    } };
    const show = async (g: SavingsGoal, p = 0) => { const generation=++historyGeneration.current;setSelected(g); setHistoryPage(p);setHistory([]); try {
        const h = await api.history(g.id, p);
        if(generation===historyGeneration.current){setHistory(h.content);setHistoryPages(h.totalPages);}
    }
    catch (e) {
        if(generation===historyGeneration.current)fail(e);
    } };
    return <main className="space-y-5 p-4 sm:p-6"><h1 className="text-2xl font-bold">Mục tiêu tiết kiệm</h1><p className="rounded-xl bg-amber-50 p-4">Đây là sổ ghi nhận tiến độ, KHÔNG khóa tiền, không trừ ví, không tạo thu/chi hay chuyển khoản thật. Số tiền và tổng tiến độ tối đa 1.000.000.000.000, tối đa 2 số thập phân.</p>{visibleError && <p role="alert" className="text-red-700">{visibleError}</p>}<div className="flex flex-wrap gap-4"><button disabled={busy} onClick={() => setDraft({ title: '', currencyCode: 'VND', archived: false })}>+ Tạo mục tiêu</button><label><input type="checkbox" checked={archived} onChange={e => { setArchived(e.target.checked); setPage(0); }}/> Đã lưu trữ</label></div>
 {draft && <form className="grid gap-4 rounded-xl border bg-white p-4 sm:grid-cols-2" onSubmit={e => { e.preventDefault(); void mutate(async () => { await api.save(draft); setDraft(null); }); }}><label>Tên mục tiêu<input required maxLength={160} className={input} value={draft.title ?? ''} onChange={e => setDraft({ ...draft, title: e.target.value })}/></label><label>Số tiền đích<input required type="number" min="0.01" max="1000000000000" step="0.01" className={input} value={draft.target ?? ''} onChange={e => setDraft({ ...draft, target: Number(e.target.value) })}/></label><label>Tiền tệ<input required pattern="[A-Za-z]{3}" disabled={!!draft.id} className={input} value={draft.currencyCode ?? 'VND'} onChange={e => setDraft({ ...draft, currencyCode: e.target.value.toUpperCase() })}/></label><label>Ngày mục tiêu<input type="date" className={input} value={draft.targetDate ?? ''} onChange={e => setDraft({ ...draft, targetDate: e.target.value || undefined })}/></label><label>Ghi chú<textarea maxLength={1000} className={input} value={draft.note ?? ''} onChange={e => setDraft({ ...draft, note: e.target.value })}/></label><div className="flex gap-4"><button disabled={busy}>Lưu mục tiêu</button><button type="button" onClick={() => setDraft(null)}>Hủy</button></div></form>}
 <div className="grid gap-4 lg:grid-cols-2">{goals.map(g => <article key={g.id} className="space-y-3 rounded-2xl border bg-white p-4"><h2 className="font-bold">{g.title}</h2><p>{g.progress.toLocaleString('vi-VN')} / {g.target.toLocaleString('vi-VN')} {g.currencyCode}</p><progress className="w-full" max={g.target} value={Math.min(g.progress, g.target)}/><p>{Math.round(g.progress / g.target * 100)}% · {g.targetDate ?? 'Chưa đặt ngày'} · {g.note}</p><div className="flex flex-wrap gap-4"><button onClick={() => setDraft({ ...g })}>Sửa</button><button onClick={() => void show(g)}>Ghi nhận / lịch sử</button>{!g.archived && <button disabled={busy} onClick={() => { if (confirm('Lưu trữ mục tiêu và giữ lịch sử?'))
        void mutate(() => api.archive(g)); }}>Lưu trữ</button>}</div></article>)}</div><div className="flex gap-4"><button disabled={page === 0 || busy} onClick={() => setPage(p => p - 1)}>Trước</button>{page + 1}/{Math.max(1, pages)}<button disabled={page + 1 >= pages || busy} onClick={() => setPage(p => p + 1)}>Sau</button></div>
 {selected && <section className="space-y-4 rounded-2xl border bg-white p-4"><div className="flex justify-between"><h2>{selected.title}</h2><button onClick={() => setSelected(null)}>Đóng</button></div>{!selected.archived && <form className="grid gap-3 sm:grid-cols-2" onSubmit={e => { e.preventDefault(); void mutate(async () => { const fingerprint = JSON.stringify([selected.id, type, amount, note]); if (operation.current?.fingerprint !== fingerprint)
        operation.current = { key: crypto.randomUUID(), fingerprint }; await api.record(selected.id, { operationId: operation.current.key, type, amount: Number(amount), currencyCode: selected.currencyCode, note }); operation.current = null; setAmount(''); setNote(''); await show(selected); }); }}><label>Thao tác<select className={input} value={type} onChange={e => setType(e.target.value as 'ADD' | 'RELEASE')}><option value="ADD">Tăng tiến độ</option><option value="RELEASE">Giảm tiến độ</option></select></label><label>Số tiền ({selected.currencyCode})<input required type="number" min="0.01" max="1000000000000" step="0.01" className={input} value={amount} onChange={e => setAmount(e.target.value)}/></label><label>Ghi chú đối soát<input maxLength={1000} className={input} value={note} onChange={e => setNote(e.target.value)}/></label><button disabled={busy}>Xác nhận ghi nhận — không chuyển tiền thật</button></form>}<ul>{history.map(h => <li key={h.id} className="border-b py-3">{h.createdAt.replace('T', ' ')} · {h.type === 'ADD' ? '+' : '−'}{h.amount.toLocaleString('vi-VN')} {h.currencyCode} · {h.note}</li>)}</ul><div className="flex gap-4"><button disabled={historyPage === 0} onClick={() => void show(selected, historyPage - 1)}>Lịch sử trước</button>{historyPage + 1}/{Math.max(1, historyPages)}<button disabled={historyPage + 1 >= historyPages} onClick={() => void show(selected, historyPage + 1)}>Lịch sử sau</button></div></section>}
 </main>;
}
