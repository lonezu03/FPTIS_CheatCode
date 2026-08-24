import { useEffect, useRef, useState, type FormEvent } from "react";
import axios from "axios";
import { ArrowLeft, CheckCircle2, Mail, ShieldCheck } from "lucide-react";
import { Link, useLocation, useSearchParams } from "react-router-dom";
import {
  forgotPasswordApi,
  resetPasswordApi,
  verifyEmailApi,
} from "@/api/auth.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function AuthRecoveryPage() {
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token") ?? "";
  const mode = location.pathname.includes("verify-email")
    ? "verify"
    : "recovery";
  const startedVerification = useRef(false);

  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [otpRequested, setOtpRequested] = useState(
    location.pathname.includes("reset-password"),
  );
  const [pending, setPending] = useState(mode === "verify" && Boolean(token));
  const [info, setInfo] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState(
    mode === "verify" && !token ? "Liên kết xác thực không hợp lệ." : "",
  );

  useEffect(() => {
    if (mode !== "verify" || startedVerification.current) return;
    startedVerification.current = true;
    if (!token) return;
    verifyEmailApi(token)
      .then(() => setMessage("Email đã được xác thực. Bạn có thể đăng nhập ngay."))
      .catch((requestError) => setError(getMessage(requestError, "Không thể xác thực email.")))
      .finally(() => setPending(false));
  }, [mode, token]);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (pending) return;
    setError("");
    setMessage("");

    if (mode === "recovery" && !email.trim()) {
      setError("Vui lòng nhập email.");
      return;
    }
    if (mode === "recovery" && otpRequested && !/^\d{6}$/.test(otp)) {
      setError("Mã OTP phải gồm đúng 6 chữ số.");
      return;
    }
    if (mode === "recovery" && otpRequested && (password.length < 8 || password !== confirmPassword)) {
      setError("Mật khẩu cần ít nhất 8 ký tự và hai ô phải trùng nhau.");
      return;
    }

    try {
      setPending(true);
      if (!otpRequested) {
        await forgotPasswordApi(email.trim());
        setOtpRequested(true);
        setInfo("Nếu email tồn tại, FitTrack đã gửi mã OTP gồm 6 chữ số. Mã có hiệu lực trong 10 phút.");
      } else {
        await resetPasswordApi(email.trim(), otp, password);
        setMessage("Đã đặt lại mật khẩu. Bạn có thể đăng nhập bằng mật khẩu mới.");
      }
    } catch (requestError) {
      setError(getMessage(requestError, "Không thể xử lý yêu cầu."));
    } finally {
      setPending(false);
    }
  };

  const title =
    mode === "verify"
      ? "Xác thực email"
      : otpRequested
        ? "Nhập OTP và mật khẩu mới"
        : "Quên mật khẩu";

  return (
    <main className="grid min-h-screen place-items-center bg-[#f5f7f3] p-4">
      <section className="w-full max-w-md rounded-3xl border bg-white p-6 shadow-xl shadow-emerald-950/10 sm:p-8">
        <div className="mb-6 grid size-12 place-items-center rounded-2xl bg-emerald-100 text-emerald-800">
          {mode === "recovery" && !otpRequested ? <Mail /> : <ShieldCheck />}
        </div>
        <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          {mode === "verify"
            ? "FitTrack đang kiểm tra liên kết xác thực của bạn."
            : otpRequested
              ? "Nhập đúng email đăng ký và mã OTP đã nhận để tạo mật khẩu mới."
              : "Nhập email đã đăng ký để nhận mã OTP đặt lại mật khẩu."}
        </p>

        {mode !== "verify" && !message && (
          <form className="mt-6 space-y-4" onSubmit={handleSubmit}>
            <div className="space-y-2">
              <Label htmlFor="recovery-email">Email đã đăng ký</Label>
              <Input
                id="recovery-email"
                type="email"
                autoComplete="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </div>
            {otpRequested && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="recovery-otp">Mã OTP</Label>
                  <Input
                    id="recovery-otp"
                    type="text"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    maxLength={6}
                    value={otp}
                    onChange={(event) => setOtp(event.target.value.replace(/\D/g, "").slice(0, 6))}
                    placeholder="000000"
                    className="text-center font-mono text-lg tracking-[0.35em]"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="new-password">Mật khẩu mới</Label>
                  <Input
                    id="new-password"
                    type="password"
                    autoComplete="new-password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirm-password">Nhập lại mật khẩu</Label>
                  <Input
                    id="confirm-password"
                    type="password"
                    autoComplete="new-password"
                    value={confirmPassword}
                    onChange={(event) => setConfirmPassword(event.target.value)}
                  />
                </div>
              </>
            )}
            {info && <p className="rounded-xl bg-blue-50 p-3 text-sm text-blue-800">{info}</p>}
            <Button className="w-full" type="submit" disabled={pending}>
              {pending ? "Đang xử lý..." : otpRequested ? "Xác nhận đổi mật khẩu" : "Gửi mã OTP"}
            </Button>
            {otpRequested && (
              <Button
                className="w-full"
                type="button"
                variant="outline"
                disabled={pending || !email.trim()}
                onClick={async () => {
                  setError("");
                  try {
                    setPending(true);
                    await forgotPasswordApi(email.trim());
                    setInfo("Nếu email tồn tại, một mã OTP mới đã được gửi. Mã cũ không còn hiệu lực.");
                  } catch (requestError) {
                    setError(getMessage(requestError, "Không thể gửi lại mã OTP."));
                  } finally {
                    setPending(false);
                  }
                }}
              >
                Gửi lại mã OTP
              </Button>
            )}
          </form>
        )}

        {pending && mode === "verify" && <p className="mt-6 text-sm">Đang xác thực...</p>}
        {error && <p className="mt-6 rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</p>}
        {message && (
          <div className="mt-6 flex gap-2 rounded-xl bg-emerald-50 p-3 text-sm text-emerald-800">
            <CheckCircle2 className="mt-0.5 size-4 shrink-0" />
            {message}
          </div>
        )}

        <Button asChild variant="ghost" className="mt-6 w-full">
          <Link to="/login">
            <ArrowLeft />
            Quay lại đăng nhập
          </Link>
        </Button>
      </section>
    </main>
  );
}

function getMessage(error: unknown, fallback: string) {
  return axios.isAxiosError(error) ? error.response?.data?.message || fallback : fallback;
}
