import { useState, type FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { createBodyMeasurement } from "@/api/body.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toLocalDateInput } from "@/lib/format";
import QuickField from "./QuickField";
import { invalidProps } from "./quick-field-styles";
import { hasErrors, parseDecimal, validateBody, type FieldErrors } from "./quick-add-validation";
import { useQuickAddFeedback } from "./use-quick-add-feedback";

type BodyPayload = Parameters<typeof createBodyMeasurement>[0];

export default function BodyQuickForm({ onDone }: { onDone: () => void }) {
  const today = toLocalDateInput();
  const [weight, setWeight] = useState("");
  const [waist, setWaist] = useState("");
  const [recordDate, setRecordDate] = useState(today);
  const [errors, setErrors] = useState<FieldErrors<"weight" | "waist" | "recordDate">>({});
  const { succeed, fail } = useQuickAddFeedback();

  const mutation = useMutation({
    mutationFn: () => {
      // Every measurement column is nullable in the API. Unmeasured values stay
      // null so reports never read them as 0.
      const payload = {
        weight: parseDecimal(weight),
        waist: parseDecimal(waist),
        chest: null,
        arm: null,
        thigh: null,
        recordDate,
      } as unknown as BodyPayload;
      return createBodyMeasurement(payload);
    },
    onSuccess: (measurement) => {
      succeed(`Đã ghi cân nặng ${measurement.weight} kg`, "/body", [
        ["body-measurements"], ["dashboard-progress"], ["weekly-report"], ["weekly-recommendations"], ["achievements"],
      ]);
      onDone();
    },
    onError: (error) => fail(error, "Không ghi được số đo"),
  });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const next = validateBody({ weight, waist, recordDate }, today);
    setErrors(next);
    if (!hasErrors(next)) mutation.mutate();
  };

  return (
    <form className="grid gap-4" onSubmit={submit} noValidate>
      <div className="grid grid-cols-2 gap-3">
        <QuickField id="qa-body-weight" label="Cân nặng (kg)" error={errors.weight}>
          <Input id="qa-body-weight" autoFocus inputMode="decimal" placeholder="65,5" value={weight}
            onChange={(event) => setWeight(event.target.value)} {...invalidProps("qa-body-weight", errors.weight)} />
        </QuickField>
        <QuickField id="qa-body-waist" label="Vòng eo (cm)" error={errors.waist} hint="Không bắt buộc">
          <Input id="qa-body-waist" inputMode="decimal" value={waist}
            onChange={(event) => setWaist(event.target.value)} {...invalidProps("qa-body-waist", errors.waist)} />
        </QuickField>
      </div>
      <QuickField id="qa-body-date" label="Ngày đo" error={errors.recordDate}>
        <Input id="qa-body-date" type="date" max={today} value={recordDate}
          onChange={(event) => setRecordDate(event.target.value)} {...invalidProps("qa-body-date", errors.recordDate)} />
      </QuickField>
      <p className="text-xs text-muted-foreground">Cân vào cùng một thời điểm mỗi ngày để so sánh chính xác hơn.</p>
      <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Đang lưu..." : "Ghi cân nặng"}</Button>
    </form>
  );
}
