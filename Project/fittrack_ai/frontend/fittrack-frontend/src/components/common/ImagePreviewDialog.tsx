import { useState } from "react";
import { ImageIcon, Maximize2 } from "lucide-react";

import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { resolveApiAssetUrl } from "@/api/axios";

type Props = {
  src?: string | null;
  alt: string;
  className?: string;
  imageClassName?: string;
};

export default function ImagePreviewDialog({ src, alt, className, imageClassName }: Props) {
  const [open, setOpen] = useState(false);

  if (!src) {
    return (
      <div className={cn("grid place-items-center rounded-xl bg-slate-100 text-slate-400", className)}>
        <ImageIcon className="size-5" />
      </div>
    );
  }
  const resolvedSrc = resolveApiAssetUrl(src);

  return (
    <>
      <button
        type="button"
        className={cn("group relative overflow-hidden rounded-xl bg-slate-100", className)}
        onClick={(event) => {
          event.stopPropagation();
          setOpen(true);
        }}
        aria-label={`Xem ảnh ${alt}`}
      >
        <img src={resolvedSrc} alt={alt} className={cn("h-full w-full object-cover", imageClassName)} />
        <span className="absolute inset-0 grid place-items-center bg-black/0 text-white opacity-0 transition group-hover:bg-black/25 group-hover:opacity-100">
          <Maximize2 className="size-5" />
        </span>
      </button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>{alt}</DialogTitle>
          </DialogHeader>
          <div className="overflow-hidden rounded-2xl bg-slate-100">
            <img src={resolvedSrc} alt={alt} className="max-h-[72vh] w-full object-contain" />
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
