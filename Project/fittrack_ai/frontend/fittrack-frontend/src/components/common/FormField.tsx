import type { ReactNode } from "react";
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

export default function FormField({
  label,
  htmlFor,
  unit,
  hint,
  required,
  children,
  className = "",
}: FormFieldProps) {
  return (
    <div className={`space-y-2 ${className}`}>
      <div className="flex items-baseline justify-between gap-3">
        <Label htmlFor={htmlFor} className="font-semibold text-slate-800">
          {label}
          {required && <span className="ml-1 text-red-500">*</span>}
        </Label>
        {unit && (
          <span className="rounded-md bg-slate-100 px-1.5 py-0.5 text-[11px] font-medium text-slate-600">
            {unit}
          </span>
        )}
      </div>
      {children}
      {hint && <p className="text-xs leading-5 text-muted-foreground">{hint}</p>}
    </div>
  );
}
