import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  ArrowDownLeft,
  ArrowUpRight,
  CalendarDays,
  CirclePlus,
  CreditCard,
  History,
  ReceiptText,
  RefreshCw,
  ShoppingCart,
  Trash2,
  UserRound,
  UtensilsCrossed,
  Wallet,
} from "lucide-react";
import { toast } from "sonner";
import { useSearchParams } from "react-router-dom";

import {
  createLunchOrderBatch,
  deleteLunchOrder,
  getLunchOrderHistory,
  getLunchPeople,
  getLunchWalletTransactions,
  getTodayLunch,
  lunchKeys,
  updateLunchOrder,
  type LunchOrder,
  type LunchOrderPortionInput,
  type LunchOrderUpdateInput,
  type LunchSelectionType,
} from "@/api/lunch.api";
import LunchOrderCard from "@/components/lunch/LunchOrderCard";
import { CutoffStatus, LunchMetric, MenuStatusBadge } from "@/components/lunch/LunchStatus";
import MenuPicker from "@/components/lunch/MenuPicker";
import LunchReviewDialog from "@/components/lunch/LunchReviewDialog";
import LunchPaymentPanel from "@/components/lunch/LunchPaymentPanel";
import PageHeader from "@/components/PageHeader";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { formatCurrency, formatDate, formatDateTime, getApiErrorMessage } from "@/lib/format";
import { useAuthStore } from "@/store/auth.store";

const NOTE_SUGGESTIONS = ["Cơm thêm", "Rau thêm"];

type CartPortion = LunchOrderPortionInput & {
  id: string;
};

export default function LunchPage() {
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const requestedTab = searchParams.get("tab");
  const activeTab = ["today", "history", "wallet", "payment"].includes(requestedTab ?? "")
    ? requestedTab!
    : "today";
  const authUser = useAuthStore((state) => state.user);
  const [selectionType, setSelectionType] = useState<LunchSelectionType>("COMBO");
  const [selectedItemIds, setSelectedItemIds] = useState<string[]>([]);
  const [beneficiaryUserId, setBeneficiaryUserId] = useState("");
  const [note, setNote] = useState("");
  const [cartPortions, setCartPortions] = useState<CartPortion[]>([]);
  const [cartRequestId, setCartRequestId] = useState<string | null>(null);
  const [editingOrder, setEditingOrder] = useState<LunchOrder | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<LunchOrder | null>(null);
  const [reviewTarget, setReviewTarget] = useState<LunchOrder | null>(null);

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
      setCartPortions([]);
      setCartRequestId(null);
      resetOrderForm();
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
      resetOrderForm();
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
      setDeleteTarget(null);
      resetOrderForm();
      refreshLunchData();
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể hủy phần ăn."));
    },
  });

  const today = todayQuery.data;
  const menu = today?.menu ?? null;
  const people = peopleQuery.data ?? [];
  const history = historyQuery.data ?? [];
  const transactions = transactionsQuery.data ?? [];

  const todayOrders = useMemo(() => {
    const byId = new Map<string, LunchOrder>();

    const myOrders = today?.myMealOrders ?? (today?.myMealOrder ? [today.myMealOrder] : []);
    for (const order of myOrders) {
      byId.set(order.id, order);
    }

    for (const order of today?.ordersPlacedByMe ?? []) {
      byId.set(order.id, order);
    }

    return [...byId.values()].filter((order) => order.status.toUpperCase() !== "CANCELLED");
  }, [today]);

  const selectedItems = useMemo(() => {
    if (!menu) {
      return [];
    }

    return [...menu.regularItems, ...menu.specialItems].filter((item) => selectedItemIds.includes(item.id));
  }, [menu, selectedItemIds]);

  const selectedBeneficiary = people.find((person) => person.id === beneficiaryUserId);
  const selectedNutrition = selectedItems.reduce(
    (total, item) => ({
      calories: total.calories + (item.calories ?? 0),
      protein: total.protein + (item.protein ?? 0),
      carbs: total.carbs + (item.carbs ?? 0),
      fat: total.fat + (item.fat ?? 0),
    }),
    { calories: 0, protein: 0, carbs: 0, fat: 0 },
  );
  const walletBalance = today?.walletBalance ?? 0;
  const insufficientBalance = !!menu && walletBalance < menu.price;
  const sponsoredCartTotal = cartPortions
    .filter((portion) => !!portion.beneficiaryUserId)
    .reduce((total) => total + (menu?.price ?? 0), 0);
  const currentPortionIsSponsored = !!beneficiaryUserId;
  const cannotSponsor = currentPortionIsSponsored && walletBalance < sponsoredCartTotal + (menu?.price ?? 0);
  const cannotSubmitCart = sponsoredCartTotal > walletBalance;
  const cartTotal = cartPortions.length * (menu?.price ?? 0);
  const requiredItemCount = selectionType === "COMBO" ? 2 : 1;
  const isBusy = batchMutation.isPending || updateMutation.isPending;

  function resetOrderForm() {
    setSelectionType("COMBO");
    setSelectedItemIds([]);
    setBeneficiaryUserId("");
    setNote("");
    setEditingOrder(null);
  }

  function startEditing(order: LunchOrder) {
    setEditingOrder(order);
    setSelectionType(order.selectionType);
    setSelectedItemIds(order.items.map((item) => item.id));
    setBeneficiaryUserId("");
    setNote(order.note ?? "");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function toggleNoteSuggestion(suggestion: string) {
    const currentParts = note
      .split("+")
      .map((part) => part.trim())
      .filter(Boolean);
    const exists = currentParts.some((part) => part.toLocaleLowerCase("vi-VN") === suggestion.toLocaleLowerCase("vi-VN"));
    const nextParts = exists
      ? currentParts.filter((part) => part.toLocaleLowerCase("vi-VN") !== suggestion.toLocaleLowerCase("vi-VN"))
      : [...currentParts, suggestion];
    setNote(nextParts.join(" + "));
  }

  function saveCurrentPortion() {
    if (!menu || !menu.acceptingOrders) {
      toast.error("Menu đã chốt hoặc chưa mở nhận đơn.");
      return;
    }

    if (!today?.canOrder) {
      toast.error(today?.blockReason || "Tài khoản hiện chưa thể đặt cơm.");
      return;
    }

    if (selectedItemIds.length !== requiredItemCount) {
      toast.error(selectionType === "COMBO" ? "Vui lòng chọn đúng 2 món." : "Vui lòng chọn 1 món đơn.");
      return;
    }

    if (cannotSponsor) {
      toast.error("Số dư quỹ không đủ để trả hộ các phần đang có trong giỏ.");
      return;
    }

    if (editingOrder) {
      updateMutation.mutate({
        orderId: editingOrder.id,
        payload: {
          selectionType,
          itemIds: selectedItemIds,
          note: note.trim(),
        },
      });
      return;
    }

    setCartPortions((current) => [
      ...current,
      {
        id: createCartPortionId(),
      beneficiaryUserId: beneficiaryUserId || undefined,
      selectionType,
      itemIds: selectedItemIds,
      note: note.trim(),
      },
    ]);
    setCartRequestId(null);
    toast.success("Đã thêm phần ăn vào giỏ. Bạn có thể chọn thêm phần khác hoặc đặt tất cả cùng lúc.");
    resetOrderForm();
  }

  function submitCart() {
    if (!menu || cartPortions.length === 0) {
      return;
    }
    const clientRequestId = cartRequestId ?? createCartRequestId();
    if (!cartRequestId) {
      setCartRequestId(clientRequestId);
    }
    batchMutation.mutate({
      menuId: menu.id,
      clientRequestId,
      portions: cartPortions.map((portion) => ({
        beneficiaryUserId: portion.beneficiaryUserId,
        selectionType: portion.selectionType,
        itemIds: portion.itemIds,
        note: portion.note,
      })),
    });
  }

  if (todayQuery.isLoading) {
    return <LunchPageLoading />;
  }

  if (todayQuery.isError || !today) {
    return (
      <div className="space-y-4 md:space-y-6">
        <PageHeader title="Đặt cơm" description="Chọn món, theo dõi quỹ và lịch sử đặt cơm." />
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
        <PageHeader title="Đặt cơm" description="Chọn món hôm nay, đặt hộ đồng nghiệp và theo dõi quỹ cơm." />
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
          {!today.canOrder && (
            <Alert className="border-red-200 bg-red-50 text-red-900" variant="destructive">
              <AlertTriangle />
              <AlertTitle>Hiện chưa thể đặt phần mới</AlertTitle>
              <AlertDescription>
                {today.blockReason || "Vui lòng thanh toán công nợ với admin trước khi đặt phần mới."}
              </AlertDescription>
            </Alert>
          )}

          <div className="grid gap-3 sm:grid-cols-3">
            <LunchMetric
              label={today.walletBalance < 0 ? "Số dư ròng (đang nợ)" : "Số dư quỹ của bạn"}
              value={formatCurrency(today.walletBalance)}
              hint={menu ? `Giá hôm nay: ${formatCurrency(menu.price)}` : "Chưa có menu hôm nay"}
              tone={menu && today.walletBalance < menu.price ? "warning" : "success"}
            />
            <LunchMetric
              label="Phần bạn đã đặt"
              value={todayOrders.length}
              hint={todayOrders.length > 0 ? "Bạn có thể đặt thêm phần nếu cần" : "Bạn chưa đặt phần nào"}
            />
            <LunchMetric
              label="Công nợ hiện tại"
              value={formatCurrency(today.outstandingDebt)}
              hint="có thể thanh toán bằng QR"
              tone={today.outstandingDebt > 0 ? "warning" : "default"}
            />
          </div>

          {!menu ? (
            <Card>
              <CardContent className="flex min-h-56 flex-col items-center justify-center gap-3 text-center">
                <div className="rounded-full bg-slate-100 p-4">
                  <CalendarDays className="h-7 w-7 text-slate-500" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="font-semibold">Chưa có menu hôm nay</h2>
                  <p className="mt-1 max-w-md text-sm text-muted-foreground">
                    Admin chưa đăng menu. Bạn có thể quay lại sau hoặc kiểm tra lịch sử đặt cơm.
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            <>
              <Card className="border-orange-200 bg-gradient-to-br from-orange-50 via-white to-emerald-50">
                <CardContent className="grid gap-4 py-1 lg:grid-cols-[1fr_auto] lg:items-center">
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <MenuStatusBadge status={menu.status} acceptingOrders={menu.acceptingOrders} />
                      <span className="text-xs font-medium text-muted-foreground">{formatDate(menu.menuDate)}</span>
                    </div>
                    <h2 className="mt-2 text-xl font-bold tracking-tight sm:text-2xl">{menu.orderLabel}</h2>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {menu.vendorName} · {formatCurrency(menu.price)}/phần
                    </p>
                  </div>
                  <CutoffStatus cutoffAt={menu.cutoffAt} acceptingOrders={menu.acceptingOrders} />
                </CardContent>
              </Card>

              <div className="grid gap-4 lg:grid-cols-[minmax(0,1.6fr)_minmax(280px,0.8fr)] lg:gap-6">
                <Card>
                  <CardHeader>
                    <CardTitle>{editingOrder ? `Sửa phần của ${editingOrder.beneficiary.fullName}` : "Tạo phần ăn"}</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-5">
                    {!editingOrder && (
                      <Alert className="border-emerald-200 bg-emerald-50/70 text-emerald-950">
                        <ShoppingCart />
                        <AlertTitle>Mỗi phần cơm chọn đúng 2 món</AlertTitle>
                        <AlertDescription>
                          Thêm từng phần vào giỏ, sau đó đặt tất cả cùng lúc. Bạn có thể tạo nhiều phần cho mình hoặc đặt hộ đồng nghiệp.
                        </AlertDescription>
                      </Alert>
                    )}
                    {!editingOrder && (
                      <div className="space-y-2">
                        <Label htmlFor="lunch-beneficiary">Người nhận phần ăn</Label>
                        <div className="relative">
                          <UserRound
                            className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
                            aria-hidden="true"
                          />
                          <select
                            id="lunch-beneficiary"
                            value={beneficiaryUserId}
                            onChange={(event) => setBeneficiaryUserId(event.target.value)}
                            disabled={!menu.acceptingOrders || !today.canOrder || peopleQuery.isLoading}
                            className="h-10 w-full appearance-none rounded-lg border border-input bg-background py-2 pl-9 pr-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
                          >
                            <option value="">Tôi — đặt cho bản thân</option>
                            {people.map((person) => (
                              <option key={person.id} value={person.id}>
                                {person.fullName} — đặt hộ
                              </option>
                            ))}
                          </select>
                        </div>
                        <p className="text-xs text-muted-foreground">
                          Khi đặt hộ, hệ thống ưu tiên trừ quỹ của bạn. Hai bên tự đối soát với nhau bên ngoài.
                        </p>
                      </div>
                    )}

                    <MenuPicker
                      menu={menu}
                      selectionType={selectionType}
                      selectedItemIds={selectedItemIds}
                      disabled={!menu.acceptingOrders || !today.canOrder || isBusy}
                      onTypeChange={setSelectionType}
                      onItemsChange={setSelectedItemIds}
                    />

                    <div className="space-y-2">
                      <Label htmlFor="lunch-note">Ghi chú cho quán</Label>
                      <div className="flex flex-wrap gap-2">
                        {NOTE_SUGGESTIONS.map((suggestion) => {
                          const selected = note.toLocaleLowerCase("vi-VN").includes(suggestion.toLocaleLowerCase("vi-VN"));
                          return (
                            <Button
                              key={suggestion}
                              type="button"
                              size="sm"
                              variant={selected ? "secondary" : "outline"}
                              onClick={() => toggleNoteSuggestion(suggestion)}
                              disabled={!menu.acceptingOrders || !today.canOrder}
                            >
                              {selected ? "✓ " : "+ "}
                              {suggestion}
                            </Button>
                          );
                        })}
                      </div>
                      <textarea
                        id="lunch-note"
                        value={note}
                        onChange={(event) => setNote(event.target.value)}
                        maxLength={300}
                        rows={3}
                        disabled={!menu.acceptingOrders || !today.canOrder}
                        placeholder="Ví dụ: ít cơm, không lấy hành..."
                        className="w-full resize-y rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50"
                      />
                      <p className="text-right text-[11px] text-muted-foreground">{note.length}/300</p>
                    </div>
                  </CardContent>
                </Card>

                <Card className="h-fit lg:sticky lg:top-6">
                  <CardHeader>
                    <CardTitle>{editingOrder ? "Xác nhận chỉnh sửa" : "Phần đang tạo"}</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-2 rounded-xl bg-slate-50 p-3">
                      <SummaryRow label="Người nhận" value={editingOrder?.beneficiary.fullName ?? selectedBeneficiary?.fullName ?? "Tôi"} />
                      <SummaryRow label="Loại phần" value={selectionType === "COMBO" ? "Cơm 2 món" : "Món đơn"} />
                      <SummaryRow label="Đơn giá" value={formatCurrency(menu.price)} strong />
                    </div>

                    <div>
                      <p className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">Món đã chọn</p>
                      {selectedItems.length === 0 ? (
                        <p className="rounded-xl border border-dashed p-3 text-sm text-muted-foreground">
                          Chưa chọn món.
                        </p>
                      ) : (
                        <ul className="space-y-2">
                          {selectedItems.map((item, index) => (
                            <li key={item.id} className="flex items-start gap-2 rounded-lg border bg-white px-3 py-2 text-sm">
                              <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-slate-900 text-[11px] font-semibold text-white">
                                {index + 1}
                              </span>
                              <span className="font-medium">{item.name}</span>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>

                    {selectedItems.length > 0 && (
                      <div className="grid grid-cols-2 gap-2 rounded-xl bg-emerald-50 p-3 text-xs sm:grid-cols-4">
                        <SummaryRow label="Calo" value={`${Math.round(selectedNutrition.calories)} kcal`} />
                        <SummaryRow label="Protein" value={`${selectedNutrition.protein.toFixed(1)}g`} />
                        <SummaryRow label="Carb" value={`${selectedNutrition.carbs.toFixed(1)}g`} />
                        <SummaryRow label="Fat" value={`${selectedNutrition.fat.toFixed(1)}g`} />
                      </div>
                    )}

                    {insufficientBalance && !editingOrder && (
                      <Alert className="border-amber-200 bg-amber-50 text-amber-900">
                        <AlertTriangle />
                        <AlertTitle>{cannotSponsor ? "Không đủ quỹ để trả hộ" : "Quỹ hiện không đủ"}</AlertTitle>
                        <AlertDescription className="text-amber-800">
                          {cannotSponsor
                            ? "Bạn cần nạp thêm quỹ hoặc để người nhận tự đặt. Đơn trả hộ chỉ được tạo khi quỹ của người trả còn đủ."
                            : `Bạn vẫn có thể tự đặt. Hệ thống sẽ ghi ${formatCurrency(-menu.price)} vào sổ công nợ.`}
                        </AlertDescription>
                      </Alert>
                    )}

                    <div className="flex flex-col gap-2">
                      <Button
                        type="button"
                        size="lg"
                        className="w-full"
                        onClick={saveCurrentPortion}
                        disabled={
                          !menu.acceptingOrders ||
                          !today.canOrder ||
                          isBusy ||
                          selectedItemIds.length !== requiredItemCount ||
                          cannotSponsor
                        }
                      >
                        {isBusy
                          ? "Đang lưu..."
                          : editingOrder
                            ? "Lưu thay đổi"
                            : insufficientBalance && !beneficiaryUserId
                              ? "Thêm phần vào giỏ (ghi nợ)"
                              : beneficiaryUserId
                                ? "Thêm phần đặt hộ vào giỏ"
                                : "Thêm phần vào giỏ"}
                      </Button>
                      {editingOrder && (
                        <Button type="button" variant="ghost" onClick={resetOrderForm} disabled={isBusy}>
                          Bỏ chỉnh sửa
                        </Button>
                      )}
                    </div>

                    {!editingOrder && (
                      <div className="space-y-3 rounded-xl border border-emerald-200 bg-emerald-50/50 p-3">
                        <div className="flex items-center justify-between gap-3">
                          <div className="flex items-center gap-2">
                            <ShoppingCart className="size-4 text-emerald-700" aria-hidden="true" />
                            <p className="text-sm font-semibold">Giỏ đặt cơm</p>
                          </div>
                          <span className="rounded-full bg-white px-2 py-0.5 text-xs font-semibold text-emerald-800">
                            {cartPortions.length} phần
                          </span>
                        </div>

                        {cartPortions.length === 0 ? (
                          <p className="rounded-lg border border-dashed border-emerald-200 bg-white/70 p-3 text-xs text-muted-foreground">
                            Chưa có phần nào trong giỏ. Chọn món rồi bấm “Thêm phần vào giỏ”.
                          </p>
                        ) : (
                          <ul className="space-y-2">
                            {cartPortions.map((portion, index) => {
                              const recipient = portion.beneficiaryUserId
                                ? people.find((person) => person.id === portion.beneficiaryUserId)?.fullName ?? "Đồng nghiệp"
                                : "Tôi";
                              const dishes = portion.itemIds
                                .map((itemId) => [...menu.regularItems, ...menu.specialItems].find((item) => item.id === itemId)?.name)
                                .filter(Boolean)
                                .join(" + ");
                              return (
                                <li key={portion.id} className="flex gap-2 rounded-lg border bg-white p-2.5">
                                  <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-xs font-bold text-emerald-800">
                                    {index + 1}
                                  </span>
                                  <div className="min-w-0 flex-1">
                                    <p className="text-xs font-semibold">{recipient} · {portion.selectionType === "COMBO" ? "Cơm 2 món" : "Món đơn"}</p>
                                    <p className="mt-0.5 truncate text-xs text-muted-foreground">{dishes}</p>
                                    {portion.note && <p className="mt-0.5 text-[11px] text-muted-foreground">Ghi chú: {portion.note}</p>}
                                  </div>
                                  <Button
                                    type="button"
                                    size="icon"
                                    variant="ghost"
                                    className="size-7 text-red-600 hover:text-red-700"
                                    aria-label={`Bỏ phần ${index + 1} khỏi giỏ`}
                                    onClick={() => {
                                      setCartPortions((current) => current.filter((item) => item.id !== portion.id));
                                      setCartRequestId(null);
                                    }}
                                    disabled={isBusy}
                                  >
                                    <Trash2 className="size-4" />
                                  </Button>
                                </li>
                              );
                            })}
                          </ul>
                        )}

                        {cannotSubmitCart && cartPortions.length > 0 && (
                          <Alert className="border-amber-200 bg-amber-50 text-amber-900">
                            <AlertTriangle />
                            <AlertDescription>
                              Quỹ hiện không đủ để trả hộ tất cả phần trong giỏ. Bỏ bớt phần đặt hộ hoặc nạp thêm quỹ trước khi đặt.
                            </AlertDescription>
                          </Alert>
                        )}

                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">Tạm tính</span>
                          <strong>{formatCurrency(cartTotal)}</strong>
                        </div>
                        <Button
                          type="button"
                          className="w-full"
                          size="lg"
                          onClick={submitCart}
                          disabled={
                            cartPortions.length === 0 ||
                            !menu.acceptingOrders ||
                            !today.canOrder ||
                            isBusy ||
                            cannotSubmitCart
                          }
                        >
                          <CirclePlus aria-hidden="true" />
                          {isBusy ? "Đang gửi đơn..." : `Đặt ${cartPortions.length} phần · ${formatCurrency(cartTotal)}`}
                        </Button>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>

              <section className="space-y-3" aria-labelledby="today-orders-heading">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h2 id="today-orders-heading" className="text-lg font-semibold">
                      Các phần bạn phụ trách hôm nay
                    </h2>
                    <p className="text-xs text-muted-foreground">Gồm phần của bạn và các phần đặt hộ.</p>
                  </div>
                  <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold">{todayOrders.length} phần</span>
                </div>

                {todayOrders.length === 0 ? (
                  <div className="rounded-xl border border-dashed bg-white p-6 text-center text-sm text-muted-foreground">
                    Bạn chưa đặt phần ăn nào hôm nay.
                  </div>
                ) : (
                  <div className="grid gap-3 lg:grid-cols-2">
                    {todayOrders.map((order) => (
                      <LunchOrderCard
                        key={order.id}
                        order={order}
                        canModify={menu.acceptingOrders}
                        busy={deleteMutation.isPending || updateMutation.isPending}
                        onEdit={startEditing}
                        onDelete={setDeleteTarget}
                      />
                    ))}
                  </div>
                )}
              </section>
            </>
          )}
        </TabsContent>

        <TabsContent value="history" className="space-y-4">
          <SectionHeading
            icon={History}
            title="Lịch sử đặt cơm"
            description="Xem lại món, người nhận và trạng thái thanh toán của từng phần."
          />
          {historyQuery.isLoading ? (
            <ListSkeleton />
          ) : historyQuery.isError ? (
            <QueryError
              title="Không tải được lịch sử"
              message={getApiErrorMessage(historyQuery.error, "Vui lòng thử lại.")}
              onRetry={() => void historyQuery.refetch()}
            />
          ) : history.length === 0 ? (
            <EmptySection icon={ReceiptText} title="Chưa có lịch sử" description="Các phần đã đặt sẽ xuất hiện tại đây." />
          ) : (
            <div className="grid gap-3 lg:grid-cols-2">
              {history.map((order) => (
                <LunchOrderCard
                  key={order.id}
                  order={order}
                  onReview={order.beneficiary.id === authUser?.userId ? setReviewTarget : undefined}
                />
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="wallet" className="space-y-4">
          <SectionHeading
            icon={Wallet}
            title="Sổ quỹ cơm"
            description="Mỗi lần nạp, trừ quỹ hoặc điều chỉnh đều được lưu lại để dễ đối soát."
          />

          <Card className="border-emerald-200 bg-emerald-50/60">
            <CardContent className="flex items-center justify-between gap-4">
              <div>
                <p className="text-sm text-emerald-800">Số dư ròng</p>
                <p className={`mt-1 text-2xl font-bold sm:text-3xl ${today.walletBalance < 0 ? "text-red-700" : "text-emerald-950"}`}>
                  {formatCurrency(today.walletBalance)}
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
                {transactions.map((transaction) => {
                  const positive = transaction.amount >= 0;
                  return (
                    <div key={transaction.id} className="flex items-start gap-3 px-3 py-3.5 sm:px-4">
                      <div
                        className={
                          positive
                            ? "rounded-full bg-emerald-100 p-2 text-emerald-700"
                            : "rounded-full bg-orange-100 p-2 text-orange-700"
                        }
                      >
                        {positive ? (
                          <ArrowDownLeft className="h-4 w-4" aria-hidden="true" />
                        ) : (
                          <ArrowUpRight className="h-4 w-4" aria-hidden="true" />
                        )}
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
                })}
              </CardContent>
            </Card>
          )}
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

      <Dialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy phần ăn?</DialogTitle>
            <DialogDescription>
              {deleteTarget
                ? `Phần “${deleteTarget.displayText}” của ${deleteTarget.beneficiary.fullName} sẽ bị hủy.`
                : "Phần ăn sẽ bị hủy."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setDeleteTarget(null)} disabled={deleteMutation.isPending}>
              Giữ lại
            </Button>
            <Button
              type="button"
              variant="destructive"
              onClick={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
              disabled={!deleteTarget || deleteMutation.isPending}
            >
              {deleteMutation.isPending ? "Đang hủy..." : "Xác nhận hủy"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function createCartPortionId(): string {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function createCartRequestId(): string {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `order_${Date.now()}_${Math.random().toString(36).slice(2, 12)}`;
}

function SummaryRow({
  label,
  value,
  strong = false,
}: {
  label: string;
  value: string;
  strong?: boolean;
}) {
  return (
    <div className="flex items-start justify-between gap-3 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className={strong ? "text-right font-bold" : "text-right font-medium"}>{value}</span>
    </div>
  );
}

function SectionHeading({
  icon: Icon,
  title,
  description,
}: {
  icon: typeof History;
  title: string;
  description: string;
}) {
  return (
    <div className="flex items-start gap-3">
      <div className="rounded-xl bg-slate-100 p-2.5">
        <Icon className="h-5 w-5 text-slate-700" aria-hidden="true" />
      </div>
      <div>
        <h2 className="text-lg font-semibold">{title}</h2>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>
    </div>
  );
}

function EmptySection({
  icon: Icon,
  title,
  description,
}: {
  icon: typeof Wallet;
  title: string;
  description: string;
}) {
  return (
    <div className="flex min-h-48 flex-col items-center justify-center rounded-xl border border-dashed bg-white p-6 text-center">
      <div className="rounded-full bg-slate-100 p-3">
        <Icon className="h-6 w-6 text-slate-500" aria-hidden="true" />
      </div>
      <h3 className="mt-3 font-semibold">{title}</h3>
      <p className="mt-1 max-w-md text-sm text-muted-foreground">{description}</p>
    </div>
  );
}

function QueryError({
  title,
  message,
  onRetry,
}: {
  title: string;
  message: string;
  onRetry: () => void;
}) {
  return (
    <Alert variant="destructive">
      <AlertTriangle />
      <AlertTitle>{title}</AlertTitle>
      <AlertDescription>
        <p>{message}</p>
        <Button type="button" variant="outline" size="sm" className="mt-3" onClick={onRetry}>
          <RefreshCw aria-hidden="true" />
          Thử lại
        </Button>
      </AlertDescription>
    </Alert>
  );
}

function ListSkeleton() {
  return (
    <div className="grid gap-3 lg:grid-cols-2">
      {Array.from({ length: 4 }).map((_, index) => (
        <Skeleton key={index} className="h-36 rounded-xl" />
      ))}
    </div>
  );
}

function LunchPageLoading() {
  return (
    <div className="space-y-4 md:space-y-6">
      <div className="space-y-2">
        <Skeleton className="h-8 w-40" />
        <Skeleton className="h-4 w-80 max-w-full" />
      </div>
      <div className="grid gap-3 sm:grid-cols-3">
        {Array.from({ length: 3 }).map((_, index) => (
          <Skeleton key={index} className="h-24 rounded-xl" />
        ))}
      </div>
      <Skeleton className="h-28 rounded-xl" />
      <div className="grid gap-4 lg:grid-cols-[1.6fr_0.8fr]">
        <Skeleton className="h-[520px] rounded-xl" />
        <Skeleton className="h-80 rounded-xl" />
      </div>
    </div>
  );
}

function getTransactionLabel(type: string): string {
  const normalized = type.toUpperCase();

  if (normalized.includes("DEBT_PAYMENT")) {
    return "Thanh toán công nợ";
  }
  if (normalized.includes("TOP") || normalized.includes("DEPOSIT")) {
    return "Nạp quỹ";
  }
  if (normalized.includes("REFUND")) {
    return "Hoàn tiền phần ăn";
  }
  if (normalized.includes("ORDER") || normalized.includes("MEAL") || normalized.includes("DEBIT")) {
    return "Thanh toán phần ăn";
  }
  if (normalized.includes("ADJUST")) {
    return "Điều chỉnh quỹ";
  }
  return "Giao dịch quỹ";
}
