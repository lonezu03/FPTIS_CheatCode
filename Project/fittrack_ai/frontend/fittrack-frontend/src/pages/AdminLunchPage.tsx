import { useMemo, useState } from "react";
import type { ElementType } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  CalendarDays,
  CreditCard,
  CheckCircle2,
  ClipboardList,
  Copy,
  HandCoins,
  LockKeyhole,
  RefreshCw,
  RotateCcw,
  Upload,
  Users,
  UtensilsCrossed,
  Wallet,
} from "lucide-react";
import { toast } from "sonner";
import { useSearchParams } from "react-router-dom";

import {
  closeLunchMenu,
  confirmLunchExternalPayment,
  getAdminLunchMembers,
  getAdminLunchMenus,
  getAdminLunchOrders,
  importLunchMenu,
  lunchKeys,
  reopenLunchMenu,
  summarizeLunchMenu,
  topUpLunchFund,
  type ImportLunchMenuInput,
  type LunchMember,
  type LunchMenu,
  type LunchOrder,
  type LunchSummary,
} from "@/api/lunch.api";
import { LunchMetric, MenuStatusBadge, PaymentStatusBadge, SelectionTypeBadge } from "@/components/lunch/LunchStatus";
import PageHeader from "@/components/PageHeader";
import AdminMenuItemEditor from "@/components/lunch/AdminMenuItemEditor";
import AdminPaymentPanel from "@/components/lunch/AdminPaymentPanel";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import DataPagination from "@/components/common/DataPagination";
import { usePagination } from "@/hooks/usePagination";
import {
  formatCurrency,
  formatDate,
  formatDateTime,
  formatShortDate,
  getApiErrorMessage,
  getDefaultLunchCutoff,
  parseLunchMenu,
  toLocalDateInput,
} from "@/lib/format";

type MenuAction = {
  menu: LunchMenu;
  action: "close" | "reopen";
};

const DEFAULT_PRICE = 35_000;

export default function AdminLunchPage() {
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const requestedTab = searchParams.get("tab");
  const activeTab = ["menu", "orders", "funds", "payments"].includes(requestedTab ?? "")
    ? requestedTab!
    : "menu";
  const today = toLocalDateInput();
  const defaultCutoff = getDefaultLunchCutoff();
  const defaultMenuDate = defaultCutoff.slice(0, 10);

  const [fromDate, setFromDate] = useState(today);
  const [toDate, setToDate] = useState(today);
  const [selectedMenuId, setSelectedMenuId] = useState("");

  const [menuDate, setMenuDate] = useState(defaultMenuDate);
  const [orderLabel, setOrderLabel] = useState("");
  const [vendorName, setVendorName] = useState("");
  const [cutoffAt, setCutoffAt] = useState(defaultCutoff);
  const [price, setPrice] = useState(DEFAULT_PRICE);
  const [rawMenuText, setRawMenuText] = useState("");

  const [summaryResult, setSummaryResult] = useState<{ menuId: string; summary: LunchSummary } | null>(null);
  const [menuAction, setMenuAction] = useState<MenuAction | null>(null);
  const [confirmPaymentTarget, setConfirmPaymentTarget] = useState<LunchOrder | null>(null);

  const [selectedMemberId, setSelectedMemberId] = useState("");
  const [topUpAmount, setTopUpAmount] = useState(100_000);
  const [topUpNote, setTopUpNote] = useState("");

  const parsedMenu = useMemo(() => parseLunchMenu(rawMenuText), [rawMenuText]);

  const menusQuery = useQuery({
    queryKey: lunchKeys.adminMenus(fromDate, toDate),
    queryFn: () => getAdminLunchMenus(fromDate, toDate),
    enabled: fromDate <= toDate,
    refetchInterval: 30_000,
  });

  const menus = menusQuery.data ?? [];
  const activeMenu = menus.find((menu) => menu.id === selectedMenuId) ?? menus[0] ?? null;

  const ordersQuery = useQuery({
    queryKey: lunchKeys.adminOrders(activeMenu?.id ?? "none"),
    queryFn: () => (activeMenu ? getAdminLunchOrders(activeMenu.id) : Promise.resolve([])),
    enabled: !!activeMenu,
    refetchInterval: activeMenu?.acceptingOrders ? 30_000 : false,
  });

  const membersQuery = useQuery({
    queryKey: lunchKeys.adminMembers(),
    queryFn: getAdminLunchMembers,
    staleTime: 30_000,
  });

  const orders = ordersQuery.data ?? [];
  const members = membersQuery.data ?? [];
  const selectedMember = members.find((member) => member.id === selectedMemberId);
  const displayedSummary =
    summaryResult && summaryResult.menuId === activeMenu?.id ? summaryResult.summary : null;

  const importMutation = useMutation({
    mutationFn: importLunchMenu,
    onSuccess: (menu) => {
      toast.success("Đã nhập và mở menu trong ngày.");
      setFromDate(menu.menuDate);
      setToDate(menu.menuDate);
      setSelectedMenuId(menu.id);
      setRawMenuText("");
      setSummaryResult(null);
      void queryClient.invalidateQueries({ queryKey: lunchKeys.admin() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể nhập menu."));
    },
  });

  const menuActionMutation = useMutation({
    mutationFn: ({ menu, action }: MenuAction) =>
      action === "close" ? closeLunchMenu(menu.id) : reopenLunchMenu(menu.id),
    onSuccess: (menu, variables) => {
      toast.success(variables.action === "close" ? "Đã chốt nhận đơn." : "Đã mở lại nhận đơn.");
      setMenuAction(null);
      setSelectedMenuId(menu.id);
      void queryClient.invalidateQueries({ queryKey: lunchKeys.admin() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể thay đổi trạng thái menu."));
    },
  });

  const summaryMutation = useMutation({
    mutationFn: summarizeLunchMenu,
    onSuccess: (summary, menuId) => {
      setSummaryResult({ menuId, summary });
      toast.success("Đã chốt và tạo nội dung gửi quán.");
      void queryClient.invalidateQueries({ queryKey: lunchKeys.admin() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
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

  const topUpMutation = useMutation({
    mutationFn: topUpLunchFund,
    onSuccess: () => {
      toast.success("Đã ghi nhận tiền nạp quỹ.");
      setTopUpNote("");
      void queryClient.invalidateQueries({ queryKey: lunchKeys.adminMembers() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.transactions() });
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể nạp quỹ."));
    },
  });

  function handleImportMenu() {
    const payload: ImportLunchMenuInput = {
      menuDate,
      orderLabel: orderLabel.trim(),
      vendorName: vendorName.trim(),
      cutoffAt,
      price,
      rawMenuText: rawMenuText.trim(),
    };

    if (!payload.menuDate || !payload.cutoffAt || !payload.orderLabel || !payload.vendorName) {
      toast.error("Vui lòng điền đủ ngày, tiêu đề, tên quán và giờ chốt.");
      return;
    }

    if (!Number.isInteger(payload.price) || payload.price <= 0) {
      toast.error("Giá phần ăn phải là số nguyên dương.");
      return;
    }

    if (!parsedMenu.isValid) {
      toast.error("Menu chưa đúng định dạng. Vui lòng kiểm tra phần xem trước.");
      return;
    }

    importMutation.mutate(payload);
  }

  function handleTopUp() {
    if (!selectedMemberId) {
      toast.error("Vui lòng chọn thành viên.");
      return;
    }

    if (!Number.isInteger(topUpAmount) || topUpAmount <= 0) {
      toast.error("Số tiền nạp phải là số nguyên dương.");
      return;
    }

    topUpMutation.mutate({
      userId: selectedMemberId,
      amount: topUpAmount,
      note: topUpNote.trim(),
    });
  }

  async function copySummary(orderText: string) {
    try {
      await navigator.clipboard.writeText(orderText);
      toast.success("Đã sao chép nội dung gửi quán.");
    } catch {
      toast.error("Không thể sao chép tự động. Hãy chọn nội dung và sao chép thủ công.");
    }
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader title="Điều phối cơm" description="Nhập menu, chốt đơn, đối soát quỹ và xuất danh sách gửi quán." />
        <Button
          type="button"
          variant="outline"
          onClick={() => {
            void menusQuery.refetch();
            if (activeMenu) {
              void ordersQuery.refetch();
            }
          }}
          disabled={menusQuery.isFetching || ordersQuery.isFetching}
          className="self-start sm:self-auto"
        >
          <RefreshCw
            className={menusQuery.isFetching || ordersQuery.isFetching ? "animate-spin" : ""}
            aria-hidden="true"
          />
          Làm mới
        </Button>
      </div>

      <Card>
        <CardContent className="grid gap-3 md:grid-cols-[1fr_1fr_minmax(220px,1.2fr)] md:items-end">
          <div className="space-y-1.5">
            <Label htmlFor="admin-lunch-from">Từ ngày</Label>
            <Input id="admin-lunch-from" type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="admin-lunch-to">Đến ngày</Label>
            <Input id="admin-lunch-to" type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="admin-active-menu">Menu đang thao tác</Label>
            <select
              id="admin-active-menu"
              value={activeMenu?.id ?? ""}
              onChange={(event) => {
                setSelectedMenuId(event.target.value);
                setSummaryResult(null);
              }}
              disabled={menusQuery.isLoading || menus.length === 0}
              className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50"
            >
              {menus.length === 0 ? (
                <option value="">Chưa có menu trong khoảng ngày</option>
              ) : (
                menus.map((menu) => (
                  <option key={menu.id} value={menu.id}>
                    {formatShortDate(menu.menuDate)} · {menu.orderLabel}
                  </option>
                ))
              )}
            </select>
          </div>
        </CardContent>
      </Card>

      {fromDate > toDate && (
        <Alert variant="destructive">
          <AlertTriangle />
          <AlertTitle>Khoảng ngày không hợp lệ</AlertTitle>
          <AlertDescription>“Từ ngày” phải nhỏ hơn hoặc bằng “Đến ngày”.</AlertDescription>
        </Alert>
      )}

      {menusQuery.isError && (
        <AdminQueryError
          title="Không tải được danh sách menu"
          error={menusQuery.error}
          onRetry={() => void menusQuery.refetch()}
        />
      )}

      <Tabs
        value={activeTab}
        onValueChange={(tab) => setSearchParams(tab === "menu" ? {} : { tab })}
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
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Upload className="h-5 w-5" aria-hidden="true" />
                  Nhập menu mới
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label="Ngày bán" htmlFor="lunch-menu-date">
                    <Input
                      id="lunch-menu-date"
                      type="date"
                      value={menuDate}
                      onChange={(event) => {
                        setMenuDate(event.target.value);
                        setCutoffAt(`${event.target.value}T10:30`);
                      }}
                    />
                  </Field>
                  <Field label="Giờ chốt" htmlFor="lunch-cutoff">
                    <Input
                      id="lunch-cutoff"
                      type="datetime-local"
                      value={cutoffAt}
                      onChange={(event) => setCutoffAt(event.target.value)}
                    />
                  </Field>
                  <Field label="Tên người gom đơn" htmlFor="lunch-order-label">
                    <Input
                      id="lunch-order-label"
                      value={orderLabel}
                      onChange={(event) => setOrderLabel(event.target.value)}
                      maxLength={120}
                      placeholder="Ví dụ: Vũ"
                    />
                  </Field>
                  <Field label="Tên quán" htmlFor="lunch-vendor-name">
                    <Input
                      id="lunch-vendor-name"
                      value={vendorName}
                      onChange={(event) => setVendorName(event.target.value)}
                      maxLength={120}
                      placeholder="Quán cơm..."
                    />
                  </Field>
                  <Field label="Giá mỗi phần" htmlFor="lunch-price">
                    <Input
                      id="lunch-price"
                      type="number"
                      min={1_000}
                      step={1_000}
                      value={price}
                      onChange={(event) => setPrice(Number(event.target.value))}
                    />
                  </Field>
                  <div className="flex items-end">
                    <div className="w-full rounded-lg bg-slate-50 px-3 py-2 text-sm">
                      <span className="text-muted-foreground">Hiển thị: </span>
                      <strong>{formatCurrency(price)}</strong>
                    </div>
                  </div>
                </div>

                <Field label="Danh sách món quán gửi" htmlFor="raw-lunch-menu">
                  <textarea
                    id="raw-lunch-menu"
                    value={rawMenuText}
                    onChange={(event) => setRawMenuText(event.target.value)}
                    rows={13}
                    maxLength={5_000}
                    placeholder={"Lòng gà roty\nTôm ram\nSườn ram\nThịt kho\n+\nPhở bò"}
                    className="w-full resize-y rounded-lg border border-input bg-background px-3 py-2 font-mono text-sm leading-6 outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
                  />
                </Field>

                <div className="flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <p className="text-xs text-muted-foreground">
                    Mỗi dòng là một món. Nếu có món đơn, dùng dòng “+” để tách khỏi nhóm cơm 2 món.
                  </p>
                  <Button
                    type="button"
                    onClick={handleImportMenu}
                    disabled={importMutation.isPending || !parsedMenu.isValid}
                  >
                    <Upload aria-hidden="true" />
                    {importMutation.isPending ? "Đang nhập..." : "Nhập & mở menu"}
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card className="h-fit xl:sticky xl:top-6">
              <CardHeader>
                <CardTitle>Xem trước cách tách món</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {parsedMenu.errors.length > 0 && (
                  <Alert className="border-amber-200 bg-amber-50 text-amber-900">
                    <AlertTriangle />
                    <AlertTitle>Menu chưa sẵn sàng</AlertTitle>
                    <AlertDescription className="text-amber-800">
                      <ul className="list-disc space-y-1 pl-4">
                        {parsedMenu.errors.map((error) => (
                          <li key={error}>{error}</li>
                        ))}
                      </ul>
                    </AlertDescription>
                  </Alert>
                )}

                <MenuPreviewGroup
                  title="Cơm phần · chọn đúng 2"
                  items={parsedMenu.regularItems}
                  tone="regular"
                />
                <MenuPreviewGroup title="Món đơn · chọn 1" items={parsedMenu.specialItems} tone="special" />

                {parsedMenu.isValid && (
                  <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                    <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
                    Menu hợp lệ, sẵn sàng nhập.
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          <ActiveMenuPanel
            menu={activeMenu}
            summary={displayedSummary}
            loading={menusQuery.isLoading}
            summarizing={summaryMutation.isPending}
            changingStatus={menuActionMutation.isPending}
            onSummarize={() => activeMenu && summaryMutation.mutate(activeMenu.id)}
            onClose={() => activeMenu && setMenuAction({ menu: activeMenu, action: "close" })}
            onReopen={() => activeMenu && setMenuAction({ menu: activeMenu, action: "reopen" })}
            onCopy={copySummary}
          />
          {activeMenu && <AdminMenuItemEditor menu={activeMenu} />}
        </TabsContent>

        <TabsContent value="orders" className="space-y-4">
          {!activeMenu ? (
            <AdminEmptyState
              icon={CalendarDays}
              title="Chưa chọn menu"
              description="Nhập menu mới hoặc chọn một menu trong khoảng ngày phía trên."
            />
          ) : (
            <>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="text-lg font-semibold">{activeMenu.orderLabel}</h2>
                    <MenuStatusBadge status={activeMenu.status} acceptingOrders={activeMenu.acceptingOrders} />
                  </div>
                  <p className="mt-1 text-sm text-muted-foreground">
                    {formatDate(activeMenu.menuDate)} · {activeMenu.vendorName}
                  </p>
                </div>
                <Button type="button" variant="outline" onClick={() => void ordersQuery.refetch()} disabled={ordersQuery.isFetching}>
                  <RefreshCw className={ordersQuery.isFetching ? "animate-spin" : ""} aria-hidden="true" />
                  Cập nhật đơn
                </Button>
              </div>

              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                <LunchMetric label="Tổng số phần" value={orders.length} />
                <LunchMetric
                  label="Đã trừ quỹ"
                  value={orders.filter((order) => isFundPayment(order.paymentStatus)).length}
                  tone="success"
                />
                <LunchMetric
                  label="Đã thu bên ngoài"
                  value={orders.filter((order) => isExternalPayment(order.paymentStatus)).length}
                />
                <LunchMetric
                  label="Chưa thanh toán"
                  value={orders.filter((order) => isUnpaid(order.paymentStatus)).length}
                  tone={orders.some((order) => isUnpaid(order.paymentStatus)) ? "warning" : "default"}
                />
              </div>

              {ordersQuery.isLoading ? (
                <AdminListSkeleton />
              ) : ordersQuery.isError ? (
                <AdminQueryError
                  title="Không tải được danh sách đơn"
                  error={ordersQuery.error}
                  onRetry={() => void ordersQuery.refetch()}
                />
              ) : orders.length === 0 ? (
                <AdminEmptyState
                  icon={ClipboardList}
                  title="Chưa có ai đặt"
                  description="Danh sách sẽ tự cập nhật khi nhân viên bắt đầu chọn món."
                />
              ) : (
                <OrdersTable
                  orders={orders}
                  confirming={confirmPaymentMutation.isPending}
                  onConfirmExternal={setConfirmPaymentTarget}
                />
              )}
            </>
          )}
        </TabsContent>

        <TabsContent value="funds" className="space-y-4 md:space-y-6">
          <div className="grid gap-4 lg:grid-cols-[minmax(280px,0.7fr)_minmax(0,1.3fr)] lg:gap-6">
            <Card className="h-fit">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <HandCoins className="h-5 w-5" aria-hidden="true" />
                  Ghi nhận nạp quỹ
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Field label="Thành viên" htmlFor="fund-member">
                  <select
                    id="fund-member"
                    value={selectedMemberId}
                    onChange={(event) => setSelectedMemberId(event.target.value)}
                    disabled={membersQuery.isLoading}
                    className="h-9 w-full rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50"
                  >
                    <option value="">Chọn người đã nộp tiền...</option>
                    {members.map((member) => (
                      <option key={member.id} value={member.id}>
                        {member.fullName} · {formatCurrency(member.walletBalance)}
                      </option>
                    ))}
                  </select>
                </Field>

                {selectedMember && (
                  <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-50 p-3 text-sm">
                    <div>
                      <p className="text-xs text-muted-foreground">Số dư hiện tại</p>
                      <p className="mt-1 font-bold">{formatCurrency(selectedMember.walletBalance)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Công nợ</p>
                      <p className={selectedMember.outstandingDebt > 0 ? "mt-1 font-bold text-red-700" : "mt-1 font-bold"}>
                        {formatCurrency(selectedMember.outstandingDebt)}
                      </p>
                    </div>
                  </div>
                )}

                <Field label="Số tiền đã nhận" htmlFor="fund-amount">
                  <Input
                    id="fund-amount"
                    type="number"
                    min={1_000}
                    step={1_000}
                    value={topUpAmount}
                    onChange={(event) => setTopUpAmount(Number(event.target.value))}
                  />
                </Field>
                <div className="grid grid-cols-3 gap-2">
                  {[100_000, 200_000, 500_000].map((amount) => (
                    <Button
                      key={amount}
                      type="button"
                      size="sm"
                      variant={topUpAmount === amount ? "secondary" : "outline"}
                      onClick={() => setTopUpAmount(amount)}
                    >
                      {amount / 1_000}k
                    </Button>
                  ))}
                </div>

                <Field label="Ghi chú đối soát" htmlFor="fund-note">
                  <Input
                    id="fund-note"
                    value={topUpNote}
                    onChange={(event) => setTopUpNote(event.target.value)}
                    maxLength={250}
                    placeholder="Ví dụ: nhận chuyển khoản 25-07"
                  />
                </Field>

                <Alert>
                  <AlertTriangle />
                  <AlertTitle>Chỉ ghi nhận tiền đã nhận</AlertTitle>
                  <AlertDescription>
                    Thao tác này tăng số dư quỹ và được lưu vĩnh viễn trong sổ giao dịch.
                  </AlertDescription>
                </Alert>

                <Button
                  type="button"
                  className="w-full"
                  onClick={handleTopUp}
                  disabled={!selectedMemberId || topUpMutation.isPending}
                >
                  <HandCoins aria-hidden="true" />
                  {topUpMutation.isPending ? "Đang ghi nhận..." : `Xác nhận nạp ${formatCurrency(topUpAmount)}`}
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <div className="flex items-center justify-between gap-3">
                  <CardTitle>Quỹ thành viên</CardTitle>
                  <Badge variant="secondary">{members.length} người</Badge>
                </div>
              </CardHeader>
              <CardContent>
                {membersQuery.isLoading ? (
                  <AdminListSkeleton />
                ) : membersQuery.isError ? (
                  <AdminQueryError
                    title="Không tải được danh sách thành viên"
                    error={membersQuery.error}
                    onRetry={() => void membersQuery.refetch()}
                  />
                ) : members.length === 0 ? (
                  <AdminEmptyState
                    icon={Users}
                    title="Chưa có thành viên"
                    description="Tài khoản nhân viên sẽ xuất hiện tại đây."
                  />
                ) : (
                  <MembersTable members={members} onSelect={setSelectedMemberId} />
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="payments" className="space-y-4 md:space-y-6">
          <AdminPaymentPanel />
        </TabsContent>
      </Tabs>

      <Dialog open={!!menuAction} onOpenChange={(open) => !open && setMenuAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{menuAction?.action === "close" ? "Chốt nhận đơn?" : "Mở lại menu?"}</DialogTitle>
            <DialogDescription>
              {menuAction?.action === "close"
                ? "Nhân viên sẽ không thể tạo, sửa hoặc hủy phần ăn sau khi chốt."
                : "Nhân viên sẽ có thể tiếp tục thay đổi đơn nếu menu chưa được tổng hợp."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setMenuAction(null)} disabled={menuActionMutation.isPending}>
              Quay lại
            </Button>
            <Button
              type="button"
              onClick={() => menuAction && menuActionMutation.mutate(menuAction)}
              disabled={!menuAction || menuActionMutation.isPending}
            >
              {menuActionMutation.isPending
                ? "Đang xử lý..."
                : menuAction?.action === "close"
                  ? "Chốt nhận đơn"
                  : "Mở lại"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!confirmPaymentTarget} onOpenChange={(open) => !open && setConfirmPaymentTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Xác nhận đã thu tiền?</DialogTitle>
            <DialogDescription>
              {confirmPaymentTarget
                ? `Ghi nhận đã nhận ${formatCurrency(confirmPaymentTarget.price)} bên ngoài từ ${confirmPaymentTarget.beneficiary.fullName}.`
                : "Đơn sẽ được chuyển sang trạng thái đã thanh toán bên ngoài."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setConfirmPaymentTarget(null)}
              disabled={confirmPaymentMutation.isPending}
            >
              Chưa nhận
            </Button>
            <Button
              type="button"
              onClick={() => confirmPaymentTarget && confirmPaymentMutation.mutate(confirmPaymentTarget.id)}
              disabled={!confirmPaymentTarget || confirmPaymentMutation.isPending}
            >
              {confirmPaymentMutation.isPending ? "Đang xác nhận..." : "Đã nhận đủ tiền"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function ActiveMenuPanel({
  menu,
  summary,
  loading,
  summarizing,
  changingStatus,
  onSummarize,
  onClose,
  onReopen,
  onCopy,
}: {
  menu: LunchMenu | null;
  summary: LunchSummary | null;
  loading: boolean;
  summarizing: boolean;
  changingStatus: boolean;
  onSummarize: () => void;
  onClose: () => void;
  onReopen: () => void;
  onCopy: (text: string) => Promise<void>;
}) {
  if (loading) {
    return <Skeleton className="h-64 rounded-xl" />;
  }

  if (!menu) {
    return (
      <AdminEmptyState
        icon={CalendarDays}
        title="Chưa có menu để tổng hợp"
        description="Nhập menu mới ở phía trên hoặc chọn một ngày đã có menu."
      />
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <CardTitle>{menu.orderLabel}</CardTitle>
              <MenuStatusBadge status={menu.status} acceptingOrders={menu.acceptingOrders} />
            </div>
            <p className="mt-1 text-sm text-muted-foreground">
              {formatDate(menu.menuDate)} · {menu.vendorName} · chốt {formatDateTime(menu.cutoffAt)}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            {menu.acceptingOrders ? (
              <Button type="button" variant="outline" onClick={onClose} disabled={changingStatus || summarizing}>
                <LockKeyhole aria-hidden="true" />
                Chốt nhận đơn
              </Button>
            ) : !menu.summarized ? (
              <Button type="button" variant="outline" onClick={onReopen} disabled={changingStatus || summarizing}>
                <RotateCcw aria-hidden="true" />
                Mở lại
              </Button>
            ) : null}
            <Button type="button" onClick={onSummarize} disabled={summarizing || changingStatus}>
              <ClipboardList aria-hidden="true" />
              {summarizing
                ? "Đang tổng hợp..."
                : menu.summarized
                  ? summary
                    ? "Tải lại tổng hợp"
                    : "Xem lại tổng hợp"
                  : "Chốt & tổng hợp"}
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-5">
        <div className="grid gap-3 sm:grid-cols-3">
          <LunchMetric label="Số phần đã đặt" value={menu.totalOrders} />
          <LunchMetric label="Chưa thanh toán" value={menu.unpaidOrders} tone={menu.unpaidOrders > 0 ? "warning" : "default"} />
          <LunchMetric label="Doanh số dự kiến" value={formatCurrency(menu.totalOrders * menu.price)} />
        </div>

        {!summary ? (
          <div className="rounded-xl border border-dashed bg-slate-50 p-5 text-center">
            <ClipboardList className="mx-auto h-7 w-7 text-slate-400" aria-hidden="true" />
            <h3 className="mt-2 font-semibold">Chưa tạo bản tổng hợp</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              “Chốt & tổng hợp” sẽ đóng menu và tạo nội dung sẵn để gửi cho quán.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
              <LunchMetric label="Tổng phần" value={summary.totalOrders} />
              <LunchMetric label="Trừ quỹ" value={summary.paidFundOrders} tone="success" />
              <LunchMetric label="Thu bên ngoài" value={summary.paidExternalOrders} />
              <LunchMetric label="Chưa trả" value={summary.unpaidOrders} tone={summary.unpaidOrders > 0 ? "warning" : "default"} />
              <LunchMetric label="Tổng tiền" value={formatCurrency(summary.totalAmount)} />
            </div>

            {summary.unpaidOrders > 0 && (
              <Alert className="border-amber-200 bg-amber-50 text-amber-900">
                <AlertTriangle />
                <AlertTitle>Còn {summary.unpaidOrders} phần chưa thanh toán</AlertTitle>
                <AlertDescription className="text-amber-800">
                  Danh sách món vẫn được tổng hợp đầy đủ. Hãy đối soát ở tab “Đơn hôm nay”.
                </AlertDescription>
              </Alert>
            )}

            <div className="grid gap-4 lg:grid-cols-[minmax(0,1.4fr)_minmax(250px,0.6fr)]">
              <div className="space-y-2">
                <div className="flex items-center justify-between gap-3">
                  <Label htmlFor="lunch-summary-text">Nội dung gửi quán</Label>
                  <Button type="button" variant="outline" size="sm" onClick={() => void onCopy(summary.orderText)}>
                    <Copy aria-hidden="true" />
                    Sao chép
                  </Button>
                </div>
                <textarea
                  id="lunch-summary-text"
                  readOnly
                  value={summary.orderText}
                  rows={Math.min(Math.max(summary.totalOrders + 2, 8), 18)}
                  onFocus={(event) => event.currentTarget.select()}
                  className="w-full resize-y rounded-lg border border-input bg-slate-950 px-3 py-3 font-mono text-sm leading-6 text-slate-50 outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
                />
              </div>
              <div>
                <p className="mb-2 text-sm font-medium">Thống kê từng món</p>
                <div className="space-y-2">
                  {summary.dishCounts.map((dish) => (
                    <div key={dish.dishName} className="flex items-center justify-between gap-3 rounded-lg bg-slate-50 px-3 py-2 text-sm">
                      <span className="font-medium">{dish.dishName}</span>
                      <Badge variant="secondary">{dish.count}</Badge>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function MenuPreviewGroup({
  title,
  items,
  tone,
}: {
  title: string;
  items: string[];
  tone: "regular" | "special";
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between gap-3">
        <h3 className="text-sm font-semibold">{title}</h3>
        <Badge variant="secondary">{items.length} món</Badge>
      </div>
      {items.length === 0 ? (
        <p className="rounded-xl border border-dashed p-3 text-sm text-muted-foreground">Chưa nhận diện được món.</p>
      ) : (
        <ol className="max-h-52 space-y-1.5 overflow-y-auto pr-1">
          {items.map((item, index) => (
            <li
              key={item}
              className={
                tone === "regular"
                  ? "flex items-center gap-2 rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-950"
                  : "flex items-center gap-2 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-950"
              }
            >
              <span className="text-xs font-semibold opacity-60">{index + 1}.</span>
              <span className="font-medium">{item}</span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}

function OrdersTable({
  orders,
  confirming,
  onConfirmExternal,
}: {
  orders: LunchOrder[];
  confirming: boolean;
  onConfirmExternal: (order: LunchOrder) => void;
}) {
  const pagination = usePagination(orders);
  return (
    <>
      <Card className="hidden md:block">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Người nhận</TableHead>
                <TableHead>Phần ăn</TableHead>
                <TableHead>Đặt bởi / trả bởi</TableHead>
                <TableHead>Thanh toán</TableHead>
                <TableHead className="text-right">Thao tác</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pagination.paginatedItems.map((order) => (
                <TableRow key={order.id}>
                  <TableCell>
                    <div>
                      <p className="font-medium">{order.beneficiary.fullName}</p>
                      <p className="text-xs text-muted-foreground">{formatCurrency(order.price)}</p>
                    </div>
                  </TableCell>
                  <TableCell className="max-w-[360px] whitespace-normal">
                    <div className="space-y-1">
                      <SelectionTypeBadge type={order.selectionType} />
                      <p className="font-medium">{order.displayText}</p>
                      {order.note && <p className="text-xs text-muted-foreground">Ghi chú: {order.note}</p>}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{order.orderedBy.fullName}</p>
                      <p className="text-xs text-muted-foreground">
                        {order.payer ? `Quỹ: ${order.payer.fullName}` : "Chưa trừ quỹ"}
                      </p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <PaymentStatusBadge status={order.paymentStatus} />
                  </TableCell>
                  <TableCell className="text-right">
                    {isUnpaid(order.paymentStatus) ? (
                      <Button
                        type="button"
                        size="sm"
                        variant="outline"
                        onClick={() => onConfirmExternal(order)}
                        disabled={confirming}
                      >
                        <HandCoins aria-hidden="true" />
                        Đã thu tiền
                      </Button>
                    ) : (
                      <span className="text-xs text-muted-foreground">Đã đối soát</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <div className="grid gap-3 md:hidden">
        {pagination.paginatedItems.map((order) => (
          <Card key={order.id} size="sm">
            <CardContent className="space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="font-semibold">{order.beneficiary.fullName}</h3>
                  <p className="mt-1 font-medium">{order.displayText}</p>
                  {order.note && <p className="mt-1 text-xs text-muted-foreground">Ghi chú: {order.note}</p>}
                </div>
                <PaymentStatusBadge status={order.paymentStatus} />
              </div>
              <div className="rounded-lg bg-slate-50 px-3 py-2 text-xs text-muted-foreground">
                Đặt bởi {order.orderedBy.fullName} · {order.payer ? `trừ quỹ ${order.payer.fullName}` : "chưa trừ quỹ"}
              </div>
              {isUnpaid(order.paymentStatus) && (
                <Button
                  type="button"
                  className="w-full"
                  variant="outline"
                  onClick={() => onConfirmExternal(order)}
                  disabled={confirming}
                >
                  <HandCoins aria-hidden="true" />
                  Xác nhận đã thu {formatCurrency(order.price)}
                </Button>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
      <DataPagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        totalItems={pagination.totalItems}
        totalPages={pagination.totalPages}
        onPageChange={pagination.setPage}
        onPageSizeChange={pagination.setPageSize}
      />
    </>
  );
}

function MembersTable({
  members,
  onSelect,
}: {
  members: LunchMember[];
  onSelect: (memberId: string) => void;
}) {
  const pagination = usePagination(members);
  return (
    <>
      <div className="hidden md:block">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Thành viên</TableHead>
              <TableHead>Số dư</TableHead>
              <TableHead>Công nợ</TableHead>
              <TableHead className="text-right">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pagination.paginatedItems.map((member) => (
              <TableRow key={member.id}>
                <TableCell>
                  <div>
                    <p className="font-medium">{member.fullName}</p>
                    <p className="text-xs text-muted-foreground">{member.email}</p>
                  </div>
                </TableCell>
                <TableCell className={member.walletBalance < 0 ? "font-semibold text-red-700" : "font-semibold"}>
                  {formatCurrency(member.walletBalance)}
                </TableCell>
                <TableCell>
                  {member.outstandingDebt > 0 ? (
                    <Badge className="border-amber-200 bg-amber-50 text-amber-800" variant="outline">
                      {formatCurrency(member.outstandingDebt)}
                    </Badge>
                  ) : (
                    <span className="text-xs text-muted-foreground">Không có</span>
                  )}
                </TableCell>
                <TableCell className="text-right">
                  <Button type="button" variant="outline" size="sm" onClick={() => onSelect(member.id)}>
                    <HandCoins aria-hidden="true" />
                    Nạp quỹ
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="grid gap-2 md:hidden">
        {pagination.paginatedItems.map((member) => (
          <button
            key={member.id}
            type="button"
            onClick={() => onSelect(member.id)}
            className="flex items-center justify-between gap-3 rounded-xl border bg-white p-3 text-left transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400"
          >
            <span className="min-w-0">
              <span className="block truncate font-semibold">{member.fullName}</span>
              <span className="block truncate text-xs text-muted-foreground">{member.email}</span>
            </span>
            <span className="shrink-0 text-right">
              <span className="block font-bold">{formatCurrency(member.walletBalance)}</span>
              <span className={member.outstandingDebt > 0 ? "block text-xs text-red-700" : "block text-xs text-muted-foreground"}>
                Nợ {formatCurrency(member.outstandingDebt)}
              </span>
            </span>
          </button>
        ))}
      </div>
      <DataPagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        totalItems={pagination.totalItems}
        totalPages={pagination.totalPages}
        onPageChange={pagination.setPage}
        onPageSizeChange={pagination.setPageSize}
      />
    </>
  );
}

function Field({
  label,
  htmlFor,
  children,
}: {
  label: string;
  htmlFor: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <Label htmlFor={htmlFor}>{label}</Label>
      {children}
    </div>
  );
}

function AdminEmptyState({
  icon: Icon,
  title,
  description,
}: {
  icon: ElementType;
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

function AdminQueryError({
  title,
  error,
  onRetry,
}: {
  title: string;
  error: unknown;
  onRetry: () => void;
}) {
  return (
    <Alert variant="destructive">
      <AlertTriangle />
      <AlertTitle>{title}</AlertTitle>
      <AlertDescription>
        <p>{getApiErrorMessage(error, "Vui lòng kiểm tra kết nối rồi thử lại.")}</p>
        <Button type="button" variant="outline" size="sm" className="mt-3" onClick={onRetry}>
          <RefreshCw aria-hidden="true" />
          Thử lại
        </Button>
      </AlertDescription>
    </Alert>
  );
}

function AdminListSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 5 }).map((_, index) => (
        <Skeleton key={index} className="h-16 rounded-xl" />
      ))}
    </div>
  );
}

function isUnpaid(status: string): boolean {
  return status.toUpperCase() === "UNPAID";
}

function isFundPayment(status: string): boolean {
  return status.toUpperCase().includes("FUND");
}

function isExternalPayment(status: string): boolean {
  return status.toUpperCase().includes("EXTERNAL");
}
