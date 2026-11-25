import { createContext, useCallback, useContext, useEffect, useRef, useState, type KeyboardEvent, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

export type ConfirmOptions = {
  /** Nói rõ việc sắp xảy ra, ví dụ "Xóa bữa ăn?" */
  title: string;
  /** Nêu tên mục và điều sẽ mất / được giữ. */
  description?: ReactNode;
  confirmText?: string;
  cancelText?: string;
  /** Hành động phá hủy: nút đỏ, focus đầu tiên nằm ở nút Hủy. */
  destructive?: boolean;
};

export type ConfirmFn = (options: ConfirmOptions) => Promise<boolean>;

type PendingConfirm = ConfirmOptions & { resolve: (value: boolean) => void };

const ConfirmContext = createContext<ConfirmFn | null>(null);

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [pending, setPending] = useState<PendingConfirm | null>(null);
  const [open, setOpen] = useState(false);
  const pendingRef = useRef<PendingConfirm | null>(null);
  const confirmRef = useRef<HTMLButtonElement>(null);
  const cancelRef = useRef<HTMLButtonElement>(null);

  const settle = useCallback((value: boolean) => {
    const current = pendingRef.current;
    pendingRef.current = null;
    setOpen(false);
    current?.resolve(value);
  }, []);

  const confirm = useCallback<ConfirmFn>((options) => {
    return new Promise<boolean>((resolve) => {
      // Một hộp thoại mới thay hộp đang mở: hộp cũ coi như bị hủy.
      pendingRef.current?.resolve(false);
      const next = { ...options, resolve };
      pendingRef.current = next;
      setPending(next);
      setOpen(true);
    });
  }, []);

  // Không để promise treo nếu provider bị gỡ.
  useEffect(() => () => pendingRef.current?.resolve(false), []);

  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== "Enter" || event.repeat || event.nativeEvent.isComposing) return;
    event.preventDefault();
    settle(true);
  };

  const destructive = pending?.destructive ?? false;

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      <Dialog open={open} onOpenChange={(next) => { if (!next) settle(false); }}>
        {pending && (
          <DialogContent
            role="alertdialog"
            showCloseButton={false}
            onKeyDown={onKeyDown}
            onOpenAutoFocus={(event) => {
              event.preventDefault();
              (destructive ? cancelRef : confirmRef).current?.focus();
            }}
          >
            <DialogHeader>
              <DialogTitle className="text-lg font-semibold leading-snug">{pending.title}</DialogTitle>
              {pending.description ? (
                <DialogDescription className="leading-relaxed">{pending.description}</DialogDescription>
              ) : (
                <DialogDescription className="sr-only">{pending.title}</DialogDescription>
              )}
            </DialogHeader>
            <DialogFooter>
              <Button ref={cancelRef} type="button" variant="outline" onClick={() => settle(false)}>
                {pending.cancelText ?? "Hủy"}
              </Button>
              <Button
                ref={confirmRef}
                type="button"
                className={destructive ? "bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-600/30" : undefined}
                onClick={() => settle(true)}
              >
                {pending.confirmText ?? "Xác nhận"}
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </ConfirmContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useConfirm(): ConfirmFn {
  const confirm = useContext(ConfirmContext);
  if (confirm) return confirm;
  return missingProvider;
}

function missingProvider(): Promise<boolean> {
  return Promise.reject(new Error("useConfirm cần được bọc trong <ConfirmProvider>."));
}
