import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuthStore } from "@/store/auth.store";
import BodyQuickForm from "./BodyQuickForm";
import FinanceQuickForm from "./FinanceQuickForm";
import JournalQuickForm from "./JournalQuickForm";
import MealQuickForm from "./MealQuickForm";
import TodoQuickForm from "./TodoQuickForm";
import { allowedQuickAddTabs, type MealType, type QuickAddTab } from "./quick-add-config";

export type QuickAddDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Tab shown when the dialog opens; falls back to the first allowed tab. */
  initialTab?: QuickAddTab;
  initialMealType?: MealType;
};

export function QuickAddDialog({ open, onOpenChange, initialTab, initialMealType }: QuickAddDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Ghi nhanh</DialogTitle>
          <DialogDescription>Lưu ngay, chỉnh chi tiết sau trong từng mục.</DialogDescription>
        </DialogHeader>
        {/* Mounted only while open so every opening starts with a fresh form. */}
        {open && <QuickAddTabs initialTab={initialTab} initialMealType={initialMealType} onDone={() => onOpenChange(false)} />}
      </DialogContent>
    </Dialog>
  );
}

function QuickAddTabs({ initialTab, initialMealType, onDone }: { initialTab?: QuickAddTab; initialMealType?: MealType; onDone: () => void }) {
  const user = useAuthStore((state) => state.user);
  const tabs = allowedQuickAddTabs(user);
  const [tab, setTab] = useState<QuickAddTab | undefined>(() =>
    tabs.some((item) => item.id === initialTab) ? initialTab : tabs[0]?.id);

  if (!tab) return <p className="text-sm text-muted-foreground">Tài khoản chưa được mở mục nào để ghi nhanh.</p>;

  return (
    <Tabs value={tab} onValueChange={(value) => setTab(value as QuickAddTab)} className="min-w-0 gap-4">
      <TabsList className="w-full justify-start overflow-x-auto">
        {tabs.map((item) => {
          const Icon = item.icon;
          return <TabsTrigger key={item.id} value={item.id} className="flex-none sm:flex-1"><Icon />{item.label}</TabsTrigger>;
        })}
      </TabsList>
      {tabs.map((item) => (
        <TabsContent key={item.id} value={item.id}>
          {item.id === "todo" && <TodoQuickForm onDone={onDone} />}
          {item.id === "meal" && <MealQuickForm onDone={onDone} initialMealType={initialMealType} />}
          {item.id === "finance" && <FinanceQuickForm onDone={onDone} />}
          {item.id === "body" && <BodyQuickForm onDone={onDone} />}
          {item.id === "journal" && <JournalQuickForm onDone={onDone} />}
        </TabsContent>
      ))}
    </Tabs>
  );
}
