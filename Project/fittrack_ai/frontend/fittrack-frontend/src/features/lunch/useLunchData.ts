import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createLunchOrderBatch,
  deleteLunchOrder,
  getLunchOrderHistory,
  getLunchPeople,
  getLunchWalletTransactions,
  getTodayLunch,
  lunchKeys,
  updateLunchOrder,
  type LunchOrderUpdateInput,
} from "@/api/lunch.api";
import { formatCurrency, getApiErrorMessage } from "@/lib/format";
import type { LunchTab } from "./lunch-utils";

/** Truy vấn của màn Đặt cơm; lịch sử và sổ quỹ chỉ tải khi mở tab. */
export function useLunchQueries(activeTab: LunchTab) {
  const todayQuery = useQuery({
    queryKey: lunchKeys.today(),
    queryFn: getTodayLunch,
    staleTime: 20_000,
  });
  const peopleQuery = useQuery({
    queryKey: lunchKeys.people(),
    queryFn: getLunchPeople,
    staleTime: 60_000,
  });
  const historyQuery = useQuery({
    queryKey: lunchKeys.history(),
    queryFn: getLunchOrderHistory,
    enabled: activeTab === "history",
  });
  const transactionsQuery = useQuery({
    queryKey: lunchKeys.transactions(),
    queryFn: getLunchWalletTransactions,
    enabled: activeTab === "wallet",
  });
  return { todayQuery, peopleQuery, historyQuery, transactionsQuery };
}

/** Đặt giỏ, sửa và hủy phần ăn; làm mới các màn liên quan khi thành công. */
export function useLunchMutations({
  onBatchSuccess,
  onUpdateSuccess,
  onDeleteSuccess,
}: {
  onBatchSuccess: () => void;
  onUpdateSuccess: () => void;
  onDeleteSuccess: () => void;
}) {
  const queryClient = useQueryClient();

  const refreshLunchData = () => {
    void Promise.all([
      queryClient.invalidateQueries({ queryKey: lunchKeys.today() }),
      queryClient.invalidateQueries({ queryKey: lunchKeys.history() }),
      queryClient.invalidateQueries({ queryKey: lunchKeys.transactions() }),
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] }),
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] }),
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] }),
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] }),
      queryClient.invalidateQueries({ queryKey: ["achievements"] }),
      queryClient.invalidateQueries({ queryKey: ["foods"] }),
    ]);
  };

  const batchMutation = useMutation({
    mutationFn: createLunchOrderBatch,
    onSuccess: (result) => {
      toast.success(
        `Đã đặt ${result.orders.length} phần. Sổ công nợ đã ghi ${formatCurrency(-result.totalPrice)}.`,
      );
      onBatchSuccess();
      refreshLunchData();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể đặt cơm. Vui lòng thử lại."));
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ orderId, payload }: { orderId: string; payload: LunchOrderUpdateInput }) =>
      updateLunchOrder(orderId, payload),
    onSuccess: () => {
      toast.success("Đã cập nhật phần ăn.");
      onUpdateSuccess();
      refreshLunchData();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể cập nhật phần ăn."));
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteLunchOrder,
    onSuccess: () => {
      toast.success("Đã hủy phần ăn.");
      onDeleteSuccess();
      refreshLunchData();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể hủy phần ăn."));
    },
  });

  return { batchMutation, updateMutation, deleteMutation };
}
