import { useState } from "react";
import axios from "axios";
import { createBodyMeasurement, deleteBodyMeasurement, getBodyMeasurements, updateBodyMeasurement } from "../api/body.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

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

export default function BodyTrackingPage() {
  const queryClient = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

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

  const createMutation = useMutation({
    mutationFn: createBodyMeasurement,
    onSuccess: () => {
      toast.success("Measurement saved");
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot save measurement");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteBodyMeasurement,
    onSuccess: () => {
      toast.success("Measurement deleted");
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete measurement");
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
      toast.success("Measurement updated");
      setEditingBody(null);
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update measurement");
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
    if (!window.confirm("Delete this measurement?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  if (measurementsQuery.isLoading) {
    return <TableLoading />;
  }

  if (measurementsQuery.isError) {
    return <ErrorState title="Cannot load body measurements" message="Please try refreshing the page." />;
  }

  const chartData = [...items].reverse();

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Body Tracking" description="Track weight, waist and body measurements over time." />

      <div className="grid gap-4 md:gap-6 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Add Measurement</CardTitle>
          </CardHeader>

          <CardContent className="space-y-3 sm:space-y-4">
            <Input type="date" value={recordDate} onChange={(event) => setRecordDate(event.target.value)} />

            <Input type="number" value={weight} onChange={(event) => setWeight(Number(event.target.value))} placeholder="Weight" />

            <Input type="number" value={waist} onChange={(event) => setWaist(Number(event.target.value))} placeholder="Waist" />

            <Input type="number" value={chest} onChange={(event) => setChest(Number(event.target.value))} placeholder="Chest" />

            <Input type="number" value={arm} onChange={(event) => setArm(Number(event.target.value))} placeholder="Arm" />

            <Input type="number" value={thigh} onChange={(event) => setThigh(Number(event.target.value))} placeholder="Thigh" />

            <Button className="w-full" onClick={handleCreate} disabled={createMutation.isPending}>
              {createMutation.isPending ? "Saving..." : "Save Measurement"}
            </Button>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Progress Chart</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[340px]">
            {chartData.length === 0 ? (
              <EmptyState title="No body data yet" description="Add your first body measurement to see progress." />
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
          <CardTitle>History</CardTitle>
        </CardHeader>

        <CardContent>
          {items.length === 0 ? (
            <EmptyState title="No measurements yet" description="Save your first measurement to start tracking." />
          ) : (
            <div className="w-full overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Weight</TableHead>
                  <TableHead>Waist</TableHead>
                  <TableHead>Chest</TableHead>
                  <TableHead>Arm</TableHead>
                  <TableHead>Thigh</TableHead>
                  <TableHead>Action</TableHead>
                </TableRow>
              </TableHeader>

              <TableBody>
                {items.map((item) => (
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
                        Edit
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleDelete(item.id)}
                        disabled={deleteMutation.isPending}
                      >
                        Delete
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
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
            <DialogTitle>Edit Measurement</DialogTitle>
          </DialogHeader>

          {editingBody && (
            <div className="space-y-3 sm:space-y-4">
              <Input
                type="date"
                value={editingBody.recordDate}
                onChange={(event) => setEditingBody({ ...editingBody, recordDate: event.target.value })}
              />

              <Input
                type="number"
                value={editingBody.weight}
                onChange={(event) => setEditingBody({ ...editingBody, weight: Number(event.target.value) })}
                placeholder="Weight"
              />

              <Input
                type="number"
                value={editingBody.waist}
                onChange={(event) => setEditingBody({ ...editingBody, waist: Number(event.target.value) })}
                placeholder="Waist"
              />

              <Input
                type="number"
                value={editingBody.chest}
                onChange={(event) => setEditingBody({ ...editingBody, chest: Number(event.target.value) })}
                placeholder="Chest"
              />

              <Input
                type="number"
                value={editingBody.arm}
                onChange={(event) => setEditingBody({ ...editingBody, arm: Number(event.target.value) })}
                placeholder="Arm"
              />

              <Input
                type="number"
                value={editingBody.thigh}
                onChange={(event) => setEditingBody({ ...editingBody, thigh: Number(event.target.value) })}
                placeholder="Thigh"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingBody)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
