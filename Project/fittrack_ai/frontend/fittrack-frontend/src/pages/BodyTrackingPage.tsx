import { useState } from "react";
import axios from "axios";
import { createBodyMeasurement, deleteBodyMeasurement, getBodyMeasurements, updateBodyMeasurement } from "../api/body.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toLocalDateInput } from "../lib/format";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import DataPagination from "../components/common/DataPagination";
import { usePagination } from "../hooks/usePagination";
import FormField from "../components/common/FormField";

export default function BodyTrackingPage() {
  const queryClient = useQueryClient();
  const today = toLocalDateInput();

  const [recordDate, setRecordDate] = useState(today);
  const [weight, setWeight] = useState(60);
  const [waist, setWaist] = useState(78);
  const [chest, setChest] = useState(90);
  const [arm, setArm] = useState(30);
  const [thigh, setThigh] = useState(52);
  const [editingBody, setEditingBody] = useState<{
    id: string;
    weight: number;
    waist: number;
    chest: number;
    arm: number;
    thigh: number;
    recordDate: string;
  } | null>(null);

  const measurementsQuery = useQuery({
    queryKey: ["body-measurements"],
    queryFn: getBodyMeasurements,
  });

  const items = measurementsQuery.data ?? [];
  const measurementPagination = usePagination(items);

  const createMutation = useMutation({
    mutationFn: createBodyMeasurement,
    onSuccess: () => {
      toast.success("Đã lưu chỉ số");
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể lưu chỉ số");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteBodyMeasurement,
    onSuccess: () => {
      toast.success("Đã xóa chỉ số");
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xóa chỉ số");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: {
      id: string;
      weight: number;
      waist: number;
      chest: number;
      arm: number;
      thigh: number;
      recordDate: string;
    }) =>
      updateBodyMeasurement(payload.id, {
        weight: payload.weight,
        waist: payload.waist,
        chest: payload.chest,
        arm: payload.arm,
        thigh: payload.thigh,
        recordDate: payload.recordDate,
      }),
    onSuccess: () => {
      toast.success("Đã cập nhật chỉ số");
      setEditingBody(null);
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể cập nhật chỉ số");
    },
  });

  const handleCreate = () => {
    createMutation.mutate({
      weight,
      waist,
      chest,
      arm,
      thigh,
      recordDate,
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Bạn có chắc muốn xóa chỉ số này?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  if (measurementsQuery.isLoading) {
    return <TableLoading />;
  }

  if (measurementsQuery.isError) {
    return <ErrorState title="Không thể tải chỉ số cơ thể" message="Vui lòng tải lại trang." />;
  }

  const chartData = [...items].reverse();

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Chỉ số cơ thể" description="Theo dõi cân nặng và các số đo cơ thể theo thời gian." />

      <div className="grid gap-4 md:gap-6 lg:grid-cols-3">
        <Card>
          <CardHeader>
          <CardTitle>Thêm chỉ số</CardTitle>
          </CardHeader>

          <CardContent className="space-y-4">
            <FormField label="Ngày đo" htmlFor="body-record-date" hint="Chọn ngày bạn thực hiện các phép đo này." required>
              <Input id="body-record-date" type="date" value={recordDate} onChange={(event) => setRecordDate(event.target.value)} />
            </FormField>

            <FormField label="Cân nặng" htmlFor="body-weight" unit="kg" hint="Đo vào cùng một thời điểm trong ngày để dễ so sánh." required>
              <Input id="body-weight" type="number" min={20} max={350} step={0.1} value={weight} onChange={(event) => setWeight(Number(event.target.value))} />
            </FormField>

            <FormField label="Vòng eo" htmlFor="body-waist" unit="cm" hint="Đo ngang rốn, thả lỏng bụng và không siết dây." required>
              <Input id="body-waist" type="number" min={30} max={250} step={0.1} value={waist} onChange={(event) => setWaist(Number(event.target.value))} />
            </FormField>

            <FormField label="Vòng ngực" htmlFor="body-chest" unit="cm" hint="Đo quanh phần đầy nhất của ngực, giữ thước song song mặt đất.">
              <Input id="body-chest" type="number" min={30} max={250} step={0.1} value={chest} onChange={(event) => setChest(Number(event.target.value))} />
            </FormField>

            <FormField label="Vòng bắp tay" htmlFor="body-arm" unit="cm" hint="Đo quanh phần lớn nhất của bắp tay khi thả lỏng.">
              <Input id="body-arm" type="number" min={10} max={100} step={0.1} value={arm} onChange={(event) => setArm(Number(event.target.value))} />
            </FormField>

            <FormField label="Vòng đùi" htmlFor="body-thigh" unit="cm" hint="Đo quanh phần lớn nhất của đùi khi đứng thẳng.">
              <Input id="body-thigh" type="number" min={20} max={150} step={0.1} value={thigh} onChange={(event) => setThigh(Number(event.target.value))} />
            </FormField>

            <Button className="w-full" onClick={handleCreate} disabled={createMutation.isPending}>
            {createMutation.isPending ? "Đang lưu..." : "Lưu chỉ số"}
            </Button>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Biểu đồ tiến độ</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[340px]">
            {chartData.length === 0 ? (
              <EmptyState title="Chưa có dữ liệu cơ thể" description="Thêm chỉ số đầu tiên để xem tiến độ." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <XAxis dataKey="recordDate" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="weight" strokeWidth={2} />
                  <Line type="monotone" dataKey="waist" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Lịch sử chỉ số</CardTitle>
        </CardHeader>

        <CardContent>
          {items.length === 0 ? (
            <EmptyState title="Chưa có chỉ số" description="Lưu chỉ số đầu tiên để bắt đầu theo dõi." />
          ) : (
            <div className="w-full overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Ngày</TableHead>
                  <TableHead>Cân nặng</TableHead>
                  <TableHead>Vòng eo</TableHead>
                  <TableHead>Vòng ngực</TableHead>
                  <TableHead>Vòng tay</TableHead>
                  <TableHead>Vòng đùi</TableHead>
                  <TableHead>Thao tác</TableHead>
                </TableRow>
              </TableHeader>

              <TableBody>
                {measurementPagination.paginatedItems.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell>{item.recordDate}</TableCell>
                    <TableCell>{item.weight}kg</TableCell>
                    <TableCell>{item.waist}cm</TableCell>
                    <TableCell>{item.chest}cm</TableCell>
                    <TableCell>{item.arm}cm</TableCell>
                    <TableCell>{item.thigh}cm</TableCell>
                    <TableCell className="space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() =>
                          setEditingBody({
                            id: item.id,
                            weight: item.weight,
                            waist: item.waist,
                            chest: item.chest,
                            arm: item.arm,
                            thigh: item.thigh,
                            recordDate: item.recordDate,
                          })
                        }
                      >
                        Sửa
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleDelete(item.id)}
                        disabled={deleteMutation.isPending}
                      >
                        Xóa
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <DataPagination
              page={measurementPagination.page}
              pageSize={measurementPagination.pageSize}
              totalItems={measurementPagination.totalItems}
              totalPages={measurementPagination.totalPages}
              onPageChange={measurementPagination.setPage}
              onPageSizeChange={measurementPagination.setPageSize}
            />
          </div>
          )}
        </CardContent>
      </Card>

      <Dialog
        open={!!editingBody}
        onOpenChange={(open) => {
          if (!open) {
            setEditingBody(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Sửa chỉ số</DialogTitle>
          </DialogHeader>

          {editingBody && (
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField label="Ngày đo" htmlFor="edit-body-date" className="sm:col-span-2" required>
                <Input id="edit-body-date" type="date" value={editingBody.recordDate} onChange={(event) => setEditingBody({ ...editingBody, recordDate: event.target.value })} />
              </FormField>
              <FormField label="Cân nặng" htmlFor="edit-body-weight" unit="kg" required>
                <Input id="edit-body-weight" type="number" step={0.1} value={editingBody.weight} onChange={(event) => setEditingBody({ ...editingBody, weight: Number(event.target.value) })} />
              </FormField>
              <FormField label="Vòng eo" htmlFor="edit-body-waist" unit="cm" required>
                <Input id="edit-body-waist" type="number" step={0.1} value={editingBody.waist} onChange={(event) => setEditingBody({ ...editingBody, waist: Number(event.target.value) })} />
              </FormField>
              <FormField label="Vòng ngực" htmlFor="edit-body-chest" unit="cm">
                <Input id="edit-body-chest" type="number" step={0.1} value={editingBody.chest} onChange={(event) => setEditingBody({ ...editingBody, chest: Number(event.target.value) })} />
              </FormField>
              <FormField label="Vòng bắp tay" htmlFor="edit-body-arm" unit="cm">
                <Input id="edit-body-arm" type="number" step={0.1} value={editingBody.arm} onChange={(event) => setEditingBody({ ...editingBody, arm: Number(event.target.value) })} />
              </FormField>
              <FormField label="Vòng đùi" htmlFor="edit-body-thigh" unit="cm">
                <Input id="edit-body-thigh" type="number" step={0.1} value={editingBody.thigh} onChange={(event) => setEditingBody({ ...editingBody, thigh: Number(event.target.value) })} />
              </FormField>

              <Button className="w-full sm:col-span-2" onClick={() => updateMutation.mutate(editingBody)} disabled={updateMutation.isPending}>
              {updateMutation.isPending ? "Đang lưu..." : "Lưu thay đổi"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
