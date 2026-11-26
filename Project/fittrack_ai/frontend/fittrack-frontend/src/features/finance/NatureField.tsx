import type { ExpenseNature } from "@/api/finance.api";
import { Field } from "./FinanceParts";
import { expenseNatures } from "./finance-utils";

export default function NatureField({ value, onChange }: { value: ExpenseNature; onChange: (value: ExpenseNature) => void }) {
  const selected = expenseNatures.find((item) => item.value === value);
  return (
    <Field label="Tính chất khoản chi" required>
      <select className="field" value={value} onChange={(event) => onChange(event.target.value as ExpenseNature)}>
        {expenseNatures.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
      </select>
      <p className="text-xs leading-5 text-muted-foreground">{selected?.description}</p>
    </Field>
  );
}
