import { useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import { loginApi, registerApi } from "../api/auth.api";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function LoginPage() {
  const [mode, setMode] = useState<"login" | "register">("login");
  const [email, setEmail] = useState("test@gmail.com");
  const [password, setPassword] = useState("123456");
  const [fullName, setFullName] = useState("Phan Thanh Vu");
  const [error, setError] = useState("");

  const setToken = useAuthStore((state) => state.setToken);
  const navigate = useNavigate();

  const handleSubmit = async () => {
    try {
      setError("");

      const data =
        mode === "login"
          ? await loginApi(email, password)
          : await registerApi({
              email,
              password,
              fullName,
              height: 160,
              weight: 60,
              goal: "LEAN_BULK",
            });

      setToken(data.token);
      navigate("/dashboard");
    } catch (error) {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      setError(message || "Auth failed");
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-center text-3xl">{mode === "login" ? "Login" : "Register"}</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          {mode === "register" && (
            <Input placeholder="Full name" value={fullName} onChange={(event) => setFullName(event.target.value)} />
          )}

          <Input placeholder="Email" value={email} onChange={(event) => setEmail(event.target.value)} />

          <Input
            placeholder="Password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />

          {error && <p className="text-sm text-red-500">{error}</p>}

          <Button onClick={handleSubmit} className="w-full">
            {mode === "login" ? "Login" : "Register"}
          </Button>

          <Button variant="ghost" className="w-full" onClick={() => setMode(mode === "login" ? "register" : "login")}>
            {mode === "login" ? "Create account" : "Already have account?"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
