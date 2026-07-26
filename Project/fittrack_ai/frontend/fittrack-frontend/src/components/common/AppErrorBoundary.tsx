import { Component, type ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";

type Props = {
  children: ReactNode;
};

type State = {
  hasError: boolean;
};

export default class AppErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  render() {
    if (!this.state.hasError) {
      return this.props.children;
    }

    return (
      <main className="grid min-h-screen place-items-center bg-background p-5">
        <section className="w-full max-w-md rounded-3xl border bg-card p-7 text-center shadow-xl">
          <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-amber-100 text-amber-700">
            <AlertTriangle className="size-6" />
          </span>
          <h1 className="mt-5 text-xl font-semibold tracking-tight">Không thể hiển thị màn hình này</h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            Dữ liệu của bạn vẫn an toàn. Hãy tải lại để khôi phục phiên làm việc.
          </p>
          <Button className="mt-6 w-full" onClick={() => window.location.reload()}>
            <RefreshCw className="size-4" />
            Tải lại ứng dụng
          </Button>
        </section>
      </main>
    );
  }
}
