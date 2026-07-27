import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Banknote, CheckCircle2, Clock3, Copy, QrCode, XCircle } from "lucide-react";
import { toast } from "sonner";

import {
  createLunchPaymentRequest,
  getLunchPaymentSettings,
  getMyLunchPaymentRequests,
  lunchKeys,
  type LunchPaymentRequestType,
} from "@/api/lunch.api";
import ImagePreviewDialog from "@/components/common/ImagePreviewDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { formatCurrency, formatDateTime, getApiErrorMessage } from "@/lib/format";
import { useAuthStore } from "@/store/auth.store";

type Props = {
  walletBalance: number;
  outstandingDebt: number;
};

export default function LunchPaymentPanel({ walletBalance, outstandingDebt }: Props) {
  const queryClient = useQueryClient();
  const authUser = useAuthStore((state) => state.user);
  const [type, setType] = useState<LunchPaymentRequestType>(
    outstandingDebt > 0 ? "DEBT_PAYMENT" : "FUND_TOP_UP",
  );
  const [amount, setAmount] = useState(outstandingDebt > 0 ? outstandingDebt : 100_000);
  const [note, setNote] = useState("");

  const settingsQuery = useQuery({
    queryKey: lunchKeys.paymentSettings(),
    queryFn: getLunchPaymentSettings,
  });
  const requestsQuery = useQuery({
    queryKey: lunchKeys.paymentRequests(),
    queryFn: getMyLunchPaymentRequests,
    refetchInterval: 20_000,
  });
  const createMutation = useMutation({
    mutationFn: createLunchPaymentRequest,
    onSuccess: () => {
      toast.success("Đã báo admin. Yêu cầu đang chờ đối soát ngân hàng.");
      setNote("");
      void queryClient.invalidateQueries({ queryKey: lunchKeys.paymentRequests() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.notifications() });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể gửi yêu cầu thanh toán.")),
  });

  const settings = settingsQuery.data;
  const requests = requestsQuery.data ?? [];
  const userReference = (
    authUser?.email.split("@")[0] ||
    authUser?.userId.slice(0, 8) ||
    "USER"
  )
    .replace(/[^a-zA-Z0-9]/g, "")
    .slice(0, 12)
    .toUpperCase();
  const transferContent =
    `FITTRACK ${type === "DEBT_PAYMENT" ? "TRA NO" : "NAP QUY"} ${userReference} ${amount}`;

  const submit = () => {
    if (!amount || amount <= 0) {
      toast.error("Vui lòng nhập số tiền hợp lệ.");
      return;
    }
    if (type === "DEBT_PAYMENT" && amount > outstandingDebt) {
      toast.error("Số tiền trả nợ không được lớn hơn công nợ.");
      return;
    }
    createMutation.mutate({ type, amount, note: note || transferContent });
  };

  return (
    <div className="grid gap-4 xl:grid-cols-[minmax(300px,0.8fr)_minmax(0,1.2fr)]">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <QrCode className="size-5 text-emerald-700" />
            Chuyển khoản bằng QR
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1">
            <Button
              variant={type === "FUND_TOP_UP" ? "default" : "ghost"}
              aria-pressed={type === "FUND_TOP_UP"}
              onClick={() => setType("FUND_TOP_UP")}
            >
              Nạp quỹ
            </Button>
            <Button
              variant={type === "DEBT_PAYMENT" ? "default" : "ghost"}
              aria-pressed={type === "DEBT_PAYMENT"}
              onClick={() => {
                setType("DEBT_PAYMENT");
                if (outstandingDebt > 0) setAmount(outstandingDebt);
              }}
              disabled={outstandingDebt <= 0}
            >
              Thanh toán nợ
            </Button>
          </div>

          <div className="grid grid-cols-2 gap-3 rounded-xl border bg-slate-50 p-3 text-sm">
            <div>
              <p className="text-xs text-muted-foreground">Số dư ròng</p>
              <p className={walletBalance < 0 ? "font-bold text-red-700" : "font-bold text-emerald-700"}>
                {formatCurrency(walletBalance)}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Công nợ</p>
              <p className="font-bold text-red-700">{formatCurrency(outstandingDebt)}</p>
            </div>
          </div>

          {settingsQuery.isError ? (
            <PaymentLoadError
              message="Không tải được cấu hình QR."
              onRetry={() => void settingsQuery.refetch()}
            />
          ) : settings?.qrImageUrl ? (
            <ImagePreviewDialog
              src={settings.qrImageUrl}
              alt="Mã QR thanh toán quỹ cơm"
              className="mx-auto aspect-square w-full max-w-64 border"
              imageClassName="object-contain"
            />
          ) : (
            <div className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">
              Admin chưa cấu hình mã QR.
            </div>
          )}

          <div className="rounded-xl bg-emerald-50 p-3 text-sm">
            <p className="font-semibold">{settings?.bankName || "Thông tin ngân hàng"}</p>
            <p>{settings?.accountName}</p>
            <p className="font-mono font-semibold">{settings?.accountNumber}</p>
            {settings?.instructions && <p className="mt-2 text-xs text-emerald-800">{settings.instructions}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="payment-amount">Số tiền</Label>
            <Input
              id="payment-amount"
              type="number"
              min={1}
              step={1000}
              value={amount}
              onChange={(event) => setAmount(Number(event.target.value))}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="payment-note">Nội dung chuyển khoản / ghi chú</Label>
            <div className="flex gap-2">
              <Input
                id="payment-note"
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder={transferContent}
              />
              <Button
                variant="outline"
                size="icon"
                aria-label="Sao chép nội dung chuyển khoản"
                onClick={() => {
                  void navigator.clipboard.writeText(note || transferContent);
                  toast.success("Đã sao chép nội dung chuyển khoản.");
                }}
              >
                <Copy className="size-4" />
              </Button>
            </div>
          </div>
          <Button
            className="w-full"
            onClick={submit}
            disabled={createMutation.isPending || !settings?.qrImageUrl}
          >
            <Banknote className="size-4" />
            {createMutation.isPending ? "Đang báo admin..." : "Tôi đã chuyển khoản"}
          </Button>
          <p className="text-xs text-muted-foreground">
            Số dư chỉ thay đổi sau khi admin kiểm tra tài khoản ngân hàng và phê duyệt.
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Lịch sử yêu cầu thanh toán</CardTitle>
        </CardHeader>
        <CardContent>
          {requestsQuery.isError ? (
            <PaymentLoadError
              message="Không tải được lịch sử thanh toán."
              onRetry={() => void requestsQuery.refetch()}
            />
          ) : requests.length === 0 ? (
            <p className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">
              Chưa có yêu cầu thanh toán.
            </p>
          ) : (
            <div className="space-y-3">
              {requests.map((request) => (
                <div key={request.id} className="rounded-xl border p-3">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-semibold">
                        {request.type === "DEBT_PAYMENT" ? "Thanh toán nợ" : "Nạp quỹ"}
                      </p>
                      <p className="text-xs text-muted-foreground">{formatDateTime(request.createdAt)}</p>
                    </div>
                    <PaymentRequestBadge status={request.status} />
                  </div>
                  <p className="mt-2 text-lg font-bold">{formatCurrency(request.amount)}</p>
                  {request.reviewNote && (
                    <p className="mt-2 rounded-lg bg-slate-50 p-2 text-xs">{request.reviewNote}</p>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function PaymentRequestBadge({ status }: { status: string }) {
  if (status === "APPROVED") {
    return <Badge className="bg-emerald-100 text-emerald-800"><CheckCircle2 />Đã duyệt</Badge>;
  }
  if (status === "REJECTED") {
    return <Badge className="bg-red-100 text-red-800"><XCircle />Từ chối</Badge>;
  }
  return <Badge className="bg-amber-100 text-amber-800"><Clock3 />Chờ duyệt</Badge>;
}

function PaymentLoadError({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      <p>{message}</p>
      <Button type="button" variant="outline" size="sm" className="mt-2" onClick={onRetry}>
        Thử lại
      </Button>
    </div>
  );
}
