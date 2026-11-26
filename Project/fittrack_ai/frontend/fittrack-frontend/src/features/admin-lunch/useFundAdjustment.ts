import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import { adjustLunchFund, lunchKeys, type LunchFundAdjustmentAction } from "@/api/lunch.api";
import { getApiErrorMessage } from "@/lib/format";
import { fundSuccessMessage, validateFundAdjustment } from "./admin-lunch-utils";

/** Manual fund/debt adjustment form. Kept at page level so values survive tab switches. */
export function useFundAdjustment() {
  const queryClient = useQueryClient();
  const [selectedMemberId, setSelectedMemberId] = useState("");
  const [amount, setAmount] = useState(100_000);
  const [action, setAction] = useState<LunchFundAdjustmentAction>("ADD_FUND");
  const [note, setNote] = useState("");

  const mutation = useMutation({
    mutationFn: adjustLunchFund,
    onSuccess: () => {
      toast.success(fundSuccessMessage(action));
      setNote("");
      void queryClient.invalidateQueries({ queryKey: lunchKeys.adminMembers() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.transactions() });
    },
    onError: (error: unknown) => {
      toast.error(getApiErrorMessage(error, "Không thể nạp quỹ."));
    },
  });

  function submit() {
    const error = validateFundAdjustment(selectedMemberId, amount);
    if (error) {
      toast.error(error);
      return;
    }
    mutation.mutate({
      userId: selectedMemberId,
      amount,
      action,
      note: note.trim(),
    });
  }

  return {
    selectedMemberId,
    amount,
    action,
    note,
    setSelectedMemberId,
    setAmount,
    setAction,
    setNote,
    pending: mutation.isPending,
    submit,
  };
}

export type FundAdjustmentState = ReturnType<typeof useFundAdjustment>;
