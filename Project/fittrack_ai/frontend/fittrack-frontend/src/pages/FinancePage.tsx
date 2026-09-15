/* eslint-disable @typescript-eslint/no-explicit-any */
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowDownRight, ArrowLeftRight, ArrowUpRight, Landmark, Plus, Trash2, WalletCards } from "lucide-react";
import { toast } from "sonner";
import {
  archiveFinanceAccount, archiveFinanceCategory, archiveFinanceRecurring, confirmFinanceRecurring,
  createFinanceAccount, createFinanceCategory, createFinanceRecurring, createFinanceTransaction,
  deleteFinanceBudget, getFinanceAccounts, getFinanceBudgets, getFinanceCategories, getFinanceDashboard,
  getFinanceRecurring, getFinanceReport, getFinanceTransactions, saveFinanceBudget, voidFinanceTransaction,
  type ExpenseNature,
} from "../api/finance.api";
import PageHeader from "../components/PageHeader";
import PageLoading from "../components/common/PageLoading";
import ErrorState from "../components/common/ErrorState";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const money = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 });
const natureLabels: Record<string, string> = {
  FIXED_MANDATORY: "Bắt buộc cố định", ESSENTIAL_VARIABLE: "Thiết yếu biến động",
  TRUE_EXPENSE: "Khoản phải chuẩn bị", SAVING: "Tiết kiệm / mục tiêu",
  DISCRETIONARY: "Tùy ý / hưởng thụ", UNCLASSIFIED: "Chưa phân loại",
};
const monthNow = new Date().toISOString().slice(0, 7);
const monthDate = (value: string) => `${value}-01`;
const localDateTime = () => {
  const d = new Date(Date.now() - new Date().getTimezoneOffset() * 60_000);
  return d.toISOString().slice(0, 16);
};

export default function FinancePage() {
  const qc = useQueryClient();
  const [month, setMonth] = useState(monthNow);
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState("");
  const [type, setType] = useState("");
  const [transactionOpen, setTransactionOpen] = useState(false);
  const [accountOpen, setAccountOpen] = useState(false);
  const [categoryOpen, setCategoryOpen] = useState(false);
  const [budgetOpen, setBudgetOpen] = useState(false);
  const [recurringOpen, setRecurringOpen] = useState(false);
  const monthValue = monthDate(month);
  const dashboard = useQuery({ queryKey: ["finance-dashboard", month], queryFn: () => getFinanceDashboard(monthValue) });
  const accounts = useQuery({ queryKey: ["finance-accounts"], queryFn: getFinanceAccounts });
  const categories = useQuery({ queryKey: ["finance-categories"], queryFn: getFinanceCategories });
  const budgets = useQuery({ queryKey: ["finance-budgets", month], queryFn: () => getFinanceBudgets(monthValue) });
  const recurring = useQuery({ queryKey: ["finance-recurring"], queryFn: getFinanceRecurring });
  const report = useQuery({ queryKey: ["finance-report", month], queryFn: () => getFinanceReport(monthValue) });
  const transactions = useQuery({
    queryKey: ["finance-transactions", month, page, search, type],
    queryFn: () => getFinanceTransactions({ from: monthValue, to: endOfMonth(month), page, size: 15, q: search || undefined, type: type || undefined }),
  });
  const refresh = () => qc.invalidateQueries({ predicate: (query) => String(query.queryKey[0]).startsWith("finance-") });
  const voidMutation = useFinanceAction(voidFinanceTransaction, "Đã hủy giao dịch");
  const deleteBudgetMutation = useFinanceAction(deleteFinanceBudget, "Đã xóa ngân sách");
  const confirmRecurringMutation = useFinanceAction(confirmFinanceRecurring, "Đã ghi nhận khoản định kỳ");
  const archiveRecurringMutation = useFinanceAction(archiveFinanceRecurring, "Đã ngừng khoản định kỳ");
  const archiveAccountMutation = useFinanceAction(archiveFinanceAccount, "Đã lưu trữ tài khoản");
  const archiveCategoryMutation = useFinanceAction(archiveFinanceCategory, "Đã lưu trữ danh mục");
  if (dashboard.isLoading || accounts.isLoading || categories.isLoading) return <PageLoading />;
  if (dashboard.isError || !dashboard.data) return <ErrorState title="Không thể tải tài chính" message="Vui lòng thử lại. Nếu lỗi tiếp diễn, hãy lưu mã yêu cầu để kiểm tra log." />;
  const data = dashboard.data;
  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader title="Tài chính cá nhân" description="Theo dõi tiền, chuẩn bị nghĩa vụ và biết phần còn có thể sử dụng. FitTrack không giữ hoặc chuyển tiền thật." />
        <div className="flex flex-wrap gap-2">
          <Input aria-label="Tháng tài chính" className="w-40" type="month" value={month} onChange={(e) => { setMonth(e.target.value); setPage(0); }} />
          <Button onClick={() => setTransactionOpen(true)}><Plus className="size-4" /> Ghi giao dịch</Button>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Metric title="Thu nhập" value={data.income} icon={ArrowDownRight} tone="bg-emerald-50 text-emerald-800" />
        <Metric title="Chi tiêu" value={data.expense} icon={ArrowUpRight} tone="bg-rose-50 text-rose-800" />
        <Metric title="Chi bắt buộc dự kiến" value={data.mandatoryCommitted} detail={`Còn phải trả ${money.format(data.mandatoryRemaining)}`} icon={Landmark} tone="bg-amber-50 text-amber-900" />
        <Metric title="Tiền linh hoạt" value={data.flexibleAvailable} detail={`Tiết kiệm ${money.format(data.savingCommitted)} · chuẩn bị ${money.format(data.trueExpensePreparation)}`} icon={WalletCards} tone="bg-blue-50 text-blue-900" />
      </div>

      <Card className="border-emerald-200 bg-emerald-50/50"><CardContent className="p-5"><p className="font-semibold text-emerald-950">Góc nhìn tháng này</p><p className="mt-1 text-sm leading-6 text-emerald-950/75">{data.insight}</p></CardContent></Card>

      <Tabs defaultValue="overview" className="gap-4">
        <TabsList className="max-w-full justify-start overflow-x-auto">
          <TabsTrigger value="overview">Tổng quan</TabsTrigger><TabsTrigger value="transactions">Giao dịch</TabsTrigger>
          <TabsTrigger value="budgets">Ngân sách</TabsTrigger><TabsTrigger value="recurring">Định kỳ</TabsTrigger><TabsTrigger value="settings">Thiết lập</TabsTrigger>
        </TabsList>
        <TabsContent value="overview" className="grid gap-4 lg:grid-cols-2">
          <Card><CardHeader><CardTitle>Tài khoản</CardTitle></CardHeader><CardContent className="space-y-3">
            {(data.accounts.length === 0) ? <Empty text="Tạo tài khoản tiền đầu tiên để bắt đầu." /> : data.accounts.filter((a) => a.active).map((a) => <div key={a.id} className="flex items-center justify-between rounded-xl border p-3"><div><p className="font-semibold">{a.name}</p><p className="text-xs text-muted-foreground">{accountTypeLabel(a.accountType)}</p></div><p className="font-bold">{money.format(a.currentBalance)}</p></div>)}
            <Button variant="outline" className="w-full" onClick={() => setAccountOpen(true)}><Plus className="size-4" /> Thêm tài khoản</Button>
          </CardContent></Card>
          <Card><CardHeader><CardTitle>Tiền đi đâu?</CardTitle></CardHeader><CardContent className="space-y-4">
            {data.topCategories.length === 0 ? <Empty text="Chưa có giao dịch chi tiêu trong tháng." /> : data.topCategories.map((item) => <div key={item.categoryId}><div className="mb-1 flex justify-between gap-3 text-sm"><span>{item.categoryName}</span><strong>{money.format(item.amount)}</strong></div><Progress value={data.expense ? Math.min(100, item.amount / data.expense * 100) : 0} /></div>)}
          </CardContent></Card>
          <Card><CardHeader><CardTitle>5 nhóm tính chất khoản chi</CardTitle></CardHeader><CardContent className="space-y-3">
            {data.natureBreakdown.length === 0 ? <Empty text="Chưa đủ dữ liệu phân loại." /> : data.natureBreakdown.map((item) => <div key={item.expenseNature} className="flex items-center justify-between rounded-xl bg-muted/35 p-3"><span>{natureLabels[item.expenseNature]}</span><span className="text-right"><strong>{money.format(item.amount)}</strong><small className="ml-2 text-muted-foreground">{item.percentOfIncome.toFixed(1)}% thu nhập</small></span></div>)}
          </CardContent></Card>
          <Card><CardHeader><CardTitle>So với tháng trước</CardTitle></CardHeader><CardContent className="space-y-3">
            <ReportLine label="Thu nhập" value={report.data?.income ?? 0}/><ReportLine label="Chi tiêu" value={report.data?.expense ?? 0}/><ReportLine label="Tiết kiệm ròng" value={report.data?.netSaving ?? 0}/><ReportLine label="Chênh lệch chi tiêu" value={report.data?.expenseChange ?? 0} signed />
          </CardContent></Card>
        </TabsContent>

        <TabsContent value="transactions"><Card><CardHeader><div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"><CardTitle>Lịch sử giao dịch</CardTitle><div className="flex gap-2"><Input placeholder="Tìm nơi chi, ghi chú..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(0); }}/><select className="rounded-xl border bg-background px-3" value={type} onChange={(e) => { setType(e.target.value); setPage(0); }}><option value="">Tất cả</option><option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option><option value="TRANSFER">Chuyển khoản</option></select></div></div></CardHeader><CardContent>
          {!transactions.data?.content.length ? <Empty text="Không có giao dịch phù hợp." /> : <div className="space-y-2">{transactions.data.content.map((tx) => <div key={tx.id} className="flex flex-col gap-2 rounded-xl border p-3 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-3"><span className={`grid size-9 place-items-center rounded-xl ${tx.type === "INCOME" ? "bg-emerald-100 text-emerald-700" : tx.type === "EXPENSE" ? "bg-rose-100 text-rose-700" : "bg-blue-100 text-blue-700"}`}>{tx.type === "TRANSFER" ? <ArrowLeftRight className="size-4"/> : tx.type === "INCOME" ? <ArrowDownRight className="size-4"/> : <ArrowUpRight className="size-4"/>}</span><div><p className="font-semibold">{tx.categoryName || `${tx.accountName} → ${tx.destinationAccountName}`}</p><p className="text-xs text-muted-foreground">{new Date(tx.occurredAt).toLocaleString("vi-VN")} {tx.merchant ? `· ${tx.merchant}` : ""}</p></div></div><div className="flex items-center justify-between gap-3"><strong className={tx.type === "INCOME" ? "text-emerald-700" : tx.type === "EXPENSE" ? "text-rose-700" : ""}>{tx.type === "INCOME" ? "+" : tx.type === "EXPENSE" ? "−" : ""}{money.format(tx.amount)}</strong><Button size="icon-sm" variant="ghost" aria-label="Xóa giao dịch" onClick={() => confirm("Đưa giao dịch này vào trạng thái đã hủy?") && voidMutation.mutate(tx.id)}><Trash2 className="size-4 text-rose-600"/></Button></div></div>)}</div>}
          {(transactions.data?.totalPages ?? 0) > 1 && <div className="mt-4 flex items-center justify-end gap-2"><Button variant="outline" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>Trước</Button><span className="text-sm">Trang {page + 1}/{transactions.data?.totalPages}</span><Button variant="outline" disabled={transactions.data?.last} onClick={() => setPage((p) => p + 1)}>Sau</Button></div>}
        </CardContent></Card></TabsContent>

        <TabsContent value="budgets"><Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Ngân sách theo danh mục</CardTitle><Button onClick={() => setBudgetOpen(true)}><Plus className="size-4"/> Thêm ngân sách</Button></div></CardHeader><CardContent className="grid gap-3 md:grid-cols-2">
          {!budgets.data?.length ? <Empty text="Chưa đặt ngân sách cho tháng này." /> : budgets.data.map((b) => <div key={b.id} className={`rounded-xl border p-4 ${b.percent >= 100 ? "border-rose-300 bg-rose-50/50" : b.percent >= 80 ? "border-amber-300 bg-amber-50/50" : ""}`}><div className="flex justify-between"><strong>{b.categoryName}</strong><Button size="icon-sm" variant="ghost" onClick={() => deleteBudgetMutation.mutate(b.id)}><Trash2 className="size-4"/></Button></div><p className="mt-1 text-sm">{money.format(b.spent)} / {money.format(b.amount)}</p><Progress className="mt-3" value={Math.min(100, b.percent)}/><p className="mt-2 text-xs text-muted-foreground">Còn {money.format(b.remaining)} · Dự kiến cuối tháng {money.format(b.projected)} {b.projectedOver ? "⚠" : ""}</p></div>)}
        </CardContent></Card></TabsContent>

        <TabsContent value="recurring"><Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Khoản định kỳ sắp tới</CardTitle><Button onClick={() => setRecurringOpen(true)}><Plus className="size-4"/> Thêm khoản</Button></div></CardHeader><CardContent className="space-y-3">
          {!recurring.data?.filter((r) => r.active).length ? <Empty text="Chưa có khoản định kỳ."/> : recurring.data?.filter((r) => r.active).map((r) => <div key={r.id} className="flex flex-col gap-3 rounded-xl border p-4 sm:flex-row sm:items-center sm:justify-between"><div><p className="font-semibold">{r.name}</p><p className="text-sm text-muted-foreground">{money.format(r.amount)} · hạn {new Date(`${r.nextDueDate}T00:00:00`).toLocaleDateString("vi-VN")} · {frequencyLabel(r.frequency)}</p><Badge variant="outline" className="mt-2">{natureLabels[r.expenseNature || "UNCLASSIFIED"]}</Badge></div><div className="flex gap-2"><Button onClick={() => confirmRecurringMutation.mutate(r.id)}>Đã thanh toán</Button><Button variant="outline" onClick={() => archiveRecurringMutation.mutate(r.id)}>Ngừng</Button></div></div>)}
        </CardContent></Card></TabsContent>

        <TabsContent value="settings" className="grid gap-4 lg:grid-cols-2">
          <Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Tài khoản tiền</CardTitle><Button size="sm" onClick={() => setAccountOpen(true)}><Plus className="size-4"/> Thêm</Button></div></CardHeader><CardContent className="space-y-2">{accounts.data?.map((a) => <div key={a.id} className="flex items-center justify-between rounded-xl border p-3"><div><strong>{a.name}</strong><p className="text-xs text-muted-foreground">{accountTypeLabel(a.accountType)} · số dư đầu {money.format(a.openingBalance)}</p></div>{a.active && <Button size="icon-sm" variant="ghost" onClick={() => archiveAccountMutation.mutate(a.id)}><Trash2 className="size-4"/></Button>}</div>)}</CardContent></Card>
          <Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Danh mục cá nhân</CardTitle><Button size="sm" onClick={() => setCategoryOpen(true)}><Plus className="size-4"/> Thêm</Button></div></CardHeader><CardContent className="space-y-2">{categories.data?.filter((c) => c.active).map((c) => <div key={c.id} className="flex items-center justify-between rounded-xl border p-3"><div><strong>{c.name}</strong><p className="text-xs text-muted-foreground">{c.transactionKind === "INCOME" ? "Thu nhập" : natureLabels[c.expenseNature || "UNCLASSIFIED"]}</p></div>{!c.systemCategory && <Button size="icon-sm" variant="ghost" onClick={() => archiveCategoryMutation.mutate(c.id)}><Trash2 className="size-4"/></Button>}</div>)}</CardContent></Card>
        </TabsContent>
      </Tabs>

      <TransactionDialog open={transactionOpen} onOpenChange={setTransactionOpen} accounts={accounts.data ?? []} categories={categories.data ?? []} onSaved={refresh}/>
      <AccountDialog open={accountOpen} onOpenChange={setAccountOpen} onSaved={refresh}/>
      <CategoryDialog open={categoryOpen} onOpenChange={setCategoryOpen} onSaved={refresh}/>
      <BudgetDialog open={budgetOpen} onOpenChange={setBudgetOpen} month={monthValue} categories={categories.data ?? []} onSaved={refresh}/>
      <RecurringDialog open={recurringOpen} onOpenChange={setRecurringOpen} accounts={accounts.data ?? []} categories={categories.data ?? []} onSaved={refresh}/>
    </div>
  );

}

function TransactionDialog({ open, onOpenChange, accounts, categories, onSaved }: any) {
  const [form, setForm] = useState({ type: "EXPENSE", amount: "", accountId: "", destinationAccountId: "", categoryId: "", expenseNature: "ESSENTIAL_VARIABLE", occurredAt: localDateTime(), merchant: "", note: "" });
  const mutation = useMutation({ mutationFn: () => createFinanceTransaction({ ...form, amount: Number(form.amount), destinationAccountId: form.type === "TRANSFER" ? form.destinationAccountId : null, categoryId: form.type === "TRANSFER" ? null : form.categoryId, occurredAt: form.occurredAt }), onSuccess: () => { toast.success("Đã ghi giao dịch"); onOpenChange(false); setForm({ ...form, amount: "", merchant: "", note: "" }); onSaved(); }, onError: () => toast.error("Không thể ghi giao dịch. Kiểm tra tài khoản và danh mục.") });
  const choices = categories.filter((c: any) => c.active && c.transactionKind === form.type);
  return <Dialog open={open} onOpenChange={onOpenChange}><DialogContent className="sm:max-w-2xl"><DialogHeader><DialogTitle>Ghi giao dịch nhanh</DialogTitle><DialogDescription>Số tiền luôn là số dương; chọn đúng loại để báo cáo không bị sai.</DialogDescription></DialogHeader><form id="finance-transaction" className="grid gap-4 sm:grid-cols-2" onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }}>
    <Field label="Số tiền (VND)" required className="sm:col-span-2"><Input autoFocus inputMode="numeric" min="1" type="number" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })}/></Field>
    <Field label="Loại giao dịch" required><select className="field" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value, categoryId: "", destinationAccountId: "" })}><option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option><option value="TRANSFER">Chuyển giữa tài khoản</option></select></Field>
    <Field label="Tài khoản nguồn / nhận thu nhập" required><select className="field" value={form.accountId} onChange={(e) => setForm({ ...form, accountId: e.target.value })}><option value="">Chọn tài khoản</option>{accounts.filter((a: any) => a.active).map((a: any) => <option key={a.id} value={a.id}>{a.name} · {money.format(a.currentBalance)}</option>)}</select></Field>
    {form.type === "TRANSFER" ? <Field label="Tài khoản nhận" required><select className="field" value={form.destinationAccountId} onChange={(e) => setForm({ ...form, destinationAccountId: e.target.value })}><option value="">Chọn tài khoản khác</option>{accounts.filter((a: any) => a.active && a.id !== form.accountId).map((a: any) => <option key={a.id} value={a.id}>{a.name}</option>)}</select></Field> : <Field label="Danh mục" required><select className="field" value={form.categoryId} onChange={(e) => { const selected = choices.find((c: any) => c.id === e.target.value); setForm({ ...form, categoryId: e.target.value, expenseNature: selected?.expenseNature || form.expenseNature }); }}><option value="">Chọn danh mục</option>{choices.map((c: any) => <option key={c.id} value={c.id}>{c.name}{c.expenseNature ? ` · ${natureLabels[c.expenseNature]}` : ""}</option>)}</select></Field>}
    {form.type === "EXPENSE" && <Field label="Tính chất khoản chi" required><select className="field" value={form.expenseNature} onChange={(e) => setForm({ ...form, expenseNature: e.target.value })}>{Object.entries(natureLabels).filter(([key]) => key !== "UNCLASSIFIED").map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></Field>}
    <Field label="Thời điểm" required><Input type="datetime-local" value={form.occurredAt} onChange={(e) => setForm({ ...form, occurredAt: e.target.value })}/></Field>
    <Field label="Nơi chi / nguồn thu"><Input placeholder="Ví dụ: siêu thị, công ty..." value={form.merchant} onChange={(e) => setForm({ ...form, merchant: e.target.value })}/></Field>
    <Field label="Ghi chú"><Input placeholder="Thông tin giúp bạn nhớ giao dịch" value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })}/></Field>
  </form><DialogFooter><Button variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button><Button form="finance-transaction" type="submit" disabled={mutation.isPending || !form.amount || !form.accountId || (form.type === "TRANSFER" ? !form.destinationAccountId : !form.categoryId)}>{mutation.isPending ? "Đang lưu..." : "Lưu giao dịch"}</Button></DialogFooter></DialogContent></Dialog>;
}

function AccountDialog({ open, onOpenChange, onSaved }: any) { const [name,setName]=useState(""); const [type,setType]=useState("BANK"); const [balance,setBalance]=useState("0"); const m=useMutation({mutationFn:()=>createFinanceAccount({name,accountType:type,currencyCode:"VND",openingBalance:Number(balance)}),onSuccess:()=>{toast.success("Đã thêm tài khoản");onOpenChange(false);setName("");onSaved();},onError:()=>toast.error("Không thể thêm tài khoản")}); return <SimpleDialog open={open} onOpenChange={onOpenChange} title="Thêm tài khoản tiền" description="Số dư đầu chỉ là điểm bắt đầu, không được tính là thu nhập." submit="Tạo tài khoản" pending={m.isPending} disabled={!name} onSubmit={()=>m.mutate()}><Field label="Tên tài khoản" required><Input value={name} onChange={e=>setName(e.target.value)} placeholder="Ví dụ: MB Bank"/></Field><Field label="Loại tài khoản" required><select className="field" value={type} onChange={e=>setType(e.target.value)}><option value="CASH">Tiền mặt</option><option value="BANK">Ngân hàng</option><option value="EWALLET">Ví điện tử</option><option value="SAVINGS">Tiết kiệm</option><option value="OTHER">Khác</option></select></Field><Field label="Số dư ban đầu (VND)" required><Input type="number" value={balance} onChange={e=>setBalance(e.target.value)}/></Field></SimpleDialog>; }

function CategoryDialog({ open,onOpenChange,onSaved }:any){const[name,setName]=useState("");const[kind,setKind]=useState("EXPENSE");const[nature,setNature]=useState<ExpenseNature>("ESSENTIAL_VARIABLE");const m=useMutation({mutationFn:()=>createFinanceCategory({name,transactionKind:kind,expenseNature:kind==="EXPENSE"?nature:null}),onSuccess:()=>{toast.success("Đã thêm danh mục");onOpenChange(false);setName("");onSaved();},onError:()=>toast.error("Không thể thêm danh mục")});return <SimpleDialog open={open} onOpenChange={onOpenChange} title="Thêm danh mục" description="Danh mục cho biết tiền đi đâu; tính chất cho biết khoản chi quan trọng đến mức nào." submit="Tạo danh mục" pending={m.isPending} disabled={!name} onSubmit={()=>m.mutate()}><Field label="Tên danh mục" required><Input value={name} onChange={e=>setName(e.target.value)} placeholder="Ví dụ: Cà phê"/></Field><Field label="Loại"><select className="field" value={kind} onChange={e=>setKind(e.target.value)}><option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option></select></Field>{kind==="EXPENSE"&&<Field label="Tính chất khoản chi"><select className="field" value={nature} onChange={e=>setNature(e.target.value as ExpenseNature)}>{Object.entries(natureLabels).filter(([k])=>k!=="UNCLASSIFIED").map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></Field>}</SimpleDialog>}

function BudgetDialog({open,onOpenChange,month,categories,onSaved}:any){const[categoryId,setCategoryId]=useState("");const[amount,setAmount]=useState("");const m=useMutation({mutationFn:()=>saveFinanceBudget({categoryId,month,amount:Number(amount),rolloverEnabled:false}),onSuccess:()=>{toast.success("Đã lưu ngân sách");onOpenChange(false);setAmount("");onSaved();},onError:()=>toast.error("Không thể lưu ngân sách")});return <SimpleDialog open={open} onOpenChange={onOpenChange} title="Đặt ngân sách tháng" description="FitTrack cảnh báo một lần ở mức 80% và 100%, đồng thời dự báo khả năng vượt." submit="Lưu ngân sách" pending={m.isPending} disabled={!categoryId||!amount} onSubmit={()=>m.mutate()}><Field label="Danh mục chi tiêu"><select className="field" value={categoryId} onChange={e=>setCategoryId(e.target.value)}><option value="">Chọn danh mục</option>{categories.filter((c:any)=>c.active&&c.transactionKind==="EXPENSE").map((c:any)=><option key={c.id} value={c.id}>{c.name}</option>)}</select></Field><Field label="Số tiền tối đa (VND)"><Input type="number" min="1" value={amount} onChange={e=>setAmount(e.target.value)}/></Field></SimpleDialog>}

function RecurringDialog({open,onOpenChange,accounts,categories,onSaved}:any){const[form,setForm]=useState({name:"",transactionType:"EXPENSE",accountId:"",destinationAccountId:"",categoryId:"",expenseNature:"FIXED_MANDATORY",amount:"",frequency:"MONTHLY",nextDueDate:new Date().toISOString().slice(0,10),remindDaysBefore:"1"});const m=useMutation({mutationFn:()=>createFinanceRecurring({...form,amount:Number(form.amount),remindDaysBefore:Number(form.remindDaysBefore),destinationAccountId:form.transactionType==="TRANSFER"?form.destinationAccountId:null,categoryId:form.transactionType==="TRANSFER"?null:form.categoryId,expenseNature:form.transactionType==="EXPENSE"?form.expenseNature:null}),onSuccess:()=>{toast.success("Đã tạo khoản định kỳ");onOpenChange(false);onSaved();},onError:()=>toast.error("Không thể tạo khoản định kỳ")});const cs=categories.filter((c:any)=>c.active&&c.transactionKind===form.transactionType);return <SimpleDialog open={open} onOpenChange={onOpenChange} title="Thêm khoản định kỳ" description="FitTrack chỉ nhắc; giao dịch thật chỉ được tạo khi bạn xác nhận đã thanh toán/đã nhận." submit="Tạo khoản định kỳ" pending={m.isPending} disabled={!form.name||!form.amount||!form.accountId||(form.transactionType==="TRANSFER"?!form.destinationAccountId:!form.categoryId)} onSubmit={()=>m.mutate()}><div className="grid gap-4 sm:grid-cols-2"><Field label="Tên khoản" required><Input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} placeholder="Ví dụ: Tiền nhà"/></Field><Field label="Số tiền" required><Input type="number" value={form.amount} onChange={e=>setForm({...form,amount:e.target.value})}/></Field><Field label="Loại"><select className="field" value={form.transactionType} onChange={e=>setForm({...form,transactionType:e.target.value,categoryId:"",destinationAccountId:""})}><option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option><option value="TRANSFER">Chuyển khoản</option></select></Field><Field label="Tài khoản"><select className="field" value={form.accountId} onChange={e=>setForm({...form,accountId:e.target.value})}><option value="">Chọn tài khoản</option>{accounts.filter((a:any)=>a.active).map((a:any)=><option key={a.id} value={a.id}>{a.name}</option>)}</select></Field>{form.transactionType==="TRANSFER"?<Field label="Tài khoản nhận"><select className="field" value={form.destinationAccountId} onChange={e=>setForm({...form,destinationAccountId:e.target.value})}><option value="">Chọn tài khoản</option>{accounts.filter((a:any)=>a.active&&a.id!==form.accountId).map((a:any)=><option key={a.id} value={a.id}>{a.name}</option>)}</select></Field>:<Field label="Danh mục"><select className="field" value={form.categoryId} onChange={e=>setForm({...form,categoryId:e.target.value})}><option value="">Chọn danh mục</option>{cs.map((c:any)=><option key={c.id} value={c.id}>{c.name}</option>)}</select></Field>}<Field label="Chu kỳ"><select className="field" value={form.frequency} onChange={e=>setForm({...form,frequency:e.target.value})}><option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option></select></Field><Field label="Ngày đến hạn kế tiếp"><Input type="date" value={form.nextDueDate} onChange={e=>setForm({...form,nextDueDate:e.target.value})}/></Field><Field label="Nhắc trước (ngày)"><Input type="number" min="0" max="30" value={form.remindDaysBefore} onChange={e=>setForm({...form,remindDaysBefore:e.target.value})}/></Field></div></SimpleDialog>}

function SimpleDialog({open,onOpenChange,title,description,submit,pending,disabled,onSubmit,children}:any){return <Dialog open={open} onOpenChange={onOpenChange}><DialogContent className="sm:max-w-xl"><DialogHeader><DialogTitle>{title}</DialogTitle><DialogDescription>{description}</DialogDescription></DialogHeader><form id={`form-${title}`} className="space-y-4" onSubmit={e=>{e.preventDefault();onSubmit();}}>{children}</form><DialogFooter><Button variant="outline" onClick={()=>onOpenChange(false)}>Hủy</Button><Button type="submit" form={`form-${title}`} disabled={pending||disabled}>{pending?"Đang lưu...":submit}</Button></DialogFooter></DialogContent></Dialog>}
function Field({label,required,children,className=""}:any){return <div className={`space-y-2 ${className}`}><Label>{label}{required&&<span className="text-rose-600"> *</span>}</Label>{children}</div>}
function Metric({title,value,detail,icon:Icon,tone}:any){return <Card className="border-0 shadow-sm"><CardContent className="p-5"><div className="flex items-start justify-between"><div><p className="text-sm text-muted-foreground">{title}</p><p className="mt-2 text-2xl font-bold tracking-tight">{money.format(value)}</p>{detail&&<p className="mt-1 text-xs text-muted-foreground">{detail}</p>}</div><span className={`grid size-10 place-items-center rounded-xl ${tone}`}><Icon className="size-5"/></span></div></CardContent></Card>}
function ReportLine({label,value,signed=false}:any){return <div className="flex justify-between rounded-xl bg-muted/35 p-3"><span>{label}</span><strong>{signed&&value>0?"+":""}{money.format(value)}</strong></div>}
function Empty({text}:{text:string}){return <div className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">{text}</div>}
function accountTypeLabel(v:string){return ({CASH:"Tiền mặt",BANK:"Ngân hàng",EWALLET:"Ví điện tử",SAVINGS:"Tiết kiệm",OTHER:"Khác"} as Record<string,string>)[v]||v}
function frequencyLabel(v:string){return ({WEEKLY:"Hàng tuần",MONTHLY:"Hàng tháng",YEARLY:"Hàng năm"} as Record<string,string>)[v]||v}
function endOfMonth(value:string){const[y,m]=value.split("-").map(Number);return new Date(y,m,0).toISOString().slice(0,10)}

// Hooks used by the main page, kept together to guarantee one refresh path.
function useFinanceAction(fn:(id:string)=>Promise<unknown>,success:string){const qc=useQueryClient();return useMutation({mutationFn:fn,onSuccess:()=>{toast.success(success);qc.invalidateQueries({predicate:(query)=>String(query.queryKey[0]).startsWith("finance-")});},onError:()=>toast.error("Không thể hoàn tất thao tác")});}
