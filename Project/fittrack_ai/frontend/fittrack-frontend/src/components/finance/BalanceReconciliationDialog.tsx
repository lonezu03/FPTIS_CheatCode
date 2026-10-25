import { useState, type FormEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { getFinanceAccounts, getFinanceReconciliations, reconcileFinanceAccount, type FinanceAccount } from '@/api/finance.api';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { formatDateTime, getApiErrorMessage } from '@/lib/format';

const money = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 2 });

export default function BalanceReconciliationDialog({ account, onClose }: { account: FinanceAccount; onClose: () => void }) {
  const client = useQueryClient();
  const [actual, setActual] = useState('');
  const [note, setNote] = useState('');
  const [confirmedBalance, setConfirmedBalance] = useState<number | null>(null);
  const [page, setPage] = useState(0);
  const current = useQuery({ queryKey: ['finance-reconcile-account', account.id], queryFn: async () => (await getFinanceAccounts()).find(item => item.id === account.id) ?? null, staleTime: 0 });
  const history = useQuery({ queryKey: ['finance-reconciliation-history', account.id, page], queryFn: () => getFinanceReconciliations(account.id, page) });
  const balance = current.data?.currentBalance;
  const amount = Number(actual);
  const valid = actual.trim() !== '' && /^-?\d+(?:\.\d{1,2})?$/.test(actual) && Number.isFinite(amount) && Math.abs(amount) <= 999999999999999 && note.trim().length > 0;
  const difference = balance == null || !valid ? null : Math.round((amount - balance) * 100) / 100;
  const save = useMutation({
    mutationFn: () => reconcileFinanceAccount(account.id, { actualBalance: amount, expectedBalance: balance!, note: note.trim() }),
    onSuccess: () => {
      void client.invalidateQueries({ predicate: query => String(query.queryKey[0]).startsWith('finance-') });
      void client.invalidateQueries({ queryKey: ['dashboard-today'] });
      toast.success('Đã đối soát số dư ví. Lịch sử thu chi được giữ nguyên.');
      onClose();
    },
    onError: error => { toast.error(getApiErrorMessage(error, 'Không thể đối soát số dư')); setConfirmedBalance(null); void current.refetch(); },
  });
  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (valid && difference !== null && difference !== 0 && balance != null && confirmedBalance === balance && !current.isFetching && current.data?.active && !save.isPending) save.mutate();
  };

  return <Dialog open onOpenChange={open => { if (!open && !save.isPending) onClose(); }}>
    <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-xl">
      <DialogHeader><DialogTitle>Đối soát số dư · {account.name}</DialogTitle><DialogDescription>Nhập số tiền thực tế đang có trong ví hoặc ngân hàng. Khoản chênh lệch được ghi riêng, không tính thành thu nhập hay chi tiêu.</DialogDescription></DialogHeader>
      {current.isLoading ? <p>Đang lấy số dư mới nhất...</p> : current.isError || !current.data ? <div><p>Không thể lấy thông tin ví.</p><Button variant="outline" onClick={() => void current.refetch()}>Thử lại</Button></div> : <form onSubmit={submit} className="space-y-4">
        <p className="rounded-xl bg-muted p-3 text-sm">Số dư trên ứng dụng: <strong>{money.format(balance!)}</strong></p>
        {!current.data.active ? <p className="text-sm text-muted-foreground">Ví đã lưu trữ. Bạn có thể xem lịch sử đối soát bên dưới.</p> : <>
          <div className="space-y-2"><Label htmlFor="reconcile-actual">Số dư thực tế (VND)</Label><Input id="reconcile-actual" type="number" inputMode="decimal" step="0.01" value={actual} onChange={event => { setActual(event.target.value); setConfirmedBalance(null); }} placeholder="Ví dụ: 2500000" required disabled={save.isPending} /><p className="text-xs text-muted-foreground">Nhập 0 nếu ví đã hết tiền; cho phép số âm khi thực tế đang âm.</p></div>
          <div className="space-y-2"><Label htmlFor="reconcile-note">Lý do điều chỉnh</Label><Input id="reconcile-note" value={note} onChange={event => setNote(event.target.value)} maxLength={500} placeholder="Ví dụ: bắt đầu theo dõi lại sau thời gian nghỉ" required disabled={save.isPending} /></div>
          {difference !== null && <p role="status" className="rounded-xl border p-3 text-sm">{difference === 0 ? 'Số dư đã khớp, không cần điều chỉnh.' : <>Chênh lệch: <strong>{difference > 0 ? '+' : ''}{money.format(difference)}</strong>. Sau xác nhận, ví sẽ có <strong>{money.format(amount)}</strong>.</>}</p>}
          <label className="flex items-start gap-3 text-sm"><input className="mt-1 size-4" type="checkbox" checked={balance != null && confirmedBalance === balance} onChange={event => setConfirmedBalance(event.target.checked ? balance! : null)} disabled={!valid || save.isPending || current.isFetching} />Tôi đã kiểm tra số tiền thực tế và muốn lưu điều chỉnh này.</label>
        </>}
        <DialogFooter><Button type="button" variant="outline" disabled={save.isPending} onClick={onClose}>Đóng</Button>{current.data.active && <Button type="submit" disabled={!valid || difference === null || difference === 0 || confirmedBalance !== balance || current.isFetching || save.isPending}>{save.isPending ? 'Đang lưu...' : 'Xác nhận đối soát'}</Button>}</DialogFooter>
      </form>}
      <section className="space-y-3 border-t pt-4"><h3 className="font-semibold">Lịch sử điều chỉnh</h3>
        {history.isLoading ? <p className="text-sm">Đang tải lịch sử...</p> : history.isError ? <div><p className="text-sm">Không thể tải lịch sử.</p><Button variant="outline" size="sm" onClick={() => void history.refetch()}>Thử lại</Button></div> : !history.data?.content.length ? <p className="text-sm text-muted-foreground">Chưa có điều chỉnh nào.</p> : history.data.content.map(row => <div key={row.id} className="space-y-1 rounded-xl border p-3 text-sm"><p>{money.format(row.balanceBefore)} → <strong>{money.format(row.balanceAfter)}</strong></p><p className="break-words">{row.note}</p><p className="text-xs text-muted-foreground">{formatDateTime(row.createdAt)}</p></div>)}
        {history.data && history.data.totalPages > 1 && <div className="flex items-center justify-between gap-2"><Button variant="outline" size="sm" disabled={page === 0 || history.isFetching} onClick={() => setPage(value => value - 1)}>Trước</Button><span className="text-xs">Trang {page + 1}/{history.data.totalPages}</span><Button variant="outline" size="sm" disabled={page + 1 >= history.data.totalPages || history.isFetching} onClick={() => setPage(value => value + 1)}>Sau</Button></div>}
      </section>
    </DialogContent>
  </Dialog>;
}
