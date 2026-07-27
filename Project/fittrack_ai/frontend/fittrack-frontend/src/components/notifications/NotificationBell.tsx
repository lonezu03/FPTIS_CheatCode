import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, CheckCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";

import {
  getLunchNotifications,
  lunchKeys,
  markAllLunchNotificationsRead,
  markLunchNotificationRead,
  type LunchNotification,
} from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { formatDateTime } from "@/lib/format";

export default function NotificationBell({ isAdmin }: { isAdmin: boolean }) {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const query = useQuery({
    queryKey: lunchKeys.notifications(),
    queryFn: getLunchNotifications,
    refetchInterval: 20_000,
    staleTime: 10_000,
  });
  const readMutation = useMutation({
    mutationFn: markLunchNotificationRead,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: lunchKeys.notifications() }),
  });
  const readAllMutation = useMutation({
    mutationFn: markAllLunchNotificationsRead,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: lunchKeys.notifications() }),
  });

  const openNotification = (notification: LunchNotification) => {
    if (!notification.readAt) readMutation.mutate(notification.id);
    void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
    void queryClient.invalidateQueries({ queryKey: lunchKeys.transactions() });
    void queryClient.invalidateQueries({ queryKey: lunchKeys.paymentRequests() });
    setOpen(false);
    navigate(
      isAdmin && notification.type === "PAYMENT_REQUEST"
        ? "/admin/lunch?tab=payments"
        : notification.type.startsWith("PAYMENT_")
          ? "/lunch?tab=payment"
          : "/lunch",
    );
  };

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="relative" aria-label="Thông báo">
          <Bell className="size-5" />
          {(query.data?.unreadCount ?? 0) > 0 && (
            <span className="absolute right-1 top-1 grid min-w-4 place-items-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {Math.min(query.data?.unreadCount ?? 0, 99)}
            </span>
          )}
        </Button>
      </SheetTrigger>
      <SheetContent className="w-full overflow-y-auto sm:max-w-md">
        <SheetHeader>
          <div className="flex items-center justify-between gap-3">
            <SheetTitle>Thông báo</SheetTitle>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => readAllMutation.mutate()}
              disabled={readAllMutation.isPending || !(query.data?.unreadCount)}
            >
              <CheckCheck className="size-4" />
              Đọc tất cả
            </Button>
          </div>
        </SheetHeader>
        <div className="space-y-2 px-4 pb-6">
          {(query.data?.notifications ?? []).length === 0 ? (
            <p className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">
              Chưa có thông báo.
            </p>
          ) : (
            query.data?.notifications.map((notification) => (
              <button
                key={notification.id}
                type="button"
                onClick={() => openNotification(notification)}
                className={[
                  "w-full rounded-xl border p-3 text-left transition hover:bg-slate-50",
                  notification.readAt ? "bg-white" : "border-emerald-200 bg-emerald-50/60",
                ].join(" ")}
              >
                <div className="flex items-start gap-2">
                  {!notification.readAt && <span className="mt-1.5 size-2 shrink-0 rounded-full bg-emerald-500" />}
                  <span>
                    <span className="block text-sm font-semibold">{notification.title}</span>
                    <span className="mt-1 block text-xs leading-5 text-muted-foreground">
                      {notification.message}
                    </span>
                    <span className="mt-1 block text-[11px] text-muted-foreground">
                      {formatDateTime(notification.createdAt)}
                    </span>
                  </span>
                </div>
              </button>
            ))
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}
