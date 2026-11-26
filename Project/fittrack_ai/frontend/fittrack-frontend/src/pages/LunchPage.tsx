import { useMemo, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { CreditCard, History, RefreshCw, UtensilsCrossed, Wallet } from "lucide-react";
import { toast } from "sonner";
import { useSearchParams } from "react-router-dom";

import { lunchKeys, type LunchOrder } from "@/api/lunch.api";
import LunchPaymentPanel from "@/components/lunch/LunchPaymentPanel";
import LunchReviewDialog from "@/components/lunch/LunchReviewDialog";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import LunchDeleteOrderDialog from "@/features/lunch/LunchDeleteOrderDialog";
import LunchHistoryTab from "@/features/lunch/LunchHistoryTab";
import LunchTodayTab from "@/features/lunch/LunchTodayTab";
import LunchWalletTab from "@/features/lunch/LunchWalletTab";
import { LunchPageLoading, QueryError } from "@/features/lunch/lunch-ui";
import { collectTodayOrders, resolveLunchTab } from "@/features/lunch/lunch-utils";
import { useLunchMutations, useLunchQueries } from "@/features/lunch/useLunchData";
import { useLunchOrderForm } from "@/features/lunch/useLunchOrderForm";
import { getApiErrorMessage } from "@/lib/format";
import { useAuthStore } from "@/store/auth.store";

export default function LunchPage() {
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = resolveLunchTab(searchParams.get("tab"));
  const authUser = useAuthStore((state) => state.user);
  const [deleteTarget, setDeleteTarget] = useState<LunchOrder | null>(null);
  const [reviewTarget, setReviewTarget] = useState<LunchOrder | null>(null);

  const { todayQuery, peopleQuery, historyQuery, transactionsQuery } = useLunchQueries(activeTab);
  const today = todayQuery.data;
  const people = peopleQuery.data ?? [];
  const form = useLunchOrderForm(today, people);
  const { batchMutation, updateMutation, deleteMutation } = useLunchMutations({
    onBatchSuccess: () => { form.clearCart(); form.resetOrderForm(); },
    onUpdateSuccess: () => form.resetOrderForm(),
    onDeleteSuccess: () => { setDeleteTarget(null); form.resetOrderForm(); },
  });
  const todayOrders = useMemo(() => collectTodayOrders(today), [today]);
  const isBusy = batchMutation.isPending || updateMutation.isPending;

  function saveCurrentPortion() {
    const error = form.validationError();
    if (error) {
      toast.error(error);
      return;
    }
    if (form.editingOrder) {
      updateMutation.mutate({ orderId: form.editingOrder.id, payload: form.updatePayload() });
      return;
    }
    form.addCurrentPortionToCart();
  }

  function submitCart() {
    const payload = form.checkoutPayload();
    if (payload) batchMutation.mutate(payload);
  }

  if (todayQuery.isLoading) {
    return <LunchPageLoading />;
  }

  if (todayQuery.isError || !today) {
    return (
      <div className="space-y-4 md:space-y-6">
        <PageHeader title="Đặt cơm" />
        <QueryError
          title="Không tải được thông tin đặt cơm"
          message={getApiErrorMessage(todayQuery.error, "Vui lòng kiểm tra kết nối rồi thử lại.")}
          onRetry={() => void todayQuery.refetch()}
        />
      </div>
    );
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader title="Đặt cơm" />
        <Button
          type="button"
          variant="outline"
          onClick={() => void todayQuery.refetch()}
          disabled={todayQuery.isFetching}
          className="self-start sm:self-auto"
        >
          <RefreshCw className={todayQuery.isFetching ? "animate-spin" : ""} aria-hidden="true" />
          Làm mới
        </Button>
      </div>

      <Tabs
        value={activeTab}
        onValueChange={(tab) => setSearchParams(tab === "today" ? {} : { tab })}
        className="gap-4"
      >
        <TabsList className="grid h-auto w-full grid-cols-4 sm:w-fit">
          <TabsTrigger value="today" className="min-h-9 px-3">
            <UtensilsCrossed aria-hidden="true" />
            Hôm nay
          </TabsTrigger>
          <TabsTrigger value="history" className="min-h-9 px-3">
            <History aria-hidden="true" />
            Lịch sử
          </TabsTrigger>
          <TabsTrigger value="wallet" className="min-h-9 px-3">
            <Wallet aria-hidden="true" />
            Sổ quỹ
          </TabsTrigger>
          <TabsTrigger value="payment" className="min-h-9 px-3">
            <CreditCard aria-hidden="true" />
            Thanh toán
          </TabsTrigger>
        </TabsList>

        <TabsContent value="today" className="space-y-4 md:space-y-6">
          <LunchTodayTab
            today={today}
            todayOrders={todayOrders}
            form={form}
            people={people}
            peopleLoading={peopleQuery.isLoading}
            isBusy={isBusy}
            ordersBusy={deleteMutation.isPending || updateMutation.isPending}
            onSave={saveCurrentPortion}
            onSubmitCart={submitCart}
            onDeleteOrder={setDeleteTarget}
          />
        </TabsContent>

        <TabsContent value="history" className="space-y-4">
          <LunchHistoryTab historyQuery={historyQuery} currentUserId={authUser?.userId} onReview={setReviewTarget} />
        </TabsContent>

        <TabsContent value="wallet" className="space-y-4">
          <LunchWalletTab walletBalance={today.walletBalance} transactionsQuery={transactionsQuery} />
        </TabsContent>

        <TabsContent value="payment" className="space-y-4">
          <LunchPaymentPanel
            walletBalance={today.walletBalance}
            outstandingDebt={today.outstandingDebt}
          />
        </TabsContent>
      </Tabs>

      <LunchReviewDialog
        key={reviewTarget?.id ?? "review-empty"}
        order={reviewTarget}
        open={!!reviewTarget}
        onOpenChange={(open) => !open && setReviewTarget(null)}
        onSaved={() => {
          void queryClient.invalidateQueries({ queryKey: lunchKeys.history() });
          void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
        }}
      />

      <LunchDeleteOrderDialog
        target={deleteTarget}
        pending={deleteMutation.isPending}
        onClose={() => setDeleteTarget(null)}
        onConfirm={(order) => deleteMutation.mutate(order.id)}
      />
    </div>
  );
}
