import { useState } from "react";
import { ClipboardList, CreditCard, RefreshCw, UtensilsCrossed, Wallet } from "lucide-react";
import { toast } from "sonner";
import { useSearchParams } from "react-router-dom";

import type { LunchMenu, LunchOrder } from "@/api/lunch.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import PageHeader from "@/components/PageHeader";
import AdminMenuItemEditor from "@/components/lunch/AdminMenuItemEditor";
import AdminPaymentPanel from "@/components/lunch/AdminPaymentPanel";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import ActiveMenuPanel from "@/features/admin-lunch/ActiveMenuPanel";
import { ConfirmPaymentDialog, DeleteMenuDialog, MenuStatusDialog } from "@/features/admin-lunch/AdminLunchDialogs";
import { AdminQueryError } from "@/features/admin-lunch/AdminLunchParts";
import FundsTab from "@/features/admin-lunch/FundsTab";
import MenuEditorCard from "@/features/admin-lunch/MenuEditorCard";
import MenuPreviewCard from "@/features/admin-lunch/MenuPreviewCard";
import MenuRangeFilter from "@/features/admin-lunch/MenuRangeFilter";
import OrdersTab from "@/features/admin-lunch/OrdersTab";
import {
  resolveAdminLunchTab,
  tabSearchParams,
  validateMenuPayload,
  type MenuAction,
} from "@/features/admin-lunch/admin-lunch-utils";
import { useAdminLunchData, useAdminLunchSelection } from "@/features/admin-lunch/useAdminLunchData";
import { useAdminLunchMutations } from "@/features/admin-lunch/useAdminLunchMutations";
import { useFundAdjustment } from "@/features/admin-lunch/useFundAdjustment";
import { useMenuEditor } from "@/features/admin-lunch/useMenuEditor";

export default function AdminLunchPage() {
  const confirm = useConfirm();
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = resolveAdminLunchTab(searchParams.get("tab"));

  const selection = useAdminLunchSelection();
  const editor = useMenuEditor();
  const fund = useFundAdjustment();
  const [menuAction, setMenuAction] = useState<MenuAction | null>(null);
  const [deleteMenuTarget, setDeleteMenuTarget] = useState<LunchMenu | null>(null);
  const [confirmPaymentTarget, setConfirmPaymentTarget] = useState<LunchOrder | null>(null);

  const { menusQuery, ordersQuery, membersQuery, menus, activeMenu, orders, members, displayedSummary } = useAdminLunchData(selection);
  const mutations = useAdminLunchMutations({
    selection,
    editor,
    activeMenu,
    deleteMenuTarget,
    setMenuAction,
    setDeleteMenuTarget,
    setConfirmPaymentTarget,
  });

  function handleSaveMenu() {
    const payload = editor.payload();
    const error = validateMenuPayload(payload, editor.parsedMenu.isValid);
    if (error) {
      toast.error(error);
      return;
    }
    if (editor.editingMenuId) {
      mutations.updateMenuMutation.mutate({ menuId: editor.editingMenuId, payload });
      return;
    }
    mutations.importMutation.mutate(payload);
  }

  async function notifyActiveMenu() {
    if (!activeMenu) return;
    const ok = await confirm({
      title: "Gửi thông báo menu?",
      description: `Menu ${activeMenu.vendorName} ngày ${activeMenu.menuDate} sẽ được gửi qua thông báo trong ứng dụng và email tới toàn bộ tài khoản đang hoạt động.`,
      confirmText: "Gửi",
    });
    if (ok) {
      mutations.notifyMenuMutation.mutate(activeMenu.id);
    }
  }

  async function copySummary(orderText: string) {
    try {
      await navigator.clipboard.writeText(orderText);
      toast.success("Đã sao chép nội dung gửi quán.");
    } catch {
      toast.error("Không thể sao chép tự động. Hãy chọn nội dung và sao chép thủ công.");
    }
  }

  const refreshing = menusQuery.isFetching || ordersQuery.isFetching;

  return (
    <div className="space-y-4 md:space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader title="Điều phối cơm" />
        <Button
          type="button"
          variant="outline"
          onClick={() => {
            void menusQuery.refetch();
            if (activeMenu) {
              void ordersQuery.refetch();
            }
          }}
          disabled={refreshing}
          className="self-start sm:self-auto"
        >
          <RefreshCw className={refreshing ? "animate-spin" : ""} aria-hidden="true" />
          Làm mới
        </Button>
      </div>

      <MenuRangeFilter selection={selection} menus={menus} activeMenu={activeMenu} loading={menusQuery.isLoading} />

      {menusQuery.isError && (
        <AdminQueryError
          title="Không tải được danh sách menu"
          error={menusQuery.error}
          onRetry={() => void menusQuery.refetch()}
        />
      )}

      <Tabs
        value={activeTab}
        onValueChange={(tab) => setSearchParams(tabSearchParams(tab))}
        className="gap-4"
      >
        <TabsList className="grid h-auto w-full grid-cols-4 sm:w-fit">
          <TabsTrigger value="menu" className="min-h-9 px-3">
            <UtensilsCrossed aria-hidden="true" />
            Menu & tổng hợp
          </TabsTrigger>
          <TabsTrigger value="orders" className="min-h-9 px-3">
            <ClipboardList aria-hidden="true" />
            Đơn hôm nay
          </TabsTrigger>
          <TabsTrigger value="funds" className="min-h-9 px-3">
            <Wallet aria-hidden="true" />
            Quỹ & công nợ
          </TabsTrigger>
          <TabsTrigger value="payments" className="min-h-9 px-3">
            <CreditCard aria-hidden="true" />
            Thanh toán QR
          </TabsTrigger>
        </TabsList>

        <TabsContent value="menu" className="space-y-4 md:space-y-6">
          <div className="grid gap-4 xl:grid-cols-[minmax(0,1.15fr)_minmax(340px,0.85fr)] xl:gap-6">
            <MenuEditorCard editor={editor} saving={mutations.isSavingMenu} onSubmit={handleSaveMenu} />
            <MenuPreviewCard parsedMenu={editor.parsedMenu} />
          </div>

          <ActiveMenuPanel
            menu={activeMenu}
            summary={displayedSummary}
            loading={menusQuery.isLoading}
            summarizing={mutations.summaryMutation.isPending}
            changingStatus={mutations.menuActionMutation.isPending}
            notifying={mutations.notifyMenuMutation.isPending}
            deleting={mutations.deleteMenuMutation.isPending}
            onSummarize={() => activeMenu && mutations.summaryMutation.mutate(activeMenu.id)}
            onClose={() => activeMenu && setMenuAction({ menu: activeMenu, action: "close" })}
            onReopen={() => activeMenu && setMenuAction({ menu: activeMenu, action: "reopen" })}
            onEdit={() => {
              if (!activeMenu) return;
              editor.startEditing(activeMenu);
              selection.setSummaryResult(null);
            }}
            onDelete={() => activeMenu && setDeleteMenuTarget(activeMenu)}
            onNotify={notifyActiveMenu}
            onCopy={copySummary}
          />
          {activeMenu && <AdminMenuItemEditor menu={activeMenu} />}
        </TabsContent>

        <TabsContent value="orders" className="space-y-4">
          <OrdersTab
            menu={activeMenu}
            menusLoading={menusQuery.isLoading}
            ordersQuery={ordersQuery}
            orders={orders}
            confirming={mutations.confirmPaymentMutation.isPending}
            onConfirmExternal={setConfirmPaymentTarget}
          />
        </TabsContent>

        <TabsContent value="funds" className="space-y-4 md:space-y-6">
          <FundsTab fund={fund} membersQuery={membersQuery} members={members} />
        </TabsContent>

        <TabsContent value="payments" className="space-y-4 md:space-y-6">
          <AdminPaymentPanel />
        </TabsContent>
      </Tabs>

      <MenuStatusDialog
        target={menuAction}
        pending={mutations.menuActionMutation.isPending}
        onCancel={() => setMenuAction(null)}
        onConfirm={(target) => mutations.menuActionMutation.mutate(target)}
      />
      <DeleteMenuDialog
        target={deleteMenuTarget}
        pending={mutations.deleteMenuMutation.isPending}
        onCancel={() => setDeleteMenuTarget(null)}
        onConfirm={(menuId) => mutations.deleteMenuMutation.mutate(menuId)}
      />
      <ConfirmPaymentDialog
        target={confirmPaymentTarget}
        pending={mutations.confirmPaymentMutation.isPending}
        onCancel={() => setConfirmPaymentTarget(null)}
        onConfirm={(orderId) => mutations.confirmPaymentMutation.mutate(orderId)}
      />
    </div>
  );
}
