import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { ShieldCheck } from "lucide-react";
import { changePasswordApi } from "../api/auth.api";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import FormField from "@/components/common/FormField";

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (newPassword.length < 8 || newPassword.length > 72) {
      setError("Mật khẩu mới phải từ 8 đến 72 ký tự.");
      return;
    }
    if (newPassword !== confirmation) {
      setError("Mật khẩu xác nhận chưa khớp.");
      return;
    }
    try {
      setSubmitting(true);
      setError("");
      const session = await changePasswordApi(currentPassword, newPassword);
      useAuthStore.getState().setSession(session.token, session);
      navigate("/dashboard", { replace: true });
    } catch (requestError) {
      const message = axios.isAxiosError(requestError) ? requestError.response?.data?.message : undefined;
      setError(message || "Không thể đổi mật khẩu.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="grid min-h-screen place-items-center bg-[#f5f7f3] p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="mb-3 grid size-12 place-items-center rounded-2xl bg-emerald-100 text-emerald-700">
            <ShieldCheck className="size-6" />
          </div>
          <CardTitle className="text-2xl">Đổi mật khẩu để tiếp tục</CardTitle>
          <p className="text-sm text-muted-foreground">
            Tài khoản đang dùng mật khẩu tạm hoặc mật khẩu cũ. Hãy đặt mật khẩu riêng trước khi sử dụng hệ thống.
          </p>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={submit}>
            <FormField label="Mật khẩu hiện tại" htmlFor="current-password" required>
              <Input id="current-password" type="password" autoComplete="current-password" value={currentPassword} onChange={(event) => setCurrentPassword(event.target.value)} />
            </FormField>
            <FormField label="Mật khẩu mới" htmlFor="new-password" hint="Từ 8 đến 72 ký tự." required>
              <Input id="new-password" type="password" autoComplete="new-password" value={newPassword} onChange={(event) => setNewPassword(event.target.value)} />
            </FormField>
            <FormField label="Nhập lại mật khẩu mới" htmlFor="password-confirmation" required>
              <Input id="password-confirmation" type="password" autoComplete="new-password" value={confirmation} onChange={(event) => setConfirmation(event.target.value)} />
            </FormField>
            {error && <p role="alert" className="rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</p>}
            <Button className="w-full" disabled={submitting}>
              {submitting ? "Đang cập nhật..." : "Đổi mật khẩu"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
