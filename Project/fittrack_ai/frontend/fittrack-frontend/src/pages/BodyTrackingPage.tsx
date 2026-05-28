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

export default function BodyTrackingPage() {
  const queryClient = useQueryClient();

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
  } | null>(null);

  const today = new Date().toISOString().slice(0, 10);

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
    }) =>
      updateBodyMeasurement(payload.id, {
        weight: payload.weight,
        waist: payload.waist,
        chest: payload.chest,
        arm: payload.arm,
        thigh: payload.thigh,
      }),
    onSuccess: () => {
      toast.success("Measurement updated");
      setEditingBody(null);
      queryClient.invalidateQueries({ queryKey: ["body-measurements"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
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
      recordDate: today,
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Delete this measurement?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  if (measurementsQuery.isLoading) {
    return <div>Loading body tracking...</div>;
  }

  const chartData = [...items].reverse();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Body Tracking</h1>
        <p className="text-muted-foreground">Track weight, waist and body measurements over time.</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Add Measurement</CardTitle>
          </CardHeader>

          <CardContent className="space-y-4">
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

          <CardContent className="h-[340px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <XAxis dataKey="recordDate" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="weight" strokeWidth={2} />
                <Line type="monotone" dataKey="waist" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>History</CardTitle>
        </CardHeader>

        <CardContent>
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
            <div className="space-y-4">
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
