import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, Clock3, QrCode, XCircle } from "lucide-react";
import { toast } from "sonner";

import {
  approveLunchPaymentRequest,
  getAdminLunchPaymentRequests,
  getLunchPaymentSettings,
  lunchKeys,
  rejectLunchPaymentRequest,
  updateLunchPaymentSettings,
  type LunchPaymentSettings,
} from "@/api/lunch.api";
import ImagePreviewDialog from "@/components/common/ImagePreviewDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { formatCurrency, formatDateTime, getApiErrorMessage } from "@/lib/format";

export default function AdminPaymentPanel() {
  const queryClient = useQueryClient();
  const [settingsDraft, setSettingsDraft] = useState<LunchPaymentSettings | null>(null);
  const settingsQuery = useQuery({
    queryKey: lunchKeys.paymentSettings(),
    queryFn: getLunchPaymentSettings,
  });
  const requestsQuery = useQuery({
    queryKey: lunchKeys.adminPaymentRequests(),
    queryFn: getAdminLunchPaymentRequests,
    refetchInterval: 20_000,
  });

  const settings = settingsDraft ?? settingsQuery.data ?? {};

  const refresh = () => {
    void queryClient.invalidateQueries({ queryKey: lunchKeys.adminPaymentRequests() });
    void queryClient.invalidateQueries({ queryKey: lunchKeys.adminMembers() });
    void queryClient.invalidateQueries({ queryKey: lunchKeys.notifications() });
  };
  const settingsMutation = useMutation({
    mutationFn: updateLunchPaymentSettings,
    onSuccess: (data) => {
      setSettingsDraft(data);
      toast.success("Đã lưu cấu hình thanh toán.");
      void queryClient.invalidateQueries({ queryKey: lunchKeys.paymentSettings() });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu cấu hình.")),
  });
  const approveMutation = useMutation({
    mutationFn: (id: string) => approveLunchPaymentRequest(id),
    onSuccess: () => {
      toast.success("Đã phê duyệt và cộng tiền vào sổ quỹ.");
      refresh();
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể phê duyệt.")),
  });
  const rejectMutation = useMutation({
    mutationFn: ({ id, note }: { id: string; note: string }) => rejectLunchPaymentRequest(id, note),
    onSuccess: () => {
      toast.success("Đã từ chối yêu cầu và báo cho người dùng.");
      refresh();
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể từ chối.")),
  });

  const requests = requestsQuery.data ?? [];
  const pending = requests.filter((request) => request.status === "PENDING");

  return (
    <div className="grid gap-4 xl:grid-cols-[minmax(300px,0.75fr)_minmax(0,1.25fr)]">
      <Card className="h-fit">
        <CardHeader>
          <CardTitle className="flex items-center gap-2"><QrCode className="size-5" />Cấu hình QR nhận tiền</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {settingsQuery.isError && (
            <PaymentLoadError
              message="Không tải được cấu hình QR hiện tại. Không nên lưu đè trước khi tải lại."
              onRetry={() => void settingsQuery.refetch()}
            />
          )}
          {settings.qrImageUrl && (
            <ImagePreviewDialog
              src={settings.qrImageUrl}
              alt="QR thanh toán"
              className="mx-auto aspect-square w-full max-w-56 border"
              imageClassName="object-contain"
            />
          )}
          <Field label="Ảnh QR" htmlFor="qr-file">
            <Input
              id="qr-file"
              type="file"
              accept="image/png,image/jpeg,image/webp,image/gif,image/avif"
              onChange={(event) => {
                const file = event.target.files?.[0];
                if (!file) return;
                if (!["image/png", "image/jpeg", "image/webp", "image/gif", "image/avif"].includes(file.type)) {
                  toast.error("Chỉ hỗ trợ PNG, JPEG, WebP, GIF hoặc AVIF.");
                  return;
                }
                if (file.size > 1_000_000) {
                  toast.error("Ảnh QR tối đa 1 MB.");
                  return;
                }
                const reader = new FileReader();
                reader.onload = () => setSettingsDraft((current) => ({ ...(current ?? settings), qrImageUrl: String(reader.result) }));
                reader.readAsDataURL(file);
              }}
            />
          </Field>
          <Field label="Ngân hàng" htmlFor="bank-name">
            <Input id="bank-name" value={settings.bankName ?? ""} onChange={(event) => setSettingsDraft({ ...settings, bankName: event.target.value })} />
          </Field>
          <Field label="Chủ tài khoản" htmlFor="account-name">
            <Input id="account-name" value={settings.accountName ?? ""} onChange={(event) => setSettingsDraft({ ...settings, accountName: event.target.value })} />
          </Field>
          <Field label="Số tài khoản" htmlFor="account-number">
            <Input id="account-number" value={settings.accountNumber ?? ""} onChange={(event) => setSettingsDraft({ ...settings, accountNumber: event.target.value })} />
          </Field>
          <Field label="Hướng dẫn" htmlFor="payment-instructions">
            <Input id="payment-instructions" value={settings.instructions ?? ""} onChange={(event) => setSettingsDraft({ ...settings, instructions: event.target.value })} />
          </Field>
          <Button
            className="w-full"
            onClick={() => settingsMutation.mutate(settings)}
            disabled={settingsMutation.isPending || settingsQuery.isError}
          >
            {settingsMutation.isPending ? "Đang lưu..." : "Lưu QR và tài khoản"}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between gap-3">
            <span>Yêu cầu thanh toán</span>
            {pending.length > 0 && <Badge className="bg-amber-100 text-amber-800">{pending.length} chờ duyệt</Badge>}
          </CardTitle>
        </CardHeader>
        <CardContent>
          {requestsQuery.isError ? (
            <PaymentLoadError
              message="Không tải được danh sách yêu cầu. Vui lòng thử lại để tránh bỏ sót thanh toán."
              onRetry={() => void requestsQuery.refetch()}
            />
          ) : requests.length === 0 ? (
            <p className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">
              Chưa có yêu cầu nào.
            </p>
          ) : (
            <div className="space-y-3">
              {[...requests].sort((a, b) => Number(b.status === "PENDING") - Number(a.status === "PENDING")).map((request) => (
                <div key={request.id} className="rounded-xl border p-3">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <p className="font-semibold">{request.user.fullName}</p>
                        <RequestStatus status={request.status} />
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {request.type === "DEBT_PAYMENT" ? "Thanh toán nợ" : "Nạp quỹ"} · {formatDateTime(request.createdAt)}
                      </p>
                      <p className="mt-2 text-xl font-bold">{formatCurrency(request.amount)}</p>
                      {request.note && <p className="mt-1 text-xs">Ghi chú: {request.note}</p>}
                      {request.reviewNote && <p className="mt-2 rounded-lg bg-slate-50 p-2 text-xs">{request.reviewNote}</p>}
                    </div>
                    {request.status === "PENDING" && (
                      <div className="flex shrink-0 gap-2">
                        <Button
                          size="sm"
                          onClick={() => {
                            if (window.confirm(`Đã nhận ${formatCurrency(request.amount)} từ ${request.user.fullName}?`)) {
                              approveMutation.mutate(request.id);
                            }
                          }}
                          disabled={approveMutation.isPending || rejectMutation.isPending}
                        >
                          <CheckCircle2 className="size-4" />Phê duyệt
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => {
                            const reason = window.prompt("Lý do từ chối:", "Chưa nhận được giao dịch ngân hàng");
                            if (reason?.trim()) rejectMutation.mutate({ id: request.id, note: reason.trim() });
                          }}
                          disabled={approveMutation.isPending || rejectMutation.isPending}
                        >
                          <XCircle className="size-4" />Từ chối
                        </Button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function Field({ label, htmlFor, children }: { label: string; htmlFor: string; children: React.ReactNode }) {
  return <div className="space-y-2"><Label htmlFor={htmlFor}>{label}</Label>{children}</div>;
}

function RequestStatus({ status }: { status: string }) {
  if (status === "APPROVED") return <Badge className="bg-emerald-100 text-emerald-800"><CheckCircle2 />Đã duyệt</Badge>;
  if (status === "REJECTED") return <Badge className="bg-red-100 text-red-800"><XCircle />Từ chối</Badge>;
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
