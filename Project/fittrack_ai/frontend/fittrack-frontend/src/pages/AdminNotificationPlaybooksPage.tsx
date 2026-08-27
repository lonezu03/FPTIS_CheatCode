import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BellRing, Pencil, Plus, Shuffle, Trash2, Users, X } from "lucide-react";
import { toast } from "sonner";

import {
  createNotificationPlaybook,
  deleteNotificationPlaybook,
  getNotificationPlaybooks,
  updateNotificationPlaybook,
  type NotificationPlaybook,
  type NotificationPlaybookPayload,
} from "@/api/notification-playbook.api";
import { getAdminUsers } from "@/api/admin-user.api";
import { getApiErrorMessage } from "@/lib/format";
import PageHeader from "@/components/PageHeader";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const days = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"] as const;
const dayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
type RecipientMode = "ALL_ACTIVE" | "SELECTED";

export default function AdminNotificationPlaybooksPage() {
  const client = useQueryClient();
  const playbooksQuery = useQuery({ queryKey: ["notification-playbooks"], queryFn: getNotificationPlaybooks });
  const usersQuery = useQuery({ queryKey: ["admin-users-notification"], queryFn: () => getAdminUsers() });
  const [name, setName] = useState("");
  const [category, setCategory] = useState<NotificationPlaybook["category"]>("WELLNESS");
  const [mode, setMode] = useState<NotificationPlaybook["mode"]>("RANDOM");
  const [triggerTime, setTriggerTime] = useState("21:30");
  const [selectedDays, setSelectedDays] = useState<string[]>([...days]);
  const [messages, setMessages] = useState("Chúc bạn ngủ ngon và phục hồi thật tốt.\nHôm nay bạn đã cố gắng rất nhiều, nghỉ ngơi nhé.");
  const [conditionType, setConditionType] = useState<NotificationPlaybook["conditionType"]>("ANY");
  const [threshold, setThreshold] = useState("");
  const [recipientMode, setRecipientMode] = useState<RecipientMode>("ALL_ACTIVE");
  const [recipientUserIds, setRecipientUserIds] = useState<string[]>([]);
  const [enabled, setEnabled] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);

  const invalidate = () => void client.invalidateQueries({ queryKey: ["notification-playbooks"] });
  const add = useMutation({
    mutationFn: createNotificationPlaybook,
    onSuccess: () => {
      resetForm();
      invalidate();
      toast.success("Đã tạo kịch bản notification");
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể tạo kịch bản")),
  });
  const save = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: NotificationPlaybookPayload }) => updateNotificationPlaybook(id, payload),
    onSuccess: () => {
      setEditingId(null);
      invalidate();
      toast.success("Đã cập nhật kịch bản");
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể cập nhật kịch bản")),
  });
  const remove = useMutation({
    mutationFn: deleteNotificationPlaybook,
    onSuccess: () => {
      invalidate();
      toast.success("Đã xóa kịch bản");
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể xóa kịch bản")),
  });
  const toggle = useMutation({
    mutationFn: ({ item, enabled }: { item: NotificationPlaybook; enabled: boolean }) =>
      updateNotificationPlaybook(item.id, toPayload(item, { enabled })),
    onSuccess: invalidate,
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể cập nhật kịch bản")),
  });

  const users = usersQuery.data ?? [];
  const selectedCount = recipientMode === "ALL_ACTIVE" ? users.filter((user) => user.active).length : recipientUserIds.length;
  const createDisabled = !name.trim() || !messages.trim() || selectedDays.length === 0 || (recipientMode === "SELECTED" && recipientUserIds.length === 0) || add.isPending || save.isPending;

  const toggleRecipient = (id: string) => {
    setRecipientUserIds((current) => current.includes(id) ? current.filter((value) => value !== id) : [...current, id]);
  };

  const createPayload: NotificationPlaybookPayload = {
    name: name.trim(),
    category,
    mode,
    triggerTime,
    daysOfWeek: selectedDays.join(","),
    messages,
    conditionType,
    threshold: threshold ? Number(threshold) : null,
    recipientMode,
    recipientUserIds,
    enabled,
  };

  const beginEdit = (item: NotificationPlaybook) => {
    setEditingId(item.id);
    setName(item.name);
    setCategory(item.category);
    setMode(item.mode);
    setTriggerTime(item.triggerTime.slice(0, 5));
    setSelectedDays(item.daysOfWeek.split(",").filter(Boolean));
    setMessages(item.messages);
    setConditionType(item.conditionType);
    setThreshold(item.threshold == null ? "" : String(item.threshold));
    setRecipientMode(item.recipientMode);
    setRecipientUserIds(item.recipientUserIds);
    setEnabled(item.enabled);
  };

  const resetForm = () => {
    setEditingId(null);
    setName("");
    setCategory("WELLNESS");
    setMode("RANDOM");
    setTriggerTime("21:30");
    setSelectedDays([...days]);
    setMessages("Chúc bạn ngủ ngon và phục hồi thật tốt.\\nHôm nay bạn đã cố gắng rất nhiều, nghỉ ngơi nhé.");
    setConditionType("ANY");
    setThreshold("");
    setRecipientMode("ALL_ACTIVE");
    setRecipientUserIds([]);
    setEnabled(true);
  };

  const submit = () => {
    if (editingId) {
      save.mutate({ id: editingId, payload: createPayload });
    } else {
      add.mutate(createPayload);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Kịch bản notification" description="Thiết lập lời chúc, nhắc nhở và thông điệp theo giờ, điều kiện và nhóm người nhận." />
      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_28rem]">
        <Card>
          <CardHeader><CardTitle className="flex items-center gap-2"><BellRing className="size-5 text-emerald-700" /> Kịch bản đang có</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {playbooksQuery.isLoading ? <p className="py-8 text-center text-sm text-muted-foreground">Đang tải...</p> : playbooksQuery.isError ? <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{getApiErrorMessage(playbooksQuery.error, "Không tải được danh sách kịch bản.")}</div> : (playbooksQuery.data ?? []).length === 0 ? <div className="rounded-2xl border border-dashed p-8 text-center"><p className="font-medium">Chưa có kịch bản nào</p><p className="mt-1 text-sm text-muted-foreground">Tạo lời chúc ngủ ngon hoặc nhắc ăn uống phù hợp ở bên phải.</p></div> : (playbooksQuery.data ?? []).map((item) => (
              <div key={item.id} className="rounded-2xl border p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2"><p className="font-semibold">{item.name}</p><Badge className={item.enabled ? "bg-emerald-100 text-emerald-800" : "bg-slate-100 text-slate-500"}>{item.enabled ? "Đang bật" : "Tạm tắt"}</Badge>{item.mode === "RANDOM" && <Badge variant="secondary"><Shuffle className="mr-1 size-3" /> Random</Badge>}</div>
                    <p className="mt-1 text-sm text-muted-foreground">Mỗi ngày lúc {item.triggerTime.slice(0, 5)} · {conditionLabel(item.conditionType, item.threshold)}</p>
                    <p className="mt-1 flex items-center gap-1 text-xs text-muted-foreground"><Users className="size-3" /> {item.recipientMode === "SELECTED" ? `${item.recipientUserIds.length} user được chọn` : "Tất cả user đang hoạt động"}</p>
                    <p className="mt-2 line-clamp-2 text-sm">{item.messages.split("\n")[0]}</p>
                  </div>
                  <div className="flex shrink-0 items-center gap-1"><button className="rounded-lg p-2 text-muted-foreground hover:bg-emerald-50 hover:text-emerald-700" onClick={() => beginEdit(item)} aria-label="Sửa kịch bản"><Pencil className="size-4" /></button><button className="rounded-lg px-2 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-50" onClick={() => toggle.mutate({ item, enabled: !item.enabled })}>{item.enabled ? "Tắt" : "Bật"}</button><button className="rounded-lg p-2 text-muted-foreground hover:bg-red-50 hover:text-red-600" onClick={() => remove.mutate(item.id)} aria-label="Xóa kịch bản"><Trash2 className="size-4" /></button></div>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card className="h-fit border-emerald-200 bg-gradient-to-b from-emerald-50/80 to-background">
          <CardHeader><CardTitle className="flex items-center gap-2">{editingId ? <Pencil className="size-5 text-emerald-700" /> : <Plus className="size-5 text-emerald-700" />} {editingId ? "Chỉnh sửa kịch bản" : "Tạo kịch bản"}</CardTitle>{editingId && <Button variant="ghost" size="sm" onClick={resetForm}><X className="size-4" /> Hủy sửa</Button>}</CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5"><Label>Tên kịch bản</Label><Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: Chúc ngủ ngon" /></div>
            <div className="grid grid-cols-2 gap-3"><FieldSelect label="Nhóm" value={category} onChange={(value) => setCategory(value as NotificationPlaybook["category"])} options={[["WELLNESS", "Wellness"], ["MEAL", "Ăn uống"], ["SLEEP", "Giấc ngủ"], ["PRODUCTIVITY", "Hiệu suất"]]} /><FieldSelect label="Cách chọn câu" value={mode} onChange={(value) => setMode(value as NotificationPlaybook["mode"])} options={[["RANDOM", "Random"], ["FIXED", "Câu đầu tiên"]]} /></div>
            <div className="space-y-1.5"><Label>Giờ gửi</Label><Input type="time" value={triggerTime} onChange={(event) => setTriggerTime(event.target.value)} /></div>
            <div className="space-y-1.5"><Label>Ngày trong tuần</Label><div className="grid grid-cols-7 gap-1">{days.map((day, index) => <button type="button" key={day} onClick={() => setSelectedDays((current) => current.includes(day) ? current.filter((value) => value !== day) : [...current, day])} className={`rounded-lg py-2 text-xs font-semibold ${selectedDays.includes(day) ? "bg-emerald-700 text-white" : "bg-muted text-muted-foreground"}`}>{dayLabels[index]}</button>)}</div></div>
            <FieldSelect label="Điều kiện theo thống kê" value={conditionType} onChange={(value) => setConditionType(value as NotificationPlaybook["conditionType"])} options={[["ANY", "Luôn gửi"], ["NO_MEAL", "Chưa ghi bữa nào"], ["MEALS_LT", "Số bữa ít hơn ngưỡng"], ["PROTEIN_GT", "Đạm vượt ngưỡng (g)"]]} />
            {conditionType !== "ANY" && conditionType !== "NO_MEAL" && <div className="space-y-1.5"><Label>Ngưỡng</Label><Input type="number" min={0} value={threshold} onChange={(event) => setThreshold(event.target.value)} placeholder="Ví dụ: 2 hoặc 180" /></div>}
            <div className="space-y-1.5"><Label>Người nhận</Label><select value={recipientMode} onChange={(event) => setRecipientMode(event.target.value as RecipientMode)} className="h-10 w-full rounded-lg border border-input bg-background px-2 text-sm"><option value="ALL_ACTIVE">Tất cả user đang hoạt động</option><option value="SELECTED">Chỉ user được chọn</option></select><p className="text-xs text-muted-foreground">Đang chọn {selectedCount} người nhận. Dùng nhóm cụ thể để tránh làm phiền toàn bộ công ty.</p></div>
            {recipientMode === "SELECTED" && <div className="max-h-44 space-y-2 overflow-y-auto rounded-xl border bg-background p-3">{usersQuery.isLoading ? <p className="text-sm text-muted-foreground">Đang tải user...</p> : users.map((user) => <label key={user.id} className="flex items-center gap-2 text-sm"><input type="checkbox" checked={recipientUserIds.includes(user.id)} onChange={() => toggleRecipient(user.id)} className="size-4 accent-emerald-700" /> <span className="min-w-0 truncate">{user.fullName || user.email}</span>{!user.active && <span className="text-xs text-muted-foreground">(đã khóa)</span>}</label>)}</div>}
            <div className="space-y-1.5"><Label>Các câu thông báo (mỗi câu một dòng)</Label><textarea value={messages} onChange={(event) => setMessages(event.target.value)} rows={5} className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm" /></div>
            <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={enabled} onChange={(event) => setEnabled(event.target.checked)} className="size-4 accent-emerald-700" /> Kịch bản đang bật</label>
            <Button className="w-full" disabled={createDisabled} onClick={submit}>{add.isPending || save.isPending ? "Đang lưu..." : editingId ? "Lưu thay đổi" : "Lưu kịch bản"}</Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function FieldSelect({ label, value, onChange, options }: { label: string; value: string; onChange: (value: string) => void; options: string[][] }) {
  return <div className="space-y-1.5"><Label>{label}</Label><select value={value} onChange={(event) => onChange(event.target.value)} className="h-10 w-full rounded-lg border border-input bg-background px-2 text-sm">{options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue}>{optionLabel}</option>)}</select></div>;
}

function toPayload(item: NotificationPlaybook, override: Partial<NotificationPlaybookPayload> = {}): NotificationPlaybookPayload {
  return { name: item.name, category: item.category, mode: item.mode, triggerTime: item.triggerTime, daysOfWeek: item.daysOfWeek, messages: item.messages, conditionType: item.conditionType, threshold: item.threshold, recipientMode: item.recipientMode, recipientUserIds: item.recipientUserIds, enabled: item.enabled, ...override };
}

function conditionLabel(type: NotificationPlaybook["conditionType"], threshold: number | null) {
  return type === "ANY" ? "mọi ngày" : type === "NO_MEAL" ? "chưa ghi bữa" : type === "MEALS_LT" ? `dưới ${threshold ?? 0} bữa` : `đạm trên ${threshold ?? 0}g`;
}
