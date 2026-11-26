import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import {
  closeLunchMenu,
  confirmLunchExternalPayment,
  deleteLunchMenu,
  importLunchMenu,
  lunchKeys,
  notifyLunchMenu,
  reopenLunchMenu,
  summarizeLunchMenu,
  updateLunchMenu,
  type ImportLunchMenuInput,
  type LunchMenu,
  type LunchOrder,
} from "@/api/lunch.api";
import { getApiErrorMessage } from "@/lib/format";
import { notifyResultToast, type MenuAction } from "./admin-lunch-utils";
import type { AdminLunchSelection } from "./useAdminLunchData";
import type { MenuEditorState } from "./useMenuEditor";

type Context = {
  selection: AdminLunchSelection;
  editor: MenuEditorState;
  activeMenu: LunchMenu | null;
  deleteMenuTarget: LunchMenu | null;
  setMenuAction: (value: MenuAction | null) => void;
  setDeleteMenuTarget: (value: LunchMenu | null) => void;
  setConfirmPaymentTarget: (value: LunchOrder | null) => void;
};

/** Menu and order writes. Each success refreshes the admin and today's lunch queries. */
export function useAdminLunchMutations({ selection, editor, activeMenu, deleteMenuTarget, setMenuAction, setDeleteMenuTarget, setConfirmPaymentTarget }: Context) {
  const queryClient = useQueryClient();
  const refreshMenus = () => {
    void queryClient.invalidateQueries({ queryKey: lunchKeys.admin() });
    void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
  };
  const showSavedMenu = (menu: LunchMenu) => {
    selection.showMenu(menu);
    editor.setRawMenuText("");
    selection.setSummaryResult(null);
    refreshMenus();
  };

  const importMutation = useMutation({
    mutationFn: importLunchMenu,
    onSuccess: (menu) => {
      toast.success("Đã nhập và mở menu trong ngày.");
      showSavedMenu(menu);
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể nhập menu."));
    },
  });

  const updateMenuMutation = useMutation({
    mutationFn: ({ menuId, payload }: { menuId: string; payload: ImportLunchMenuInput }) =>
      updateLunchMenu(menuId, payload),
    onSuccess: (menu) => {
      toast.success("Đã cập nhật menu. Danh sách món mới đã sẵn sàng để thông báo.");
      editor.setEditingMenuId(null);
      showSavedMenu(menu);
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể cập nhật menu."));
    },
  });

  const deleteMenuMutation = useMutation({
    mutationFn: deleteLunchMenu,
    onSuccess: () => {
      toast.success("Đã xóa menu nháp. Bạn có thể import lại menu mới.");
      const deletedId = deleteMenuTarget?.id;
      setDeleteMenuTarget(null);
      selection.setSummaryResult(null);
      if (editor.editingMenuId === deletedId) {
        editor.reset();
      }
      if (selection.selectedMenuId === deletedId) {
        selection.setSelectedMenuId("");
      }
      refreshMenus();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể xóa menu. Menu có thể đã phát sinh đơn."));
    },
  });

  const menuActionMutation = useMutation({
    mutationFn: ({ menu, action }: MenuAction) =>
      action === "close" ? closeLunchMenu(menu.id) : reopenLunchMenu(menu.id),
    onSuccess: (menu, variables) => {
      toast.success(variables.action === "close" ? "Đã chốt nhận đơn." : "Đã mở lại nhận đơn.");
      setMenuAction(null);
      selection.setSelectedMenuId(menu.id);
      refreshMenus();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể thay đổi trạng thái menu."));
    },
  });

  const notifyMenuMutation = useMutation({
    mutationFn: notifyLunchMenu,
    onSuccess: (result) => {
      const { level, message } = notifyResultToast(result);
      if (level === "warning") toast.warning(message);
      else toast.success(message);
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể thông báo menu."));
    },
  });

  const summaryMutation = useMutation({
    mutationFn: summarizeLunchMenu,
    onSuccess: (summary, menuId) => {
      selection.setSummaryResult({ menuId, summary });
      toast.success("Đã chốt và tạo nội dung gửi quán.");
      refreshMenus();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể tổng hợp đơn."));
    },
  });

  const confirmPaymentMutation = useMutation({
    mutationFn: confirmLunchExternalPayment,
    onSuccess: () => {
      toast.success("Đã xác nhận thu tiền bên ngoài.");
      setConfirmPaymentTarget(null);
      if (activeMenu) {
        void queryClient.invalidateQueries({ queryKey: lunchKeys.adminOrders(activeMenu.id) });
      }
      void queryClient.invalidateQueries({ queryKey: lunchKeys.adminMembers() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.transactions() });
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể xác nhận thanh toán."));
    },
  });

  return {
    importMutation,
    updateMenuMutation,
    deleteMenuMutation,
    menuActionMutation,
    notifyMenuMutation,
    summaryMutation,
    confirmPaymentMutation,
    isSavingMenu: importMutation.isPending || updateMenuMutation.isPending,
  };
}
