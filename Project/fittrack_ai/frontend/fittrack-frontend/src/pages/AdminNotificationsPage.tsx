import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { BellRing, MailCheck, Send } from "lucide-react";
import { toast } from "sonner";
import { getAdminUsers } from "@/api/admin-user.api";
import { broadcastNotification, getMailStatus, sendTestEmail } from "@/api/notification.api";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getApiErrorMessage } from "@/lib/format";

export default function AdminNotificationsPage() {
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [sendToAll, setSendToAll] = useState(true);
  const [recipients, setRecipients] = useState<string[]>([]);
  const usersQuery = useQuery({ queryKey: ["admin-users", "notification"], queryFn: () => getAdminUsers() });
  const mailStatusQuery = useQuery({ queryKey: ["admin", "mail-status"], queryFn: getMailStatus });
  const users = (usersQuery.data ?? []).filter((user) => user.active);

  const mutation = useMutation({
    mutationFn: broadcastNotification,
    onSuccess: (result) => {
      toast.success(`Đã gửi tới ${result.recipientCount} tài khoản`);
      setTitle("");
      setMessage("");
      setRecipients([]);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể gửi thông báo")),
  });

  const testMailMutation = useMutation({
    mutationFn: sendTestEmail,
    onSuccess: (result) => toast.success(`${result.message}: ${result.recipient}`),
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể gửi email thử")),
  });

  const toggleRecipient = (id: string) => {
    setRecipients((current) =>
      current.includes(id) ? current.filter((item) => item !== id) : [...current, id],
    );
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Gửi thông báo" description="Gửi thông báo tới toàn bộ hệ thống hoặc các thành viên được chọn." />
      <Card className="max-w-3xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MailCheck className="size-5 text-emerald-700" />
            Trạng thái gửi email
          </CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-sm">
            <p className={mailStatusQuery.data?.configured ? "font-medium text-emerald-700" : "font-medium text-amber-700"}>
              {mailStatusQuery.isLoading ? "Đang kiểm tra cấu hình..." : mailStatusQuery.data?.message || "Không đọc được cấu hình email"}
            </p>
            {mailStatusQuery.data && (
              <p className="mt-1 text-xs text-muted-foreground">
                {mailStatusQuery.data.host}:{mailStatusQuery.data.port} · {mailStatusQuery.data.maskedSender || "chưa có người gửi"}
              </p>
            )}
          </div>
          <Button
            type="button"
            variant="outline"
            disabled={!mailStatusQuery.data?.configured || testMailMutation.isPending}
            onClick={() => testMailMutation.mutate()}
          >
            <MailCheck />
            {testMailMutation.isPending ? "Đang gửi..." : "Gửi email thử cho tôi"}
          </Button>
        </CardContent>
      </Card>
      <Card className="max-w-3xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BellRing className="size-5 text-emerald-700" />
            Soạn thông báo
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="space-y-2">
            <Label htmlFor="notification-title">Tiêu đề</Label>
            <Input
              id="notification-title"
              maxLength={180}
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Ví dụ: Thay đổi giờ chốt cơm"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="notification-message">Nội dung</Label>
            <textarea
              id="notification-message"
              maxLength={800}
              rows={5}
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              className="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm outline-none focus:border-emerald-500"
              placeholder="Nhập nội dung người dùng sẽ nhận..."
            />
            <p className="text-right text-xs text-muted-foreground">{message.length}/800</p>
          </div>
          <label className="flex items-center gap-3 rounded-xl border p-3">
            <input
              type="checkbox"
              checked={sendToAll}
              onChange={(event) => setSendToAll(event.target.checked)}
              className="size-4 accent-emerald-700"
            />
            <span>
              <span className="block font-medium">Gửi tới tất cả tài khoản đang hoạt động</span>
              <span className="block text-xs text-muted-foreground">Bỏ chọn để chọn người nhận cụ thể.</span>
            </span>
          </label>

          {!sendToAll && (
            <div className="max-h-64 space-y-2 overflow-y-auto rounded-xl border p-3">
              {users.map((user) => (
                <label key={user.id} className="flex items-center gap-3 rounded-lg p-2 hover:bg-slate-50">
                  <input
                    type="checkbox"
                    checked={recipients.includes(user.id)}
                    onChange={() => toggleRecipient(user.id)}
                    className="size-4 accent-emerald-700"
                  />
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-medium">{user.fullName || user.email}</span>
                    <span className="block truncate text-xs text-muted-foreground">{user.email}</span>
                  </span>
                </label>
              ))}
            </div>
          )}

          <Button
            className="w-full"
            disabled={
              mutation.isPending ||
              !title.trim() ||
              !message.trim() ||
              (!sendToAll && recipients.length === 0)
            }
            onClick={() =>
              mutation.mutate({
                title: title.trim(),
                message: message.trim(),
                sendToAll,
                recipientUserIds: recipients,
              })
            }
          >
            <Send />
            {mutation.isPending ? "Đang gửi..." : "Gửi thông báo"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
