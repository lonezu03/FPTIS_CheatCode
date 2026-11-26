import type { ReactNode } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

/** Form dialog shared by the account, category, budget and recurring editors. */
export default function SimpleDialog({
  formId,
  title,
  description,
  submit,
  pending,
  disabled,
  onOpenChange,
  onSubmit,
  children,
  wide = false,
}: {
  formId: string;
  title: string;
  description?: string;
  submit: string;
  pending: boolean;
  disabled: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: () => void;
  children: ReactNode;
  wide?: boolean;
}) {
  return (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent className={`max-h-[90vh] overflow-y-auto ${wide ? "sm:max-w-2xl" : "sm:max-w-xl"}`}>
        <DialogHeader><DialogTitle>{title}</DialogTitle>{description ? <DialogDescription>{description}</DialogDescription> : <DialogDescription className="sr-only">{title}</DialogDescription>}</DialogHeader>
        <form id={formId} className="space-y-4" onSubmit={(event) => { event.preventDefault(); onSubmit(); }}>{children}</form>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button type="submit" form={formId} disabled={pending || disabled}>{pending ? "Đang lưu..." : submit}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
