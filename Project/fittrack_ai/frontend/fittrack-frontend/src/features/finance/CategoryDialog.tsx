import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";

import {
  createFinanceCategory,
  updateFinanceCategory,
  type ExpenseNature,
  type FinanceCategory,
} from "@/api/finance.api";
import { Input } from "@/components/ui/input";
import { getApiErrorMessage } from "@/lib/format";
import { Field } from "./FinanceParts";
import NatureField from "./NatureField";
import SimpleDialog from "./SimpleDialog";

export default function CategoryDialog({ initial, categories, onOpenChange, onSaved }: {
  initial: FinanceCategory | null;
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [kind, setKind] = useState<"EXPENSE" | "INCOME">(initial?.transactionKind ?? "EXPENSE");
  const [nature, setNature] = useState<ExpenseNature>(initial?.expenseNature ?? "ESSENTIAL_VARIABLE");
  const [parentId, setParentId] = useState(initial?.parentId ?? "");
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { name, transactionKind: kind, expenseNature: kind === "EXPENSE" ? nature : null, parentId: parentId || null };
      return initial ? updateFinanceCategory(initial.id, payload) : createFinanceCategory(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật danh mục" : "Đã thêm danh mục");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu danh mục.")),
  });
  // Only one level of nesting: a parent must be a top-level category of the same kind.
  const parentChoices = categories.filter((category) => category.active && category.id !== initial?.id && category.transactionKind === kind && !category.parentId);
  return (
    <SimpleDialog
      formId="finance-category"
      title={initial ? "Sửa danh mục" : "Thêm danh mục"}
      submit={initial ? "Cập nhật" : "Tạo danh mục"}
      pending={mutation.isPending}
      disabled={!name.trim()}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Tên danh mục" required><Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: Cà phê" /></Field>
      <Field label="Loại" required>
        <select className="field" value={kind} onChange={(event) => { setKind(event.target.value as "EXPENSE" | "INCOME"); setParentId(""); }}>
          <option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option>
        </select>
      </Field>
      {kind === "EXPENSE" && <NatureField value={nature} onChange={setNature} />}
      <Field label="Danh mục cha (không bắt buộc)">
        <select className="field" value={parentId} onChange={(event) => setParentId(event.target.value)}>
          <option value="">Không có</option>
          {parentChoices.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
        </select>
      </Field>
    </SimpleDialog>
  );
}
