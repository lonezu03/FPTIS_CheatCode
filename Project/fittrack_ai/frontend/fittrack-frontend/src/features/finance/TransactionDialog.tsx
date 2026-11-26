import { useEffect, useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";

import {
  analyzeFinanceReceipt,
  createFinanceTransaction,
  updateFinanceTransaction,
  type FinanceAccount,
  type FinanceCategory,
  type FinanceTransaction,
  type FinanceTransactionInput,
} from "@/api/finance.api";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { readConvenience, writeConvenience } from "@/lib/convenience-storage";
import { getApiErrorMessage } from "@/lib/format";
import { useAuthStore } from "@/store/auth.store";
import { Field } from "./FinanceParts";
import NatureField from "./NatureField";
import {
  buildTransactionPayload,
  categoryChoices,
  hasDraftContent,
  isDateTimeValue,
  isTransactionDraft,
  isTransactionFormValid,
  money,
  natureLabels,
  sortAccountsByRecent,
  transactionFormFrom,
  transactionFormFromTemplate,
  transactionTypeLabel,
  type TransactionForm,
} from "./finance-utils";

const RECEIPT_TYPES = ["image/png", "image/jpeg", "image/webp", "image/avif", "image/gif"];
const RECEIPT_MAX_BYTES = 1_500_000;

/**
 * Create or edit a transaction; new entries keep a local draft and can be prefilled from a receipt photo.
 * `copyFrom` opens a new entry prefilled from an existing transaction with the current time.
 */
export default function TransactionDialog({
  initial,
  copyFrom = null,
  accounts,
  categories,
  recentCategoryIds,
  templates,
  onOpenChange,
  onSaved,
}: {
  initial: FinanceTransaction | null;
  copyFrom?: FinanceTransaction | null;
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  recentCategoryIds: string[];
  templates: FinanceTransaction[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const userId = useAuthStore(state => state.user?.userId);
  const [draftOwner] = useState(userId);
  // A copy never reads or overwrites the saved draft of a fresh entry.
  const draftKey = userId && draftOwner === userId && !initial && !copyFrom ? `fittrack:finance-draft:${userId}` : null;
  const [recovery, setRecovery] = useState(() => readConvenience(draftKey, isTransactionDraft));
  const saved = useRef(false);
  const [form, setForm] = useState<TransactionForm>(() => copyFrom ? transactionFormFromTemplate(copyFrom, accounts) : transactionFormFrom(initial));
  useEffect(() => { if (!recovery && !saved.current) writeConvenience(draftKey, hasDraftContent(form) ? form : null); }, [draftKey, form, recovery]);
  const [receiptWarning, setReceiptWarning] = useState<string | null>(null);
  // A receipt result is ignored when the user edited the form while it was being read.
  const formRevision = useRef(0);
  const analysisRevision = useRef(0);
  const receiptMutation = useMutation({
    mutationFn: analyzeFinanceReceipt,
    onSuccess: (draft) => {
      if (formRevision.current !== analysisRevision.current) {
        toast.info("Bạn đã sửa biểu mẫu trong lúc đọc ảnh; kết quả ảnh không được áp dụng.");
        return;
      }
      setForm((current) => ({
        ...current,
        type: "EXPENSE",
        amount: draft.amount ? String(draft.amount) : current.amount,
        occurredAt: isDateTimeValue(draft.occurredAt) ? draft.occurredAt : current.occurredAt,
        merchant: draft.merchant ?? current.merchant,
        note: draft.note ?? current.note,
        categoryId: "",
        accountId: "",
      }));
      setReceiptWarning(draft.warning ?? "Kiểm tra lại thông tin trước khi lưu.");
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể đọc ảnh hóa đơn.")),
  });
  const onReceiptSelected = (file?: File) => {
    if (!file) return;
    if (!RECEIPT_TYPES.includes(file.type)) { toast.error("Chỉ hỗ trợ ảnh PNG, JPEG, WebP, AVIF hoặc GIF."); return; }
    if (file.size > RECEIPT_MAX_BYTES) { toast.error("Ảnh phải nhỏ hơn 1,5 MB."); return; }
    analysisRevision.current = formRevision.current;
    const reader = new FileReader();
    reader.onload = () => { if (typeof reader.result === "string") receiptMutation.mutate(reader.result); };
    reader.onerror = () => toast.error("Không thể đọc file ảnh.");
    reader.readAsDataURL(file);
  };
  const mutation = useMutation({
    mutationFn: () => {
      const payload = buildTransactionPayload(form);
      return initial
        ? updateFinanceTransaction(initial.id, payload)
        : createFinanceTransaction(payload);
    },
    onSuccess: () => {
      saved.current = true;
      writeConvenience(draftKey, null);
      toast.success(initial ? "Đã cập nhật giao dịch" : "Đã ghi giao dịch");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu giao dịch.")),
  });
  const choices = categoryChoices(categories, form.type);
  const recentAccountIds = [...new Set(templates.map(template => template.accountId))];
  const accountChoices = sortAccountsByRecent(accounts, recentAccountIds);
  const recentChoices = recentCategoryIds
    .map((id) => choices.find((category) => category.id === id))
    .filter((category): category is FinanceCategory => Boolean(category));
  const valid = isTransactionFormValid(form, accounts, choices) && !recovery;

  return (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{initial ? "Sửa giao dịch" : copyFrom ? "Sao chép giao dịch" : "Ghi giao dịch nhanh"}</DialogTitle>
          <DialogDescription>Số tiền luôn là số dương; chọn đúng loại để báo cáo không bị sai.</DialogDescription>
        </DialogHeader>
        {recovery && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm">
            <p>Có giao dịch đang nhập trên thiết bị. Chưa có khoản nào được ghi nhận.</p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Button size="sm" onClick={() => { formRevision.current += 1; setForm(recovery); setRecovery(null); }}>Khôi phục bản nháp</Button>
              <Button size="sm" variant="outline" onClick={() => { writeConvenience(draftKey, null); setRecovery(null); }}>Bỏ bản nháp cũ</Button>
            </div>
          </div>
        )}
        {!initial && !copyFrom && templates.length > 0 && (
          <details className="rounded-xl border p-3">
            <summary className="cursor-pointer text-sm font-medium">Dùng lại giao dịch gần đây</summary>
            <div className="flex flex-wrap gap-2">
              {templates.map(template => (
                <Button
                  key={template.id}
                  type="button"
                  size="sm"
                  variant="outline"
                  disabled={Boolean(recovery) || receiptMutation.isPending}
                  onClick={() => { formRevision.current += 1; setForm(transactionFormFromTemplate(template, accounts)); }}
                >
                  {template.categoryName ?? transactionTypeLabel(template.type)} · {money.format(template.amount)}
                </Button>
              ))}
            </div>
          </details>
        )}
        <form id="finance-transaction" className="grid gap-4 sm:grid-cols-2" onChange={() => { formRevision.current += 1; }} onSubmit={(event) => { event.preventDefault(); if (!receiptMutation.isPending && !mutation.isPending && valid) mutation.mutate(); }}>
          {!initial && <div className="sm:col-span-2 rounded-xl border p-3 space-y-2">
            <label className="text-sm font-medium" htmlFor="finance-receipt">Chụp hoặc tải ảnh hóa đơn để điền nhanh</label>
            <input id="finance-receipt" className="block w-full text-sm" type="file" accept="image/png,image/jpeg,image/webp,image/avif,image/gif" capture="environment" disabled={receiptMutation.isPending} onChange={(event) => { onReceiptSelected(event.target.files?.[0]); event.target.value = ""; }} />
            <p className="text-xs text-muted-foreground">{receiptMutation.isPending ? "Đang đọc hóa đơn..." : receiptWarning ?? "Tạo bản nháp để bạn kiểm tra trước khi lưu."}</p>
          </div>}
          <Field label="Số tiền (VND)" required className="sm:col-span-2">
            <Input autoFocus inputMode="decimal" min="0.01" step="0.01" type="number" value={form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} />
          </Field>
          <Field label="Loại giao dịch" required>
            <select className="field" value={form.type} onChange={(event) => setForm({ ...form, type: event.target.value as FinanceTransactionInput["type"], categoryId: "", destinationAccountId: "" })}>
              <option value="EXPENSE">Chi tiêu</option>
              <option value="INCOME">Thu nhập</option>
              <option value="TRANSFER">Chuyển giữa tài khoản</option>
            </select>
          </Field>
          <Field label="Tài khoản nguồn / nhận thu nhập" required>
            <select className="field" value={form.accountId} onChange={(event) => setForm({ ...form, accountId: event.target.value, destinationAccountId: event.target.value === form.destinationAccountId ? "" : form.destinationAccountId })}>
              <option value="">Chọn tài khoản</option>
              {accountChoices.map((account) => <option key={account.id} value={account.id}>{account.name} · {money.format(account.currentBalance)}{recentAccountIds.includes(account.id) ? " · Đã dùng gần đây" : ""}</option>)}
            </select>
          </Field>
          {form.type === "TRANSFER" ? (
            <Field label="Tài khoản nhận" required>
              <select className="field" value={form.destinationAccountId} onChange={(event) => setForm({ ...form, destinationAccountId: event.target.value })}>
                <option value="">Chọn tài khoản khác</option>
                {accounts.filter((account) => account.active && account.id !== form.accountId).map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
              </select>
            </Field>
          ) : (
            <Field label="Danh mục" required>
              <select className="field" value={form.categoryId} onChange={(event) => {
                const selected = choices.find((category) => category.id === event.target.value);
                setForm({ ...form, categoryId: event.target.value, expenseNature: selected?.expenseNature ?? form.expenseNature });
              }}>
                <option value="">Chọn danh mục</option>
                {choices.map((category) => <option key={category.id} value={category.id}>{category.name}{category.expenseNature ? ` · ${natureLabels[category.expenseNature]}` : ""}</option>)}
              </select>
            </Field>
          )}
          {form.type !== "TRANSFER" && recentChoices.length > 0 && (
            <Field label="Danh mục gần đây" className="sm:col-span-2">
              <div className="flex flex-wrap gap-2">
                {recentChoices.map((category) => (
                  <Button
                    key={category.id}
                    type="button"
                    size="sm"
                    variant={form.categoryId === category.id ? "default" : "outline"}
                    onClick={() => setForm({
                      ...form,
                      categoryId: category.id,
                      expenseNature: category.expenseNature ?? form.expenseNature,
                    })}
                  >
                    {category.name}
                  </Button>
                ))}
              </div>
            </Field>
          )}
          <details className="sm:col-span-2 rounded-xl border p-3">
            <summary className="cursor-pointer text-sm font-medium">Thông tin bổ sung: tính chất chi, nơi mua, ghi chú</summary>
            <div className="mt-3 grid gap-4 sm:grid-cols-2">
              {form.type === "EXPENSE" && (
                <NatureField value={form.expenseNature} onChange={(expenseNature) => setForm({ ...form, expenseNature })} />
              )}
              <Field label="Nơi chi / nguồn thu">
                <Input placeholder="Ví dụ: siêu thị, công ty..." value={form.merchant} onChange={(event) => setForm({ ...form, merchant: event.target.value })} />
              </Field>
              <Field label="Ghi chú">
                <Input placeholder="Thông tin giúp bạn nhớ giao dịch" value={form.note} onChange={(event) => setForm({ ...form, note: event.target.value })} />
              </Field>
            </div>
          </details>
          <Field label="Thời điểm" required>
            <Input type="datetime-local" value={form.occurredAt} onChange={(event) => setForm({ ...form, occurredAt: event.target.value })} />
          </Field>
        </form>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button form="finance-transaction" type="submit" disabled={mutation.isPending || receiptMutation.isPending || !valid}>
            {mutation.isPending ? "Đang lưu..." : initial ? "Cập nhật" : "Lưu giao dịch"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
