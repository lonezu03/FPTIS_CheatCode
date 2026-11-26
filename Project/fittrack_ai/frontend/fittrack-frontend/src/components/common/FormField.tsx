import { Children, cloneElement, isValidElement, useId, type ReactElement, type ReactNode } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type FormFieldProps = {
  label: string;
  htmlFor?: string;
  unit?: string;
  hint?: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
};

type ControlProps = { id?: string; "aria-describedby"?: string; "aria-required"?: boolean | "true" | "false" };

/** Ô nhập gốc hoặc Input của ui: an toàn để gắn id và mô tả mà không đổi giao diện. */
function isLabelableControl(node: ReactNode): node is ReactElement<ControlProps> {
  if (!isValidElement(node)) return false;
  return node.type === "input" || node.type === "select" || node.type === "textarea" || node.type === Input;
}

export default function FormField({
  label,
  htmlFor,
  unit,
  hint,
  required,
  children,
  className = "",
}: FormFieldProps) {
  const autoId = useId();
  const hintId = `${autoId}-hint`;

  // Khi chỉ có một ô nhập, tự nối nhãn và hướng dẫn với ô đó để trình đọc màn hình đọc đúng tên trường.
  const only = Children.count(children) === 1 ? Children.toArray(children)[0] : null;
  let controlId = htmlFor;
  let content: ReactNode = children;
  if (isLabelableControl(only)) {
    const ownId = only.props.id;
    if (!htmlFor || ownId === htmlFor) {
      controlId = ownId ?? htmlFor ?? autoId;
      const describedBy = [only.props["aria-describedby"], hint ? hintId : undefined].filter(Boolean).join(" ") || undefined;
      content = cloneElement(only, {
        id: controlId,
        "aria-describedby": describedBy,
        ...(required && only.props["aria-required"] === undefined ? { "aria-required": true } : {}),
      });
    }
  }

  return (
    <div className={`space-y-2 ${className}`}>
      <div className="flex items-baseline justify-between gap-3">
        <Label htmlFor={controlId} className="font-semibold text-slate-800">
          {label}
          {required && <span className="ml-1 text-red-500" aria-hidden="true">*</span>}
        </Label>
        {unit && (
          <span className="rounded-md bg-slate-100 px-1.5 py-0.5 text-[11px] font-medium text-slate-600">
            {unit}
          </span>
        )}
      </div>
      {content}
      {hint && <p id={hintId} className="text-xs leading-5 text-muted-foreground">{hint}</p>}
    </div>
  );
}
