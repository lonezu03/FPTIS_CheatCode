import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

/** Nhắc tiếp tục buổi tập chưa lưu trên thiết bị. */
export default function RecoverableDraftCard({ title, onResume, onDiscard }: { title: string; onResume: () => void; onDiscard: () => void }) {
  return (
    <Card>
      <CardContent className="space-y-3 p-4">
        <p className="font-semibold">Bạn có buổi tập chưa lưu</p>
        <p className="text-sm text-muted-foreground">{title}. Bản nháp giữ trên thiết bị này tối đa 7 ngày và chưa được ghi vào lịch sử.</p>
        <div className="flex flex-wrap gap-2">
          <Button onClick={onResume}>Tiếp tục buổi tập</Button>
          <Button variant="outline" onClick={onDiscard}>Bỏ bản nháp</Button>
        </div>
      </CardContent>
    </Card>
  );
}
