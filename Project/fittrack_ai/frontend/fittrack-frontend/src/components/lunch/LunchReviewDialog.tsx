import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { MessageSquareText, Star } from "lucide-react";
import { toast } from "sonner";

import { reviewLunchDish, type LunchMenuItem, type LunchOrder } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { getApiErrorMessage } from "@/lib/format";
import { resolveApiAssetUrl } from "@/api/axios";

type Props = {
  order: LunchOrder | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
};

export default function LunchReviewDialog({ order, open, onOpenChange, onSaved }: Props) {
  const initialItem = order?.items[0] ?? null;
  const initialReview = initialItem
    ? order?.reviews?.find((entry) => entry.menuItemId === initialItem.id)
    : null;
  const [selectedItem, setSelectedItem] = useState<LunchMenuItem | null>(initialItem);
  const [rating, setRating] = useState(initialReview?.rating ?? 5);
  const [comment, setComment] = useState(initialReview?.comment ?? "");

  const mutation = useMutation({
    mutationFn: () =>
      reviewLunchDish(order!.id, {
        menuItemId: selectedItem!.id,
        rating,
        comment,
      }),
    onSuccess: () => {
      toast.success("Đã lưu đánh giá món ăn.");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu đánh giá.")),
  });

  const chooseItem = (item: LunchMenuItem) => {
    setSelectedItem(item);
    const review = order?.reviews?.find((entry) => entry.menuItemId === item.id);
    setRating(review?.rating ?? 5);
    setComment(review?.comment ?? "");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <MessageSquareText className="size-5 text-amber-500" />
            Đánh giá món đã ăn
          </DialogTitle>
          <DialogDescription>Mỗi món trong phần ăn có thể được chấm điểm và nhận xét riêng.</DialogDescription>
        </DialogHeader>

        {order && (
          <div className="space-y-4">
            <div className="grid gap-2 sm:grid-cols-2">
              {order.items.filter(
                (item, index, items) => items.findIndex((candidate) => candidate.id === item.id) === index,
              ).map((item) => (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => chooseItem(item)}
                  className={cn(
                    "flex items-center gap-2 rounded-xl border p-2 text-left",
                    selectedItem?.id === item.id ? "border-emerald-400 bg-emerald-50" : "hover:bg-slate-50",
                  )}
                >
                  {item.imageUrl && (
                    <img
                      src={resolveApiAssetUrl(item.imageUrl)}
                      alt=""
                      className="size-11 shrink-0 rounded-lg object-cover"
                    />
                  )}
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-semibold">{item.name}</span>
                    <span className="text-xs text-muted-foreground">
                      {order.reviews?.some((review) => review.menuItemId === item.id) ? "Đã đánh giá" : "Chưa đánh giá"}
                    </span>
                  </span>
                </button>
              ))}
            </div>

            {selectedItem && (
              <>
                <div>
                  <p className="mb-2 text-sm font-semibold">Điểm cho {selectedItem.name}</p>
                  <div className="flex gap-1">
                    {[1, 2, 3, 4, 5].map((value) => (
                      <button
                        key={value}
                        type="button"
                        onClick={() => setRating(value)}
                        className="rounded-lg p-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400"
                        aria-label={`${value} sao`}
                        aria-pressed={rating === value}
                      >
                        <Star
                          className={cn(
                            "size-7",
                            value <= rating ? "fill-amber-400 text-amber-400" : "text-slate-300",
                          )}
                        />
                      </button>
                    ))}
                  </div>
                </div>

                <textarea
                  value={comment}
                  maxLength={1000}
                  onChange={(event) => setComment(event.target.value)}
                  placeholder="Món ăn hôm nay thế nào?"
                  className="min-h-28 w-full resize-y rounded-xl border border-input bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-ring"
                />
              </>
            )}
          </div>
        )}

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Đóng
          </Button>
          <Button
            onClick={() => mutation.mutate()}
            disabled={!order || !selectedItem || mutation.isPending}
          >
            {mutation.isPending ? "Đang lưu..." : "Lưu đánh giá"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
