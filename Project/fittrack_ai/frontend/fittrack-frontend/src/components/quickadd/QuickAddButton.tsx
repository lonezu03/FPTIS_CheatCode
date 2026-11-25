import { useEffect, useState } from "react";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/store/auth.store";
import { QuickAddDialog } from "./QuickAddDialog";
import { allowedQuickAddTabs, isQuickAddShortcut } from "./quick-add-config";

/** Header button "Ghi nhanh" (Alt+N). Renders nothing when the user has no quick-add module. */
export function QuickAddButton({ className }: { className?: string }) {
  const user = useAuthStore((state) => state.user);
  const enabled = allowedQuickAddTabs(user).length > 0;
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!enabled) return;
    const onKey = (event: KeyboardEvent) => {
      if (!isQuickAddShortcut(event)) return;
      event.preventDefault();
      setOpen(true);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [enabled]);

  if (!enabled) return null;

  return (
    <>
      <Button type="button" size="sm" className={cn("gap-1.5", className)} onClick={() => setOpen(true)}
        title="Ghi nhanh (Alt+N)" aria-keyshortcuts="Alt+N">
        <Plus className="size-4" />
        <span className="hidden sm:inline">Ghi nhanh</span>
        <span className="sr-only sm:hidden">Ghi nhanh</span>
        <kbd className="ml-1 hidden rounded border border-white/30 px-1 text-[0.65rem] font-medium opacity-80 lg:inline">Alt N</kbd>
      </Button>
      <QuickAddDialog open={open} onOpenChange={setOpen} />
    </>
  );
}

export default QuickAddButton;
