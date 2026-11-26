import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";

import { createFinanceAccount, updateFinanceAccount, type FinanceAccount } from "@/api/finance.api";
import { Input } from "@/components/ui/input";
import { getApiErrorMessage } from "@/lib/format";
import { Field, Hint } from "./FinanceParts";
import SimpleDialog from "./SimpleDialog";

export default function AccountDialog({ initial, onOpenChange, onSaved }: {
  initial: FinanceAccount | null;
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [type, setType] = useState(initial?.accountType ?? "BANK");
  const [balance, setBalance] = useState(String(initial?.openingBalance ?? 0));
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { name, accountType: type, currencyCode: "VND", openingBalance: Number(balance) };
      return initial ? updateFinanceAccount(initial.id, payload) : createFinanceAccount(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật tài khoản" : "Đã thêm tài khoản");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu tài khoản.")),
  });
  return (
    <SimpleDialog
      formId="finance-account"
      title={initial ? "Sửa tài khoản tiền" : "Thêm tài khoản tiền"}
      description="Không tính là thu nhập."
      submit={initial ? "Cập nhật" : "Tạo tài khoản"}
      pending={mutation.isPending}
      disabled={!name.trim() || balance === ""}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Tên tài khoản" required><Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: MB Bank" /></Field>
      <Field label="Loại tài khoản" required>
        <select className="field" value={type} onChange={(event) => setType(event.target.value)}>
          <option value="CASH">Tiền mặt</option><option value="BANK">Ngân hàng</option><option value="EWALLET">Ví điện tử</option><option value="SAVINGS">Tiết kiệm</option><option value="OTHER">Khác</option>
        </select>
      </Field>
      <Field label="Số dư ban đầu (VND)" required><Input type="number" value={balance} onChange={(event) => setBalance(event.target.value)} /></Field>
      {initial && <Hint>Số tiền lúc bắt đầu theo dõi. Muốn chỉnh số dư hiện tại, dùng “Đối soát”.</Hint>}
    </SimpleDialog>
  );
}
