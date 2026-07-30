import { useState, type FormEvent } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import { ArrowRight, Check, Dumbbell, Eye, EyeOff, Sparkles, UtensilsCrossed } from "lucide-react";
import { loginApi, registerApi, resendVerificationApi } from "../api/auth.api";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function LoginPage() {
  const [mode, setMode] = useState<"login" | "register">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const setSession = useAuthStore((state) => state.setSession);
  const navigate = useNavigate();

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (isSubmitting) return;

    if (!email.trim() || !password) {
      setError("Vui lòng nhập đầy đủ email và mật khẩu.");
      return;
    }

    if (mode === "register" && (!fullName.trim() || password.length < 8)) {
      setError("Vui lòng nhập họ tên. Mật khẩu đăng ký cần ít nhất 8 ký tự.");
      return;
    }

    try {
      setError("");
      setIsSubmitting(true);

      if (mode === "register") {
        const result = await registerApi({
              email: email.trim(),
              password,
              fullName: fullName.trim(),
              height: 165,
              weight: 60,
              goal: "MAINTAIN",
            });
        setSuccess(result.message);
        setMode("login");
        setPassword("");
        return;
      }

      const data = await loginApi(email.trim(), password);

      setSession(data.token, {
        userId: data.userId,
        email: data.email,
        fullName: data.fullName,
        role: data.role ?? "USER",
        lunchEnabled: data.lunchEnabled,
        fitnessEnabled: data.fitnessEnabled,
        healthEnabled: data.healthEnabled,
        chatbotEnabled: data.chatbotEnabled,
      });
      navigate("/dashboard", { replace: true });
    } catch (requestError) {
      const message = axios.isAxiosError(requestError) ? requestError.response?.data?.message : undefined;
      setError(message || "Không thể đăng nhập. Vui lòng kiểm tra lại thông tin.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const switchMode = () => {
    setMode((current) => (current === "login" ? "register" : "login"));
    setError("");
    setSuccess("");
  };

  const resendVerification = async () => {
    if (!email.trim()) {
      setError("Vui lòng nhập email cần xác thực.");
      return;
    }
    try {
      setIsSubmitting(true);
      await resendVerificationApi(email.trim());
      setError("");
      setSuccess("Nếu tài khoản đang chờ xác thực, email mới đã được gửi.");
    } catch (requestError) {
      const message = axios.isAxiosError(requestError) ? requestError.response?.data?.message : undefined;
      setError(message || "Không thể gửi lại email xác thực.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <main className="relative min-h-screen overflow-hidden bg-[#f5f7f3] p-3 sm:p-5 lg:p-7">
      <div className="pointer-events-none absolute -left-32 top-12 h-80 w-80 rounded-full bg-emerald-200/50 blur-3xl" />
      <div className="pointer-events-none absolute -right-24 bottom-0 h-96 w-96 rounded-full bg-amber-200/50 blur-3xl" />

      <div className="relative mx-auto grid min-h-[calc(100vh-1.5rem)] max-w-7xl overflow-hidden rounded-[2rem] border border-white/70 bg-white shadow-[0_24px_80px_-30px_rgba(15,43,35,0.35)] sm:min-h-[calc(100vh-2.5rem)] lg:grid-cols-[1.08fr_0.92fr]">
        <section className="relative hidden overflow-hidden bg-[#0d2b24] p-10 text-white lg:flex lg:flex-col lg:justify-between xl:p-14">
          <div className="absolute inset-0 opacity-40 [background-image:radial-gradient(circle_at_20%_20%,rgba(52,211,153,.4),transparent_28%),radial-gradient(circle_at_80%_70%,rgba(251,191,36,.3),transparent_30%)]" />
          <div className="absolute -right-20 top-24 h-72 w-72 rounded-full border border-white/10" />
          <div className="absolute -right-2 top-44 h-44 w-44 rounded-full border border-white/10" />

          <div className="relative flex items-center gap-3">
            <div className="grid size-11 place-items-center rounded-2xl bg-emerald-400 text-[#0d2b24] shadow-lg shadow-emerald-950/30">
              <Sparkles className="size-5" />
            </div>
            <div>
              <p className="text-xl font-bold tracking-tight">FitTrack</p>
              <p className="text-xs text-emerald-100/70">Wellness workspace</p>
            </div>
          </div>

          <div className="relative max-w-lg space-y-7">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/10 px-3 py-1.5 text-xs text-emerald-50 backdrop-blur">
              <span className="size-1.5 rounded-full bg-emerald-300" />
              Một nơi cho sức khỏe và nhịp sống công sở
            </div>
            <h1 className="text-4xl font-semibold leading-[1.12] tracking-[-0.035em] xl:text-5xl">
              Tập tốt hơn.
              <br />
              Ăn ngon hơn.
              <br />
              <span className="text-emerald-300">Mỗi ngày.</span>
            </h1>
            <p className="max-w-md text-base leading-7 text-emerald-50/70">
              Theo dõi luyện tập, dinh dưỡng, tiến độ cơ thể và đặt bữa trưa cùng đồng nghiệp trong một trải nghiệm liền mạch.
            </p>

            <div className="grid max-w-md grid-cols-2 gap-3">
              <Feature icon={Dumbbell} label="Luyện tập" detail="Kế hoạch rõ ràng" />
              <Feature icon={UtensilsCrossed} label="Bữa trưa" detail="Đặt món trong vài chạm" />
            </div>
          </div>

          <p className="relative text-xs text-emerald-100/45">FitTrack · Chăm sóc bản thân, cùng nhau</p>
        </section>

        <section className="flex items-center justify-center px-5 py-10 sm:px-10 lg:px-14 xl:px-20">
          <div className="w-full max-w-md">
            <div className="mb-9 flex items-center gap-3 lg:hidden">
              <div className="grid size-10 place-items-center rounded-xl bg-[#0d2b24] text-emerald-300">
                <Sparkles className="size-5" />
              </div>
              <div>
                <p className="font-bold tracking-tight text-[#0d2b24]">FitTrack</p>
                <p className="text-xs text-muted-foreground">Wellness workspace</p>
              </div>
            </div>

            <div className="mb-8">
              <p className="mb-2 text-sm font-semibold text-emerald-700">
                {mode === "login" ? "Chào mừng trở lại" : "Bắt đầu cùng FitTrack"}
              </p>
              <h2 className="text-3xl font-semibold tracking-[-0.035em] text-[#102a24] sm:text-4xl">
                {mode === "login" ? "Đăng nhập tài khoản" : "Tạo tài khoản mới"}
              </h2>
              <p className="mt-3 text-sm leading-6 text-muted-foreground">
                {mode === "login"
                  ? "Tiếp tục hành trình sức khỏe và xem bữa trưa hôm nay."
                  : "Chỉ mất một phút để thiết lập không gian của bạn."}
              </p>
            </div>

            <form className="space-y-5" onSubmit={handleSubmit}>
              {mode === "register" && (
                <div className="space-y-2">
                  <Label htmlFor="full-name">Họ và tên</Label>
                  <Input
                    id="full-name"
                    autoComplete="name"
                    placeholder="Nguyễn Văn An"
                    value={fullName}
                    onChange={(event) => setFullName(event.target.value)}
                  />
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  placeholder="ban@congty.vn"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Mật khẩu</Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    autoComplete={mode === "login" ? "current-password" : "new-password"}
                    placeholder="Ít nhất 6 ký tự"
                    className="pr-11"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                  <button
                    type="button"
                    aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                    className="absolute right-1.5 top-1/2 grid size-8 -translate-y-1/2 place-items-center rounded-lg text-muted-foreground transition hover:bg-muted hover:text-foreground"
                    onClick={() => setShowPassword((visible) => !visible)}
                  >
                    {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
              </div>

              {error && (
                <div role="alert" className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                  {error}
                </div>
              )}
              {success && (
                <div role="status" className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
                  {success}
                </div>
              )}

              {mode === "login" && error.toLowerCase().includes("email") && (
                <Button type="button" variant="outline" className="w-full" onClick={resendVerification} disabled={isSubmitting}>
                  Gửi lại email xác thực
                </Button>
              )}

              {mode === "login" && (
                <div className="text-right">
                  <Link className="text-sm font-medium text-emerald-700 hover:underline" to="/forgot-password">
                    Quên mật khẩu?
                  </Link>
                </div>
              )}

              <Button type="submit" size="lg" className="w-full" disabled={isSubmitting}>
                {isSubmitting ? "Đang xử lý..." : mode === "login" ? "Đăng nhập" : "Tạo tài khoản"}
                {!isSubmitting && <ArrowRight className="ml-1 size-4" />}
              </Button>
            </form>

            <div className="my-7 flex items-center gap-3 text-xs text-muted-foreground">
              <span className="h-px flex-1 bg-border" />
              {mode === "login" ? "Chưa có tài khoản?" : "Đã có tài khoản?"}
              <span className="h-px flex-1 bg-border" />
            </div>

            <Button type="button" variant="outline" size="lg" className="w-full" onClick={switchMode}>
              {mode === "login" ? "Tạo tài khoản miễn phí" : "Quay lại đăng nhập"}
            </Button>

            <p className="mt-8 flex items-center justify-center gap-2 text-center text-xs text-muted-foreground">
              <Check className="size-3.5 text-emerald-600" />
              Dữ liệu của bạn được bảo vệ an toàn
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}

function Feature({
  icon: Icon,
  label,
  detail,
}: {
  icon: typeof Dumbbell;
  label: string;
  detail: string;
}) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.07] p-4 backdrop-blur">
      <Icon className="mb-3 size-5 text-emerald-300" />
      <p className="text-sm font-semibold">{label}</p>
      <p className="mt-0.5 text-xs text-emerald-50/55">{detail}</p>
    </div>
  );
}
