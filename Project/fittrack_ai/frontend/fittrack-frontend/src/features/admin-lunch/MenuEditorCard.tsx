import { AlertTriangle, Pencil, Upload } from "lucide-react";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { formatCurrency } from "@/lib/format";
import { Field } from "./AdminLunchParts";
import type { MenuEditorState } from "./useMenuEditor";

/** Import a new menu, or replace a menu that has no orders yet. */
export default function MenuEditorCard({ editor, saving, onSubmit }: {
  editor: MenuEditorState;
  saving: boolean;
  onSubmit: () => void;
}) {
  const { editingMenuId, parsedMenu } = editor;
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {editingMenuId ? <Pencil className="h-5 w-5" aria-hidden="true" /> : <Upload className="h-5 w-5" aria-hidden="true" />}
          {editingMenuId ? "Sửa menu đã import" : "Nhập menu mới"}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {editingMenuId && (
          <Alert className="border-amber-200 bg-amber-50 text-amber-900">
            <AlertTriangle />
            <AlertTitle>Bạn đang thay thế toàn bộ danh sách món</AlertTitle>
            <AlertDescription>
              Chỉ có thể lưu khi menu chưa phát sinh phần ăn. Sau khi có đơn, hãy dùng phần sửa từng món bên dưới để bảo toàn lịch sử.
            </AlertDescription>
          </Alert>
        )}
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Ngày bán" htmlFor="lunch-menu-date">
            <Input
              id="lunch-menu-date"
              type="date"
              value={editor.menuDate}
              onChange={(event) => editor.changeMenuDate(event.target.value)}
            />
          </Field>
          <Field label="Giờ chốt" htmlFor="lunch-cutoff">
            <Input
              id="lunch-cutoff"
              type="datetime-local"
              value={editor.cutoffAt}
              onChange={(event) => editor.setCutoffAt(event.target.value)}
            />
          </Field>
          <Field label="Tên người gom đơn" htmlFor="lunch-order-label">
            <Input
              id="lunch-order-label"
              value={editor.orderLabel}
              onChange={(event) => editor.setOrderLabel(event.target.value)}
              maxLength={120}
              placeholder="Ví dụ: Vũ"
            />
          </Field>
          <Field label="Tên quán" htmlFor="lunch-vendor-name">
            <Input
              id="lunch-vendor-name"
              value={editor.vendorName}
              onChange={(event) => editor.setVendorName(event.target.value)}
              maxLength={120}
              placeholder="Quán cơm..."
            />
          </Field>
          <Field label="Giá mỗi phần" htmlFor="lunch-price">
            <Input
              id="lunch-price"
              type="number"
              min={1_000}
              step={1_000}
              value={editor.price}
              onChange={(event) => editor.setPrice(Number(event.target.value))}
            />
          </Field>
          <div className="flex items-end">
            <div className="w-full rounded-lg bg-slate-50 px-3 py-2 text-sm">
              <span className="text-muted-foreground">Hiển thị: </span>
              <strong>{formatCurrency(editor.price)}</strong>
            </div>
          </div>
        </div>

        <Field label="Danh sách món quán gửi" htmlFor="raw-lunch-menu">
          <textarea
            id="raw-lunch-menu"
            value={editor.rawMenuText}
            onChange={(event) => editor.setRawMenuText(event.target.value)}
            rows={13}
            maxLength={5_000}
            placeholder={"Lòng gà roty\nTôm ram\nSườn ram\nThịt kho\n+\nPhở bò"}
            className="w-full resize-y rounded-lg border border-input bg-background px-3 py-2 font-mono text-sm leading-6 outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
          />
        </Field>

        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">
            Mỗi dòng là một món. Dùng “+” cho món đơn; dùng “@DRINKS” hoặc “@EXTRAS” rồi nhập “Trà đào | 45000” để thêm món có giá riêng.
          </p>
          <div className="flex gap-2 self-end sm:self-auto">
            {editingMenuId && (
              <Button type="button" variant="outline" onClick={editor.reset} disabled={saving}>
                Hủy sửa
              </Button>
            )}
            <Button
              type="button"
              onClick={onSubmit}
              disabled={saving || !parsedMenu.isValid}
            >
              {editingMenuId ? <Pencil aria-hidden="true" /> : <Upload aria-hidden="true" />}
              {saving ? "Đang lưu..." : editingMenuId ? "Lưu menu đã sửa" : "Nhập & mở menu"}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
