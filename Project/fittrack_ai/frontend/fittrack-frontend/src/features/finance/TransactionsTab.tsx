import { useState } from "react";
import { Download, Plus } from "lucide-react";
import { toast } from "sonner";

import { getFinanceTransactions, type FinanceAccount, type FinanceCategory, type FinanceTransaction, type PageResponse } from "@/api/finance.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { collectPages, downloadCsv } from "@/lib/csv";
import { getApiErrorMessage } from "@/lib/format";
import { Empty, InlineError, ListSkeleton } from "./FinanceParts";
import TransactionDialog from "./TransactionDialog";
import TransactionRow from "./TransactionRow";
import {
  TRANSACTION_EXPORT_MAX_PAGES,
  TRANSACTION_EXPORT_PAGE_SIZE,
  endOfMonth,
  monthDate,
  recentCategoryIdsOf,
  transactionCsvColumns,
} from "./finance-utils";
import { useFinanceRefresh } from "./useFinanceQueries";
import type { FinanceViewState } from "./useFinanceView";

/** "Giao dịch" tab: filters, paged history, edit, copy, void and CSV export of the filtered month. */
export default function TransactionsTab({ view, transactions, accounts, categories, canCreate, onNew, onEdit, onVoid }: {
  view: FinanceViewState;
  transactions: { data?: PageResponse<FinanceTransaction>; isLoading: boolean; isError: boolean; error: unknown };
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  canCreate: boolean;
  onNew: () => void;
  onEdit: (transaction: FinanceTransaction) => void;
  onVoid: (id: string) => void;
}) {
  const confirm = useConfirm();
  const refresh = useFinanceRefresh();
  const { page, search, typeFilter, accountFilter, categoryFilter } = view;
  const totalPages = transactions.data?.totalPages ?? 0;
  const [copySource, setCopySource] = useState<FinanceTransaction | null>(null);
  const [exporting, setExporting] = useState(false);

  const exportCsv = async () => {
    setExporting(true);
    try {
      const { items, truncated } = await collectPages(
        (pageIndex) => getFinanceTransactions({
          from: monthDate(view.month),
          to: endOfMonth(view.month),
          page: pageIndex,
          size: TRANSACTION_EXPORT_PAGE_SIZE,
          q: search || undefined,
          type: typeFilter || undefined,
          accountId: accountFilter || undefined,
          categoryId: categoryFilter || undefined,
        }),
        { maxPages: TRANSACTION_EXPORT_MAX_PAGES },
      );
      if (!items.length) {
        toast.info("Không có giao dịch để xuất.");
        return;
      }
      downloadCsv(`giao-dich-${view.month}`, items, transactionCsvColumns);
      if (truncated) toast.warning(`Chỉ xuất ${items.length} giao dịch đầu tiên. Hãy lọc hẹp hơn để xuất phần còn lại.`);
      else toast.success(`Đã xuất ${items.length} giao dịch.`);
    } catch (error) {
      toast.error(getApiErrorMessage(error, "Không xuất được giao dịch."));
    } finally {
      setExporting(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <CardTitle>Lịch sử giao dịch</CardTitle>
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => void exportCsv()} disabled={exporting || !transactions.data?.content.length} title="Xuất các giao dịch của tháng theo bộ lọc hiện tại">
                <Download className="size-4" /> {exporting ? "Đang xuất..." : "Xuất CSV"}
              </Button>
              <Button onClick={onNew} disabled={!canCreate}>
                <Plus className="size-4" /> Ghi giao dịch
              </Button>
            </div>
          </div>
          <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
            <Input
              placeholder="Tìm nơi chi, ghi chú..."
              aria-label="Tìm giao dịch"
              value={search}
              onChange={(event) => view.changeSearch(event.target.value)}
            />
            <select
              className="field"
              aria-label="Lọc loại giao dịch"
              value={typeFilter}
              onChange={(event) => view.changeType(event.target.value)}
            >
              <option value="">Tất cả loại</option>
              <option value="EXPENSE">Chi tiêu</option>
              <option value="INCOME">Thu nhập</option>
              <option value="TRANSFER">Chuyển khoản</option>
            </select>
            <select
              className="field"
              aria-label="Lọc tài khoản"
              value={accountFilter}
              onChange={(event) => view.changeAccount(event.target.value)}
            >
              <option value="">Tất cả tài khoản</option>
              {accounts.map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
            </select>
            <select
              className="field"
              aria-label="Lọc danh mục"
              value={categoryFilter}
              disabled={typeFilter === "TRANSFER"}
              onChange={(event) => view.changeCategory(event.target.value)}
            >
              <option value="">Tất cả danh mục</option>
              {categories
                .filter((category) => !typeFilter || category.transactionKind === typeFilter)
                .map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
            </select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {transactions.isError ? (
          <InlineError error={transactions.error} fallback="Không tải được lịch sử giao dịch." />
        ) : transactions.isLoading ? (
          <ListSkeleton rows={5} />
        ) : !transactions.data?.content.length ? (
          <Empty text="Không có giao dịch phù hợp." />
        ) : (
          <div className="space-y-2">
            {transactions.data.content.map((transaction) => (
              <TransactionRow
                key={transaction.id}
                transaction={transaction}
                onEdit={() => onEdit(transaction)}
                onCopy={canCreate ? () => setCopySource(transaction) : undefined}
                onVoid={async () => {
                  const ok = await confirm({
                    title: "Hủy giao dịch?",
                    description: "Giao dịch chuyển sang Đã hủy: vẫn lưu để đối soát nhưng không tính vào số dư và báo cáo.",
                    confirmText: "Hủy giao dịch",
                    cancelText: "Giữ lại",
                    destructive: true,
                  });
                  if (ok) {
                    onVoid(transaction.id);
                  }
                }}
              />
            ))}
          </div>
        )}
        {totalPages > 1 && (
          <div className="mt-4 flex items-center justify-end gap-2">
            <Button variant="outline" disabled={page === 0} onClick={() => view.setPage((value) => value - 1)}>
              Trước
            </Button>
            <span className="text-sm">Trang {page + 1}/{transactions.data?.totalPages}</span>
            <Button variant="outline" disabled={transactions.data?.last} onClick={() => view.setPage((value) => value + 1)}>
              Sau
            </Button>
          </div>
        )}
      </CardContent>
      {copySource && (
        <TransactionDialog
          key={copySource.id}
          initial={null}
          copyFrom={copySource}
          accounts={accounts}
          categories={categories}
          recentCategoryIds={recentCategoryIdsOf(transactions.data?.content ?? [])}
          templates={[]}
          onOpenChange={(open) => { if (!open) setCopySource(null); }}
          onSaved={refresh}
        />
      )}
    </Card>
  );
}
