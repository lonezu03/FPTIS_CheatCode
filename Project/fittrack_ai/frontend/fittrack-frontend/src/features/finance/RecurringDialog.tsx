import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";

import {
  createFinanceRecurring,
  updateFinanceRecurring,
  type FinanceAccount,
  type FinanceCategory,
  type FinanceRecurring,
} from "@/api/finance.api";
import { Input } from "@/components/ui/input";
import { getApiErrorMessage } from "@/lib/format";
import { Field } from "./FinanceParts";
import NatureField from "./NatureField";
import SimpleDialog from "./SimpleDialog";
import { categoryChoices, localDate } from "./finance-utils";

export default function RecurringDialog({ initial, accounts, categories, onOpenChange, onSaved }: {
  initial: FinanceRecurring | null;
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState({
    name: initial?.name ?? "",
    transactionType: initial?.transactionType ?? "EXPENSE",
    accountId: initial?.accountId ?? "",
    destinationAccountId: initial?.destinationAccountId ?? "",
    categoryId: initial?.categoryId ?? "",
    expenseNature: initial?.expenseNature ?? "FIXED_MANDATORY",
    amount: initial ? String(initial.amount) : "",
    frequency: initial?.frequency ?? "MONTHLY",
    nextDueDate: initial?.nextDueDate ?? localDate(),
    remindDaysBefore: String(initial?.remindDaysBefore ?? 1),
  });
  const mutation = useMutation({
    mutationFn: () => {
      const payload = {
        name: form.name,
        transactionType: form.transactionType,
        accountId: form.accountId,
        destinationAccountId: form.transactionType === "TRANSFER" ? form.destinationAccountId || null : null,
        categoryId: form.transactionType === "TRANSFER" ? null : form.categoryId || null,
        expenseNature: form.transactionType === "EXPENSE" ? form.expenseNature : null,
        amount: Number(form.amount),
        frequency: form.frequency,
        nextDueDate: form.nextDueDate,
        remindDaysBefore: Number(form.remindDaysBefore),
      };
      return initial ? updateFinanceRecurring(initial.id, payload) : createFinanceRecurring(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật khoản định kỳ" : "Đã tạo khoản định kỳ");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu khoản định kỳ.")),
  });
  const choices = categoryChoices(categories, form.transactionType);
  const valid = form.name.trim() && Number(form.amount) > 0 && form.accountId && form.nextDueDate
    && (form.transactionType === "TRANSFER" ? form.destinationAccountId : form.categoryId);

  return (
    <SimpleDialog
      formId="finance-recurring"
      title={initial ? "Sửa khoản định kỳ" : "Thêm khoản định kỳ"}
      description="Chỉ ghi giao dịch khi bạn xác nhận."
      submit={initial ? "Cập nhật" : "Tạo khoản định kỳ"}
      pending={mutation.isPending}
      disabled={!valid}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
      wide
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Tên khoản" required><Input value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} placeholder="Ví dụ: Tiền nhà" /></Field>
        <Field label="Số tiền (VND)" required><Input type="number" min="1" value={form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} /></Field>
        <Field label="Loại" required>
          <select className="field" value={form.transactionType} onChange={(event) => setForm({ ...form, transactionType: event.target.value as FinanceRecurring["transactionType"], categoryId: "", destinationAccountId: "" })}>
            <option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option><option value="TRANSFER">Chuyển khoản</option>
          </select>
        </Field>
        <Field label="Tài khoản" required>
          <select className="field" value={form.accountId} onChange={(event) => setForm({ ...form, accountId: event.target.value, destinationAccountId: event.target.value === form.destinationAccountId ? "" : form.destinationAccountId })}>
            <option value="">Chọn tài khoản</option>
            {accounts.filter((account) => account.active).map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
          </select>
        </Field>
        {form.transactionType === "TRANSFER" ? (
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
              {choices.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
            </select>
          </Field>
        )}
        {form.transactionType === "EXPENSE" && <NatureField value={form.expenseNature} onChange={(expenseNature) => setForm({ ...form, expenseNature })} />}
        <Field label="Chu kỳ" required>
          <select className="field" value={form.frequency} onChange={(event) => setForm({ ...form, frequency: event.target.value as FinanceRecurring["frequency"] })}>
            <option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option>
          </select>
        </Field>
        <Field label="Ngày đến hạn kế tiếp" required><Input type="date" value={form.nextDueDate} onChange={(event) => setForm({ ...form, nextDueDate: event.target.value })} /></Field>
        <Field label="Nhắc trước (ngày)" required><Input type="number" min="0" max="30" value={form.remindDaysBefore} onChange={(event) => setForm({ ...form, remindDaysBefore: event.target.value })} /></Field>
      </div>
    </SimpleDialog>
  );
}
