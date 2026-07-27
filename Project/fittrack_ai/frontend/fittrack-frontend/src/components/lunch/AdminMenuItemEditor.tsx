import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ImagePlus, Pencil, UtensilsCrossed } from "lucide-react";
import { toast } from "sonner";

import { lunchKeys, updateLunchMenuItem, type LunchMenu, type LunchMenuItem } from "@/api/lunch.api";
import ImagePreviewDialog from "@/components/common/ImagePreviewDialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getApiErrorMessage } from "@/lib/format";

type Draft = {
  name: string;
  imageUrl: string;
  calories: string;
  protein: string;
  carbs: string;
  fat: string;
};

export default function AdminMenuItemEditor({ menu }: { menu: LunchMenu }) {
  const queryClient = useQueryClient();
  const [item, setItem] = useState<LunchMenuItem | null>(null);
  const [draft, setDraft] = useState<Draft>(emptyDraft());

  const editItem = (selected: LunchMenuItem) => {
    setItem(selected);
    setDraft({
      name: selected.name,
      imageUrl: selected.imageUrl ?? "",
      calories: value(selected.calories),
      protein: value(selected.protein),
      carbs: value(selected.carbs),
      fat: value(selected.fat),
    });
  };

  const mutation = useMutation({
    mutationFn: () =>
      updateLunchMenuItem(item!.id, {
        name: draft.name,
        imageUrl: draft.imageUrl || null,
        calories: numberOrNull(draft.calories),
        protein: numberOrNull(draft.protein),
        carbs: numberOrNull(draft.carbs),
        fat: numberOrNull(draft.fat),
      }),
    onSuccess: () => {
      toast.success("Đã cập nhật ảnh và dinh dưỡng món ăn.");
      setItem(null);
      void queryClient.invalidateQueries({ queryKey: lunchKeys.admin() });
      void queryClient.invalidateQueries({ queryKey: lunchKeys.today() });
      void queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      void queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      void queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      void queryClient.invalidateQueries({ queryKey: ["foods"] });
      void queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      void queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      void queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể cập nhật món ăn.")),
  });

  const allItems = [...menu.regularItems, ...menu.specialItems];

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ImagePlus className="size-5 text-emerald-700" />
            Ảnh và dinh dưỡng từng món
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            {allItems.map((menuItem) => (
              <div key={menuItem.id} className="flex items-center gap-3 rounded-xl border p-2.5">
                <ImagePreviewDialog
                  src={menuItem.imageUrl}
                  alt={menuItem.name}
                  className="size-14 shrink-0"
                />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold">{menuItem.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {menuItem.calories != null ? `${Math.round(menuItem.calories)} kcal` : "Chưa có dinh dưỡng"}
                  </p>
                </div>
                <Button variant="outline" size="icon" onClick={() => editItem(menuItem)} aria-label={`Sửa ${menuItem.name}`}>
                  <Pencil className="size-4" />
                </Button>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <Dialog open={!!item} onOpenChange={(open) => !open && setItem(null)}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>Cập nhật món ăn</DialogTitle>
            <DialogDescription>
              Dinh dưỡng của món đã chọn sẽ tự cộng vào dashboard fitness của người đặt.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <Field label="Tên món" htmlFor="dish-name">
              <Input id="dish-name" value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
            </Field>
            <Field label="URL ảnh hoặc chọn file" htmlFor="dish-image">
              <div className="space-y-2">
                <Input
                  id="dish-image"
                  value={draft.imageUrl.startsWith("data:") ? "" : draft.imageUrl}
                  placeholder="https://... hoặc chọn ảnh bên dưới"
                  onChange={(event) => setDraft({ ...draft, imageUrl: event.target.value })}
                />
                <Input
                  type="file"
                  accept="image/png,image/jpeg,image/webp,image/gif,image/avif"
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (!file) return;
                    if (!["image/png", "image/jpeg", "image/webp", "image/gif", "image/avif"].includes(file.type)) {
                      toast.error("Chỉ hỗ trợ PNG, JPEG, WebP, GIF hoặc AVIF.");
                      return;
                    }
                    if (file.size > 1_000_000) {
                      toast.error("Ảnh tối đa 1 MB.");
                      return;
                    }
                    const reader = new FileReader();
                    reader.onload = () => setDraft((current) => ({ ...current, imageUrl: String(reader.result) }));
                    reader.readAsDataURL(file);
                  }}
                />
                {draft.imageUrl && (
                  <div className="flex items-center gap-3">
                    <ImagePreviewDialog src={draft.imageUrl} alt={draft.name || "Món ăn"} className="h-24 w-32" />
                    <Button variant="outline" size="sm" onClick={() => setDraft({ ...draft, imageUrl: "" })}>
                      Xóa ảnh
                    </Button>
                  </div>
                )}
              </div>
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <MacroInput label="Calories (kcal)" value={draft.calories} onChange={(calories) => setDraft({ ...draft, calories })} />
              <MacroInput label="Protein (g)" value={draft.protein} onChange={(protein) => setDraft({ ...draft, protein })} />
              <MacroInput label="Carbs (g)" value={draft.carbs} onChange={(carbs) => setDraft({ ...draft, carbs })} />
              <MacroInput label="Fat (g)" value={draft.fat} onChange={(fat) => setDraft({ ...draft, fat })} />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setItem(null)}>Hủy</Button>
            <Button onClick={() => mutation.mutate()} disabled={!draft.name.trim() || mutation.isPending}>
              <UtensilsCrossed className="size-4" />
              {mutation.isPending ? "Đang lưu..." : "Lưu món"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

function Field({ label, htmlFor, children }: { label: string; htmlFor: string; children: React.ReactNode }) {
  return <div className="space-y-2"><Label htmlFor={htmlFor}>{label}</Label>{children}</div>;
}

function MacroInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="space-y-1.5 text-sm font-medium">
      <span>{label}</span>
      <Input type="number" min={0} step={0.1} value={value} onChange={(event) => onChange(event.target.value)} />
    </label>
  );
}

function emptyDraft(): Draft {
  return { name: "", imageUrl: "", calories: "", protein: "", carbs: "", fat: "" };
}

function value(input?: number | null) {
  return input == null ? "" : String(input);
}

function numberOrNull(input: string) {
  return input.trim() === "" ? null : Number(input);
}
