import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";

import { saveFinanceBudget, updateFinanceBudget, type FinanceBudget, type FinanceCategory } from "@/api/finance.api";
import { Input } from "@/components/ui/input";
import { getApiErrorMessage } from "@/lib/format";
import { Field } from "./FinanceParts";
import SimpleDialog from "./SimpleDialog";
import { categoryChoices } from "./finance-utils";

export default function BudgetDialog({ initial, month, categories, onOpenChange, onSaved }: {
  initial: FinanceBudget | null;
  /** First day of the selected month (yyyy-MM-01). */
  month: string;
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [categoryId, setCategoryId] = useState(initial?.categoryId ?? "");
  const [amount, setAmount] = useState(initial ? String(initial.amount) : "");
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { categoryId, month, amount: Number(amount), rolloverEnabled: false };
      return initial ? updateFinanceBudget(initial.id, payload) : saveFinanceBudget(payload);
    },
    onSuccess: () => {
      toast.success("Đã lưu ngân sách");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu ngân sách.")),
  });
  return (
    <SimpleDialog
      formId="finance-budget"
      title={initial ? "Sửa ngân sách tháng" : "Đặt ngân sách tháng"}
      description="Nhắc bạn khi chạm 80% và 100% ngân sách."
      submit="Lưu ngân sách"
      pending={mutation.isPending}
      disabled={!categoryId || Number(amount) <= 0}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Danh mục chi tiêu" required>
        <select className="field" value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
          <option value="">Chọn danh mục</option>
          {categoryChoices(categories, "EXPENSE").map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
        </select>
      </Field>
      <Field label="Số tiền tối đa (VND)" required><Input type="number" min="1" value={amount} onChange={(event) => setAmount(event.target.value)} /></Field>
    </SimpleDialog>
  );
}
