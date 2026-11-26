import type { UseQueryResult } from "@tanstack/react-query";
import { ArrowDownLeft, ArrowUpRight, Wallet } from "lucide-react";

import type { LunchWalletTransaction } from "@/api/lunch.api";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency, formatDateTime, getApiErrorMessage } from "@/lib/format";
import { EmptySection, ListSkeleton, QueryError, SectionHeading } from "./lunch-ui";
import { getTransactionLabel } from "./lunch-utils";

function TransactionRow({ transaction }: { transaction: LunchWalletTransaction }) {
  const positive = transaction.amount >= 0;
  return (
    <div className="flex items-start gap-3 px-3 py-3.5 sm:px-4">
      <div className={positive ? "rounded-full bg-emerald-100 p-2 text-emerald-700" : "rounded-full bg-orange-100 p-2 text-orange-700"}>
        {positive ? <ArrowDownLeft className="h-4 w-4" aria-hidden="true" /> : <ArrowUpRight className="h-4 w-4" aria-hidden="true" />}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <p className="font-medium">{getTransactionLabel(transaction.type)}</p>
          <p className={positive ? "font-bold text-emerald-700" : "font-bold text-orange-700"}>
            {positive ? "+" : ""}
            {formatCurrency(transaction.amount)}
          </p>
        </div>
        {transaction.note && <p className="mt-0.5 text-xs text-muted-foreground">{transaction.note}</p>}
        <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-muted-foreground">
          <span>{formatDateTime(transaction.createdAt)}</span>
          {transaction.balanceAfter != null && (
            <span>Số dư sau giao dịch: {formatCurrency(transaction.balanceAfter)}</span>
          )}
        </div>
      </div>
    </div>
  );
}

/** Tab "Sổ quỹ": số dư ròng và các giao dịch quỹ cơm. */
export default function LunchWalletTab({
  walletBalance,
  transactionsQuery,
}: {
  walletBalance: number;
  transactionsQuery: UseQueryResult<LunchWalletTransaction[]>;
}) {
  const transactions = transactionsQuery.data ?? [];
  return (
    <>
      <SectionHeading icon={Wallet} title="Sổ quỹ cơm" />

      <Card className="border-emerald-200 bg-emerald-50/60">
        <CardContent className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm text-emerald-800">Số dư ròng</p>
            <p className={`mt-1 text-2xl font-bold sm:text-3xl ${walletBalance < 0 ? "text-red-700" : "text-emerald-950"}`}>
              {formatCurrency(walletBalance)}
            </p>
          </div>
          <div className="rounded-full bg-white p-3 text-emerald-700 shadow-sm">
            <Wallet className="h-6 w-6" aria-hidden="true" />
          </div>
        </CardContent>
      </Card>

      {transactionsQuery.isLoading ? (
        <ListSkeleton />
      ) : transactionsQuery.isError ? (
        <QueryError
          title="Không tải được sổ quỹ"
          message={getApiErrorMessage(transactionsQuery.error, "Vui lòng thử lại.")}
          onRetry={() => void transactionsQuery.refetch()}
        />
      ) : transactions.length === 0 ? (
        <EmptySection icon={Wallet} title="Chưa có giao dịch" description="Admin sẽ ghi nhận tại đây khi bạn nạp quỹ." />
      ) : (
        <Card>
          <CardContent className="divide-y p-0">
            {transactions.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} />)}
          </CardContent>
        </Card>
      )}
    </>
  );
}
