import { useCallback } from "react";
import { useQueryClient, type QueryKey } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/format";

/**
 * Success/error feedback for quick-add forms: toast with a link to the module
 * and invalidation of the queries that show the new record.
 */
export function useQuickAddFeedback() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const succeed = useCallback(
    (message: string, path: string, keys: QueryKey[], predicate?: (key: QueryKey) => boolean) => {
      keys.forEach((queryKey) => void queryClient.invalidateQueries({ queryKey }));
      if (predicate) void queryClient.invalidateQueries({ predicate: (query) => predicate(query.queryKey) });
      toast.success(message, { action: { label: "Xem", onClick: () => navigate(path) } });
    },
    [navigate, queryClient],
  );

  const fail = useCallback((error: unknown, fallback: string) => {
    toast.error(getApiErrorMessage(error, fallback));
  }, []);

  return { succeed, fail };
}
