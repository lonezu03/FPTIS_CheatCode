import { Pencil, Plus, Trash2 } from "lucide-react";

import type { FinanceAccount, FinanceCategory } from "@/api/finance.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import EmptyState from "@/components/common/EmptyState";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Empty } from "./FinanceParts";
import { accountTypeLabel, money, natureLabels } from "./finance-utils";

/** "Thiết lập" tab: money accounts and personal categories. */
export default function SettingsTab({ accounts, categories, onAddAccount, onEditAccount, onReconcile, onArchiveAccount, onAddCategory, onEditCategory, onArchiveCategory }: {
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  onAddAccount: () => void;
  onEditAccount: (account: FinanceAccount) => void;
  onReconcile: (account: FinanceAccount) => void;
  onArchiveAccount: (id: string) => void;
  onAddCategory: () => void;
  onEditCategory: (category: FinanceCategory) => void;
  onArchiveCategory: (id: string) => void;
}) {
  const confirm = useConfirm();
  const activeCategories = categories.filter((item) => item.active);
  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Tài khoản tiền</CardTitle>
            <Button size="sm" onClick={onAddAccount}><Plus className="size-4" /> Thêm</Button>
          </div>
          <p className="text-sm text-muted-foreground">Số dư lệch với thực tế? Dùng “Đối soát” để chỉnh lại.</p>
        </CardHeader>
        <CardContent className="space-y-2">
          {accounts.length === 0 ? <Empty text="Chưa có tài khoản tiền." /> : accounts.map((account) => (
            <div key={account.id} className={`flex min-w-0 items-start justify-between gap-2 rounded-xl border p-3 ${account.active ? "" : "opacity-60"}`}>
              <div className="min-w-0 flex-1 break-words">
                <strong>{account.name}</strong>
                <p className="text-xs text-muted-foreground">
                  {accountTypeLabel(account.accountType)} · số dư đầu {money.format(account.openingBalance)}
                  {!account.active ? " · Đã lưu trữ" : ""}
                </p>
                <p className="mt-1 text-sm font-semibold">Hiện có: {money.format(account.currentBalance)}</p>
                <Button className="mt-2" size="sm" variant="outline" onClick={() => onReconcile(account)}>{account.active ? 'Đối soát số dư' : 'Lịch sử đối soát'}</Button>
              </div>
              {account.active && (
                <div className="flex shrink-0 gap-1">
                  <Button size="icon-sm" variant="ghost" aria-label="Sửa tài khoản" onClick={() => onEditAccount(account)}>
                    <Pencil className="size-4" />
                  </Button>
                  <Button
                    size="icon-sm"
                    variant="ghost"
                    aria-label="Lưu trữ tài khoản"
                    onClick={async () => { if (await confirm({ title: "Lưu trữ tài khoản?", description: `Tài khoản "${account.name}" sẽ được lưu trữ. Lịch sử vẫn được giữ lại.`, confirmText: "Lưu trữ" })) onArchiveAccount(account.id); }}
                  >
                    <Trash2 className="size-4 text-rose-600" />
                  </Button>
                </div>
              )}
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Danh mục cá nhân</CardTitle>
            <Button size="sm" onClick={onAddCategory}><Plus className="size-4" /> Thêm</Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {activeCategories.length === 0 && (
            <EmptyState title="Chưa có danh mục" description="Thêm danh mục để phân loại thu chi." />
          )}
          {activeCategories.map((category) => (
            <div key={category.id} className="flex min-w-0 items-start justify-between gap-2 rounded-xl border p-3">
              <div className="min-w-0 flex-1 break-words">
                <strong>{category.name}</strong>
                <p className="text-xs text-muted-foreground">
                  {category.transactionKind === "INCOME" ? "Thu nhập" : natureLabels[category.expenseNature || "UNCLASSIFIED"]}
                  {category.parentId ? ` · danh mục con của ${categories.find((item) => item.id === category.parentId)?.name ?? "khác"}` : ""}
                </p>
              </div>
              <div className="flex shrink-0 gap-1">
                <Button size="icon-sm" variant="ghost" aria-label="Sửa danh mục" onClick={() => onEditCategory(category)}>
                  <Pencil className="size-4" />
                </Button>
                {!category.systemCategory && (
                  <Button
                    size="icon-sm"
                    variant="ghost"
                    aria-label="Lưu trữ danh mục"
                    onClick={async () => { if (await confirm({ title: "Lưu trữ danh mục?", description: `Danh mục "${category.name}" sẽ được lưu trữ. Dữ liệu cũ vẫn được giữ lại.`, confirmText: "Lưu trữ" })) onArchiveCategory(category.id); }}
                  >
                    <Trash2 className="size-4 text-rose-600" />
                  </Button>
                )}
              </div>
            </div>
          ))}
        </CardContent>
      </Card>
    </>
  );
}
