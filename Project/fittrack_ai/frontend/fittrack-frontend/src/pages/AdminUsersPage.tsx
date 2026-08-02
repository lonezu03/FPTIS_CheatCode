import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertCircle, KeyRound, Search, ShieldCheck, UserCog, UsersRound } from "lucide-react";
import { toast } from "sonner";
import {
  getAdminUsersPage,
  resetAdminUserPassword,
  updateAdminUser,
  type AdminUser,
} from "@/api/admin-user.api";
import { useAuthStore } from "@/store/auth.store";
import { getApiErrorMessage } from "@/lib/format";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/common/EmptyState";
import TableLoading from "@/components/common/TableLoading";
import DataPagination from "@/components/common/DataPagination";
import { useServerPagination } from "@/hooks/useServerPagination";
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type UserAccessPayload = {
  fullName: string;
  role: "USER" | "ADMIN";
  active: boolean;
  lunchEnabled: boolean;
  fitnessEnabled: boolean;
  healthEnabled: boolean;
  chatbotEnabled: boolean;
};

export default function AdminUsersPage() {
  const queryClient = useQueryClient();
  const currentUserId = useAuthStore((state) => state.user?.userId);
  const [searchInput, setSearchInput] = useState("");
  const [keyword, setKeyword] = useState("");
  const [editingUser, setEditingUser] = useState<AdminUser | null>(null);
  const [resetUser, setResetUser] = useState<AdminUser | null>(null);
  const userPager = useServerPagination(20);

  const usersQuery = useQuery({
    queryKey: ["admin-users", keyword, userPager.page, userPager.pageSize],
    queryFn: () => getAdminUsersPage(keyword, userPager.page - 1, userPager.pageSize),
    placeholderData: (previous) => previous,
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      payload,
    }: {
      id: string;
      payload: UserAccessPayload;
    }) => updateAdminUser(id, payload),
    onSuccess: () => {
      toast.success("Đã cập nhật tài khoản");
      setEditingUser(null);
      void queryClient.invalidateQueries({ queryKey: ["admin-users"] });
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, "Không thể cập nhật tài khoản"));
    },
  });

  const resetMutation = useMutation({
    mutationFn: ({ id, password }: { id: string; password: string }) =>
      resetAdminUserPassword(id, password),
    onSuccess: () => {
      toast.success("Đã đặt lại mật khẩu");
      setResetUser(null);
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, "Không thể đặt lại mật khẩu"));
    },
  });

  const users = usersQuery.data?.content ?? [];
  const userPagination = {
    ...userPager,
    paginatedItems: users,
    totalItems: usersQuery.data?.totalElements ?? 0,
    totalPages: Math.max(1, usersQuery.data?.totalPages ?? 1),
  };
  const activeUsers = users.filter((user) => user.active).length;
  const admins = users.filter((user) => user.role === "ADMIN" && user.active).length;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Quản lý tài khoản"
        description="Cấp quyền admin, khóa hoặc mở tài khoản và đặt lại mật khẩu. Chỉ quản trị viên truy cập được khu vực này."
      />

      <div className="grid gap-3 sm:grid-cols-3">
        <MetricCard label="Tài khoản hiển thị" value={users.length} icon={UsersRound} />
        <MetricCard label="Đang hoạt động" value={activeUsers} icon={ShieldCheck} />
        <MetricCard label="Admin hoạt động" value={admins} icon={UserCog} />
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <CardTitle>Danh sách tài khoản</CardTitle>
            <form
              className="flex w-full gap-2 sm:max-w-md"
              onSubmit={(event) => {
                event.preventDefault();
                userPager.resetPage();
                setKeyword(searchInput.trim());
              }}
            >
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                placeholder="Tìm theo tên hoặc email"
              />
              <Button type="submit" variant="outline">
                <Search />
                Tìm
              </Button>
            </form>
          </div>
        </CardHeader>
        <CardContent>
          {usersQuery.isLoading ? (
            <TableLoading />
          ) : usersQuery.isError ? (
            <Alert variant="destructive">
              <AlertCircle />
              <AlertTitle>Không tải được tài khoản</AlertTitle>
              <AlertDescription>
                {getApiErrorMessage(usersQuery.error, "Vui lòng thử lại.")}
              </AlertDescription>
            </Alert>
          ) : users.length === 0 ? (
            <EmptyState
              title="Không tìm thấy tài khoản"
              description="Thử thay đổi từ khóa tìm kiếm."
            />
          ) : (
            <>
              <div className="hidden md:block">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Thành viên</TableHead>
                      <TableHead>Vai trò</TableHead>
                      <TableHead>Trạng thái</TableHead>
                      <TableHead>Ngày tạo</TableHead>
                      <TableHead className="text-right">Thao tác</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {userPagination.paginatedItems.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell>
                          <p className="font-medium">{user.fullName || "Chưa cập nhật tên"}</p>
                          <p className="text-xs text-muted-foreground">{user.email}</p>
                        </TableCell>
                        <TableCell>
                          <RoleBadge role={user.role} />
                        </TableCell>
                        <TableCell>
                          <StatusBadge active={user.active} />
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {formatDate(user.createdAt)}
                        </TableCell>
                        <TableCell>
                          <div className="flex justify-end gap-2">
                            <Button size="sm" variant="outline" onClick={() => setEditingUser(user)}>
                              <UserCog />
                              Sửa
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => setResetUser(user)}>
                              <KeyRound />
                              Mật khẩu
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              <div className="grid gap-3 md:hidden">
                {userPagination.paginatedItems.map((user) => (
                  <Card key={user.id} size="sm">
                    <CardContent className="space-y-3">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <h3 className="truncate font-semibold">
                            {user.fullName || "Chưa cập nhật tên"}
                          </h3>
                          <p className="truncate text-xs text-muted-foreground">{user.email}</p>
                        </div>
                        <StatusBadge active={user.active} />
                      </div>
                      <div className="flex items-center justify-between">
                        <RoleBadge role={user.role} />
                        <span className="text-xs text-muted-foreground">{formatDate(user.createdAt)}</span>
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <Button variant="outline" onClick={() => setEditingUser(user)}>
                          <UserCog />
                          Chỉnh sửa
                        </Button>
                        <Button variant="outline" onClick={() => setResetUser(user)}>
                          <KeyRound />
                          Mật khẩu
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
              <DataPagination
                page={userPagination.page}
                pageSize={userPagination.pageSize}
                totalItems={userPagination.totalItems}
                totalPages={userPagination.totalPages}
                onPageChange={userPagination.setPage}
                onPageSizeChange={userPagination.setPageSize}
              />
            </>
          )}
        </CardContent>
      </Card>

      {editingUser && (
        <EditUserDialog
          key={editingUser.id}
          user={editingUser}
          currentUserId={currentUserId}
          pending={updateMutation.isPending}
          onClose={() => setEditingUser(null)}
          onSave={(payload) =>
            updateMutation.mutate({ id: editingUser.id, payload })
          }
        />
      )}
      {resetUser && (
        <ResetPasswordDialog
          key={resetUser.id}
          user={resetUser}
          pending={resetMutation.isPending}
          onClose={() => setResetUser(null)}
          onSave={(password) =>
            resetMutation.mutate({ id: resetUser.id, password })
          }
        />
      )}
    </div>
  );
}

function EditUserDialog({
  user,
  currentUserId,
  pending,
  onClose,
  onSave,
}: {
  user: AdminUser;
  currentUserId?: string;
  pending: boolean;
  onClose: () => void;
  onSave: (payload: UserAccessPayload) => void;
}) {
  const [fullName, setFullName] = useState(user.fullName ?? "");
  const [role, setRole] = useState<"USER" | "ADMIN">(user.role);
  const [active, setActive] = useState(user.active);
  const [lunchEnabled, setLunchEnabled] = useState(user.lunchEnabled);
  const [fitnessEnabled, setFitnessEnabled] = useState(user.fitnessEnabled);
  const [healthEnabled, setHealthEnabled] = useState(user.healthEnabled);
  const [chatbotEnabled, setChatbotEnabled] = useState(user.chatbotEnabled);

  const isSelf = user.id === currentUserId;

  return (
    <Dialog open onOpenChange={(value) => !value && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Chỉnh sửa tài khoản</DialogTitle>
          <DialogDescription>{user.email}</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="admin-user-name">Họ tên</Label>
            <Input
              id="admin-user-name"
              value={fullName}
              onChange={(event) => setFullName(event.target.value)}
              maxLength={255}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="admin-user-role">Vai trò</Label>
            <select
              id="admin-user-role"
              value={role}
              onChange={(event) => setRole(event.target.value as "USER" | "ADMIN")}
              disabled={isSelf}
              className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"
            >
              <option value="USER">Người dùng</option>
              <option value="ADMIN">Quản trị viên</option>
            </select>
          </div>
          <label className="flex items-center justify-between gap-3 rounded-xl border p-3">
            <span>
              <span className="block font-medium">Cho phép đăng nhập</span>
              <span className="block text-xs text-muted-foreground">
                Tài khoản bị khóa sẽ mất quyền truy cập ngay ở lần gọi API tiếp theo.
              </span>
            </span>
            <input
              type="checkbox"
              checked={active}
              onChange={(event) => setActive(event.target.checked)}
              disabled={isSelf}
              className="size-5 accent-emerald-700"
            />
          </label>
          <div className="space-y-2 rounded-xl border p-3">
            <p className="font-medium">Quyền sử dụng chức năng</p>
            <PermissionToggle label="Đặt cơm" checked={lunchEnabled} onChange={setLunchEnabled} />
            <PermissionToggle label="Fitness" checked={fitnessEnabled} onChange={setFitnessEnabled} />
            <PermissionToggle label="Chăm sóc sức khỏe" checked={healthEnabled} onChange={setHealthEnabled} />
            <PermissionToggle label="Trợ lý AI" checked={chatbotEnabled} onChange={setChatbotEnabled} />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={pending}>
            Hủy
          </Button>
          <Button
            onClick={() =>
              onSave({
                fullName: fullName.trim(),
                role,
                active,
                lunchEnabled,
                fitnessEnabled,
                healthEnabled,
                chatbotEnabled,
              })
            }
            disabled={pending || !fullName.trim()}
          >
            {pending ? "Đang lưu..." : "Lưu thay đổi"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function ResetPasswordDialog({
  user,
  pending,
  onClose,
  onSave,
}: {
  user: AdminUser;
  pending: boolean;
  onClose: () => void;
  onSave: (password: string) => void;
}) {
  const [password, setPassword] = useState("");

  return (
    <Dialog open onOpenChange={(value) => !value && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Đặt lại mật khẩu</DialogTitle>
          <DialogDescription>
            Đặt mật khẩu mới cho {user.fullName || user.email}. Không gửi mật khẩu qua kênh công khai.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-1.5">
          <Label htmlFor="admin-reset-password">Mật khẩu mới</Label>
          <Input
            id="admin-reset-password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            minLength={8}
            maxLength={72}
            autoComplete="new-password"
          />
          <p className="text-xs text-muted-foreground">Từ 8 đến 72 ký tự.</p>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={pending}>
            Hủy
          </Button>
          <Button onClick={() => onSave(password)} disabled={pending || password.length < 8}>
            {pending ? "Đang cập nhật..." : "Đặt lại mật khẩu"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function PermissionToggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label className="flex items-center justify-between gap-3 rounded-lg bg-slate-50 px-3 py-2 text-sm">
      <span>{label}</span>
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
        className="size-4 accent-emerald-700"
      />
    </label>
  );
}

function MetricCard({
  label,
  value,
  icon: Icon,
}: {
  label: string;
  value: number;
  icon: typeof UsersRound;
}) {
  return (
    <Card size="sm">
      <CardContent className="flex items-center gap-3">
        <span className="grid size-10 place-items-center rounded-xl bg-emerald-100 text-emerald-800">
          <Icon className="size-5" />
        </span>
        <div>
          <p className="text-xs text-muted-foreground">{label}</p>
          <p className="text-xl font-bold">{value}</p>
        </div>
      </CardContent>
    </Card>
  );
}

function RoleBadge({ role }: { role: AdminUser["role"] }) {
  return role === "ADMIN" ? (
    <Badge className="bg-violet-100 text-violet-800">ADMIN</Badge>
  ) : (
    <Badge variant="secondary">USER</Badge>
  );
}

function StatusBadge({ active }: { active: boolean }) {
  return active ? (
    <Badge className="bg-emerald-100 text-emerald-800">Hoạt động</Badge>
  ) : (
    <Badge variant="outline" className="border-red-200 bg-red-50 text-red-700">
      Đã khóa
    </Badge>
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));
}
