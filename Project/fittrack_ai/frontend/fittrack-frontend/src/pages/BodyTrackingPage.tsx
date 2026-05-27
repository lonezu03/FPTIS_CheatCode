import { useEffect, useState } from "react";
import { createBodyMeasurement, deleteBodyMeasurement, getBodyMeasurements, type BodyMeasurement } from "../api/body.api";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export default function BodyTrackingPage() {
  const [items, setItems] = useState<BodyMeasurement[]>([]);
  const [weight, setWeight] = useState(60);
  const [waist, setWaist] = useState(78);
  const [chest, setChest] = useState(90);
  const [arm, setArm] = useState(30);
  const [thigh, setThigh] = useState(52);

  const today = new Date().toISOString().slice(0, 10);

  const load = async () => {
    setItems(await getBodyMeasurements());
  };

  useEffect(() => {
    load();
  }, []);

  const handleCreate = async () => {
    try {
      await createBodyMeasurement({
        weight,
        waist,
        chest,
        arm,
        thigh,
        recordDate: today,
      });

      toast.success("Body measurement saved");
      await load();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot save body measurement");
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Delete this measurement?")) {
      return;
    }

    try {
      await deleteBodyMeasurement(id);
      toast.success("Measurement deleted");
      await load();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot delete measurement");
    }
  };

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

            <Button className="w-full" onClick={handleCreate}>
              Save Measurement
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
                  <TableCell>
                    <Button variant="destructive" size="sm" onClick={() => handleDelete(item.id)}>
                      Delete
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
