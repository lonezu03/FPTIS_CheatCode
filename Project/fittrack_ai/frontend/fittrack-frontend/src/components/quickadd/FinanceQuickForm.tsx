import { useState, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { createFinanceTransaction, getFinanceAccounts, getFinanceCategories, type FinanceCategory } from "@/api/finance.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { formatCurrency, toLocalDateTimeInput } from "@/lib/format";
import QuickField from "./QuickField";
import { invalidProps, selectClass } from "./quick-field-styles";
import { hasErrors, parseMoney, validateFinance, type FieldErrors } from "./quick-add-validation";
import { useQuickAddFeedback } from "./use-quick-add-feedback";

type Kind = "EXPENSE" | "INCOME";

function categoryLabel(category: FinanceCategory, all: FinanceCategory[]) {
  const parent = category.parentId ? all.find((item) => item.id === category.parentId) : undefined;
  return parent ? `${parent.name} › ${category.name}` : category.name;
}

export default function FinanceQuickForm({ onDone }: { onDone: () => void }) {
  const [kind, setKind] = useState<Kind>("EXPENSE");
  const [amount, setAmount] = useState("");
  const [accountChoice, setAccountChoice] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [note, setNote] = useState("");
  const [errors, setErrors] = useState<FieldErrors<"amount" | "accountId" | "categoryId" | "note">>({});
  const { succeed, fail } = useQuickAddFeedback();

  const accounts = useQuery({ queryKey: ["finance-accounts"], queryFn: getFinanceAccounts });
  const categories = useQuery({ queryKey: ["finance-categories"], queryFn: getFinanceCategories });
  const activeAccounts = (accounts.data ?? []).filter((account) => account.active);
  // A single wallet is preselected so the common case needs no choice.
  const accountId = accountChoice || (activeAccounts.length === 1 ? activeAccounts[0].id : "");
  const allCategories = categories.data ?? [];
  const kindCategories = allCategories.filter((category) => category.active && category.transactionKind === kind)
    .sort((a, b) => categoryLabel(a, allCategories).localeCompare(categoryLabel(b, allCategories), "vi"));

  const parsedAmount = parseMoney(amount);
  const mutation = useMutation({
    mutationFn: () => createFinanceTransaction({
      type: kind,
      amount: parsedAmount!,
      accountId,
      destinationAccountId: null,
      categoryId,
      expenseNature: null,
      occurredAt: `${toLocalDateTimeInput()}:00`,
      merchant: "",
      note: note.trim(),
    }),
    onSuccess: (transaction) => {
      succeed(
        `Đã ghi ${kind === "EXPENSE" ? "khoản chi" : "khoản thu"} ${formatCurrency(transaction.amount)}`,
        "/finance",
        [["dashboard-today"]],
        (key) => String(key[0]).startsWith("finance-"),
      );
      onDone();
    },
    onError: (error) => fail(error, "Không ghi được giao dịch"),
  });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const next = validateFinance({ amount, accountId, categoryId, note });
    setErrors(next);
    if (!hasErrors(next)) mutation.mutate();
  };

  if (accounts.isLoading || categories.isLoading) {
    return <div className="grid gap-3" aria-busy="true"><Skeleton className="h-10" /><Skeleton className="h-10" /><Skeleton className="h-10" /></div>;
  }
  if (accounts.isError || categories.isError) {
    return (
      <div role="alert" className="grid gap-3 text-sm">
        <p>Không tải được tài khoản hoặc danh mục.</p>
        <Button variant="outline" onClick={() => { void accounts.refetch(); void categories.refetch(); }}>Thử lại</Button>
      </div>
    );
  }
  if (activeAccounts.length === 0) {
    return (
      <div className="grid gap-3 text-sm">
        <p>Bạn chưa có ví hoặc tài khoản nào để ghi thu chi.</p>
        <Button asChild variant="outline"><Link to="/finance" onClick={onDone}>Tạo tài khoản</Link></Button>
      </div>
    );
  }

  return (
    <form className="grid gap-4" onSubmit={submit} noValidate>
      <div className="grid grid-cols-2 gap-2" role="group" aria-label="Loại giao dịch">
        {(["EXPENSE", "INCOME"] as const).map((value) => (
          <Button key={value} type="button" variant={kind === value ? "default" : "outline"} aria-pressed={kind === value}
            onClick={() => { setKind(value); setCategoryId(""); }}>
            {value === "EXPENSE" ? "Khoản chi" : "Khoản thu"}
          </Button>
        ))}
      </div>
      <QuickField id="qa-fin-amount" label="Số tiền (đ)" error={errors.amount}
        hint={parsedAmount && Number.isFinite(parsedAmount) ? formatCurrency(parsedAmount) : "Có thể gõ 50k hoặc 50.000"}>
        <Input id="qa-fin-amount" autoFocus inputMode="numeric" placeholder="50.000" value={amount}
          onChange={(event) => setAmount(event.target.value)} {...invalidProps("qa-fin-amount", errors.amount)} />
      </QuickField>
      <div className="grid gap-4 sm:grid-cols-2">
        <QuickField id="qa-fin-category" label="Danh mục" error={errors.categoryId}>
          <select id="qa-fin-category" className={selectClass} value={categoryId} onChange={(event) => setCategoryId(event.target.value)}
            {...invalidProps("qa-fin-category", errors.categoryId)}>
            <option value="">Chọn danh mục</option>
            {kindCategories.map((category) => <option key={category.id} value={category.id}>{categoryLabel(category, allCategories)}</option>)}
          </select>
        </QuickField>
        <QuickField id="qa-fin-account" label="Tài khoản" error={errors.accountId}>
          <select id="qa-fin-account" className={selectClass} value={accountId} onChange={(event) => setAccountChoice(event.target.value)}
            {...invalidProps("qa-fin-account", errors.accountId)}>
            <option value="">Chọn tài khoản</option>
            {activeAccounts.map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
          </select>
        </QuickField>
      </div>
      <QuickField id="qa-fin-note" label="Ghi chú" error={errors.note}>
        <Input id="qa-fin-note" maxLength={1000} placeholder="Không bắt buộc" value={note} onChange={(event) => setNote(event.target.value)}
          {...invalidProps("qa-fin-note", errors.note)} />
      </QuickField>
      <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Đang lưu..." : kind === "EXPENSE" ? "Ghi khoản chi" : "Ghi khoản thu"}</Button>
    </form>
  );
}
