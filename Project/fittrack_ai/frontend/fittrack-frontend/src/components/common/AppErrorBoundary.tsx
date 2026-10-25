import { Component, type ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";

type Props = {
  children: ReactNode;
  contained?: boolean;
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
      <main className={`grid ${this.props.contained ? 'min-h-[50dvh]' : 'min-h-screen'} place-items-center bg-background p-5`}>
        <section className="w-full max-w-md rounded-3xl border bg-card p-7 text-center shadow-xl">
          <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-amber-100 text-amber-700">
            <AlertTriangle className="size-6" />
          </span>
          <h1 className="mt-5 text-xl font-semibold tracking-tight">Không thể hiển thị màn hình này</h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            Không thể hiển thị nội dung. Bạn có thể thử lại hoặc chuyển sang mục khác.
          </p>
          <Button className="mt-6 w-full" onClick={() => this.props.contained ? this.setState({ hasError: false }) : window.location.reload()}>
            <RefreshCw className="size-4" />
            {this.props.contained ? 'Thử lại' : 'Tải lại ứng dụng'}
          </Button>
        </section>
      </main>
    );
  }
}
