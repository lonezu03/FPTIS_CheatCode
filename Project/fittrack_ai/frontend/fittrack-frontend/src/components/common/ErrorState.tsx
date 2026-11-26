import { AlertCircle, RotateCw } from "lucide-react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";

type ErrorStateProps = {
  title?: string;
  message?: string;
  /** Hiển thị nút thử lại khi có hàm này. */
  onRetry?: () => void;
  retryLabel?: string;
  /** Vô hiệu nút thử lại khi đang tải lại. */
  retrying?: boolean;
  className?: string;
};

export default function ErrorState({
  title = "Something went wrong",
  message = "Please try again later.",
  onRetry,
  retryLabel = "Thử lại",
  retrying = false,
  className,
}: ErrorStateProps) {
  return (
    <Alert variant="destructive" className={className}>
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>{title}</AlertTitle>
      <AlertDescription>
        <p>{message}</p>
        {onRetry && (
          <Button type="button" size="sm" variant="outline" disabled={retrying} onClick={onRetry}>
            <RotateCw className={`size-4 ${retrying ? "animate-spin" : ""}`} />
            {retryLabel}
          </Button>
        )}
      </AlertDescription>
    </Alert>
  );
}
