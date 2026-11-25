import { Component, type ReactNode } from "react";
import { AlertCircle, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";

type Props = { title: string; children: ReactNode };
type State = { hasError: boolean };

/** Keeps one broken dashboard card (unexpected data shape, render bug) from blanking the whole page. */
export default class SectionBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: unknown) {
    console.error(`Dashboard section "${this.props.title}" failed`, error);
  }

  render() {
    if (!this.state.hasError) return this.props.children;
    return (
      <div role="alert" className="flex min-h-28 flex-wrap items-center justify-between gap-3 rounded-2xl border border-destructive/30 bg-destructive/5 p-4 text-sm">
        <span className="flex items-center gap-2 text-destructive">
          <AlertCircle className="size-4" />
          Không hiển thị được mục “{this.props.title}”.
        </span>
        <Button size="sm" variant="outline" onClick={() => this.setState({ hasError: false })}>
          <RotateCw className="size-3.5" />
          Thử lại
        </Button>
      </div>
    );
  }
}
