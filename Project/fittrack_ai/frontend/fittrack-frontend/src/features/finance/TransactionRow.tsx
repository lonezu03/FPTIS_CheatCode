import { ArrowDownRight, ArrowLeftRight, ArrowUpRight, Copy, Pencil, Trash2 } from "lucide-react";

import type { FinanceTransaction } from "@/api/finance.api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { money, natureLabels, transactionTone } from "./finance-utils";

export default function TransactionRow({
  transaction,
  onEdit,
  onCopy,
  onVoid,
}: {
  transaction: FinanceTransaction;
  onEdit: () => void;
  /** Opens a new entry prefilled from this one, dated now. */
  onCopy?: () => void;
  onVoid: () => void;
}) {
  const isVoid = transaction.status === "VOID";
  return (
    <div className={`flex flex-col gap-2 rounded-xl border p-3 sm:flex-row sm:items-center sm:justify-between ${isVoid ? "opacity-55" : ""}`}>
      <div className="flex min-w-0 items-center gap-3">
        <span className={`grid size-9 shrink-0 place-items-center rounded-xl ${transactionTone(transaction.type)}`}>
          {transaction.type === "TRANSFER" ? <ArrowLeftRight className="size-4" /> : transaction.type === "INCOME" ? <ArrowDownRight className="size-4" /> : <ArrowUpRight className="size-4" />}
        </span>
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <p className={isVoid ? "font-semibold line-through" : "font-semibold"}>
              {transaction.categoryName || `${transaction.accountName} → ${transaction.destinationAccountName}`}
            </p>
            {isVoid && <Badge variant="outline">Đã hủy</Badge>}
            {transaction.expenseNature && <Badge variant="outline">{natureLabels[transaction.expenseNature]}</Badge>}
          </div>
          <p className="truncate text-xs text-muted-foreground">
            {new Date(transaction.occurredAt).toLocaleString("vi-VN")}
            {transaction.merchant ? ` · ${transaction.merchant}` : ""}
            {transaction.note ? ` · ${transaction.note}` : ""}
          </p>
        </div>
      </div>
      <div className="flex items-center justify-between gap-3">
        <strong className={transaction.type === "INCOME" ? "text-emerald-700" : transaction.type === "EXPENSE" ? "text-rose-700" : ""}>
          {transaction.type === "INCOME" ? "+" : transaction.type === "EXPENSE" ? "−" : ""}{money.format(transaction.amount)}
        </strong>
        {!isVoid && (
          <div className="flex gap-1">
            {onCopy && (
              <Button size="icon-sm" variant="ghost" aria-label="Sao chép giao dịch" title="Sao chép sang hôm nay" onClick={onCopy}>
                <Copy className="size-4" />
              </Button>
            )}
            <Button size="icon-sm" variant="ghost" aria-label="Sửa giao dịch" onClick={onEdit}>
              <Pencil className="size-4" />
            </Button>
            <Button size="icon-sm" variant="ghost" aria-label="Hủy giao dịch" onClick={onVoid}>
              <Trash2 className="size-4 text-rose-600" />
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
