import { AlertTriangle, CheckCircle2 } from "lucide-react";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { MenuEditorState } from "./useMenuEditor";

/** Live preview of how the pasted menu is split into regular, single and extra dishes. */
export default function MenuPreviewCard({ parsedMenu }: { parsedMenu: MenuEditorState["parsedMenu"] }) {
  return (
    <Card className="h-fit xl:sticky xl:top-6">
      <CardHeader>
        <CardTitle>Xem trước cách tách món</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {parsedMenu.errors.length > 0 && (
          <Alert className="border-amber-200 bg-amber-50 text-amber-900">
            <AlertTriangle />
            <AlertTitle>Menu chưa sẵn sàng</AlertTitle>
            <AlertDescription className="text-amber-800">
              <ul className="list-disc space-y-1 pl-4">
                {parsedMenu.errors.map((error) => (
                  <li key={error}>{error}</li>
                ))}
              </ul>
            </AlertDescription>
          </Alert>
        )}

        <MenuPreviewGroup
          title="Cơm phần · chọn đúng 2"
          items={parsedMenu.regularItems}
          tone="regular"
        />
        <MenuPreviewGroup title="Món đơn · chọn 1" items={parsedMenu.specialItems} tone="special" />
        <MenuPreviewGroup title="Món thêm / đồ uống · tính theo giá nhập" items={parsedMenu.extraItems} tone="extra" />

        {parsedMenu.isValid && (
          <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
            <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
            Menu hợp lệ, sẵn sàng nhập.
          </div>
        )}
      </CardContent>
    </Card>
  );
}

const toneClass = {
  regular: "flex items-center gap-2 rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-950",
  special: "flex items-center gap-2 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-950",
  extra: "flex items-center gap-2 rounded-lg bg-sky-50 px-3 py-2 text-sm text-sky-950",
};

function MenuPreviewGroup({
  title,
  items,
  tone,
}: {
  title: string;
  items: string[];
  tone: keyof typeof toneClass;
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between gap-3">
        <h3 className="text-sm font-semibold">{title}</h3>
        <Badge variant="secondary">{items.length} món</Badge>
      </div>
      {items.length === 0 ? (
        <p className="rounded-xl border border-dashed p-3 text-sm text-muted-foreground">Chưa nhận diện được món.</p>
      ) : (
        <ol className="max-h-52 space-y-1.5 overflow-y-auto pr-1">
          {items.map((item, index) => (
            <li key={item} className={toneClass[tone]}>
              <span className="text-xs font-semibold opacity-60">{index + 1}.</span>
              <span className="font-medium">{item}</span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
