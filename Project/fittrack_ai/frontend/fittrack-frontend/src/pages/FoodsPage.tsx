import { type ChangeEvent, useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { resolveApiAssetUrl } from "@/api/axios";

import PageHeader from "../components/PageHeader";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";
import DataPagination from "../components/common/DataPagination";
import { useServerPagination } from "../hooks/useServerPagination";
import FormField from "../components/common/FormField";

import {
  archiveFoodApi,
  createFoodApi,
  getFoodsManagementPageApi,
  reviewFoodApi,
  restoreFoodApi,
  suggestFoodApi,
  updateFoodApi,
  type Food,
  type FoodSourceType,
} from "../api/food.api";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAuthStore } from "@/store/auth.store";

type FoodDraft = {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number | null;
  sugar: number | null;
  sodium: number | null;
  potassium: number | null;
  calcium: number | null;
  iron: number | null;
  vitaminC: number | null;
  water: number | null;
  unit: string;
  servingSizeGrams: number | null;
  dataSourceType: FoodSourceType;
  dataSourceName: string;
  verified: boolean;
  imageUrl: string;
};

const emptyDraft: FoodDraft = {
  name: "",
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  fiber: null,
  sugar: null,
  sodium: null,
  potassium: null,
  calcium: null,
  iron: null,
  vitaminC: null,
  water: null,
  unit: "100g",
  servingSizeGrams: 100,
  dataSourceType: "ESTIMATED",
  dataSourceName: "",
  verified: false,
  imageUrl: "",
};

const sourceLabels: Record<FoodSourceType, string> = {
  VERIFIED_DATABASE: "Cơ sở dữ liệu đã kiểm chứng",
  PRODUCT_LABEL: "Nhãn sản phẩm",
  RECIPE_CALCULATED: "Tính từ công thức",
  COMMUNITY: "Người dùng đóng góp",
  ESTIMATED: "Ước tính",
};

const MAX_IMAGE_FILE_SIZE = 1024 * 1024;

export default function FoodsPage() {
  const queryClient = useQueryClient();
  const isAdmin = useAuthStore((state) => state.user?.role === "ADMIN");

  const [keyword, setKeyword] = useState("");
  const [searchKeyword, setSearchKeyword] = useState("");
  const [includeInactive, setIncludeInactive] = useState(isAdmin);

  const [draft, setDraft] = useState<FoodDraft>({
    name: "Greek Yogurt",
    calories: 59,
    protein: 10,
    carbs: 3.6,
    fat: 0.4,
    fiber: 0,
    sugar: 3.2,
    sodium: 36,
    potassium: 141,
    calcium: 110,
    iron: 0.1,
    vitaminC: 0,
    water: 85,
    unit: "100g",
    servingSizeGrams: 100,
    dataSourceType: "PRODUCT_LABEL",
    dataSourceName: "Nhãn sản phẩm",
    verified: false,
    imageUrl: "",
  });

  const [editingFood, setEditingFood] = useState<Food | null>(null);
  const [previewImage, setPreviewImage] = useState<{ url: string; title: string } | null>(null);
  const foodPager = useServerPagination(20);

  const foodsQuery = useQuery({
    queryKey: ["foods-management", searchKeyword, isAdmin && includeInactive, foodPager.page, foodPager.pageSize],
    queryFn: () => getFoodsManagementPageApi(
      searchKeyword,
      isAdmin && includeInactive,
      foodPager.page - 1,
      foodPager.pageSize,
    ),
    placeholderData: (previous) => previous,
  });

  const foods = foodsQuery.data?.content ?? [];
  const foodPagination = {
    ...foodPager,
    paginatedItems: foods,
    totalItems: foodsQuery.data?.totalElements ?? 0,
    totalPages: Math.max(1, foodsQuery.data?.totalPages ?? 1),
  };

  const createMutation = useMutation({
    mutationFn: isAdmin ? createFoodApi : suggestFoodApi,
    onSuccess: () => {
      toast.success(isAdmin ? "Đã tạo thực phẩm" : "Đã gửi thực phẩm để admin duyệt");
      setDraft(emptyDraft);
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể tạo thực phẩm");
    },
  });

  const reviewMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: "APPROVED" | "REJECTED" }) =>
      reviewFoodApi(id, status),
    onSuccess: () => {
      toast.success("Đã xử lý đề xuất thực phẩm");
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xử lý đề xuất");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: Food) =>
      updateFoodApi(payload.id, {
        name: payload.name,
        calories: payload.calories,
        protein: payload.protein,
        carbs: payload.carbs,
        fat: payload.fat,
        fiber: payload.fiber,
        sugar: payload.sugar,
        sodium: payload.sodium,
        potassium: payload.potassium,
        calcium: payload.calcium,
        iron: payload.iron,
        vitaminC: payload.vitaminC,
        water: payload.water,
        unit: payload.unit,
        servingSizeGrams: payload.servingSizeGrams,
        dataSourceType: payload.dataSourceType,
        dataSourceName: payload.dataSourceName?.trim() ?? "",
        verified: payload.verified,
        imageUrl: payload.imageUrl?.trim() || null,
      }),
    onSuccess: () => {
      toast.success("Đã cập nhật thực phẩm");
      setEditingFood(null);
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể cập nhật thực phẩm");
    },
  });

  const archiveMutation = useMutation({
    mutationFn: archiveFoodApi,
    onSuccess: () => {
      toast.success("Đã lưu trữ thực phẩm");
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể lưu trữ thực phẩm");
    },
  });

  const restoreMutation = useMutation({
    mutationFn: restoreFoodApi,
    onSuccess: () => {
      toast.success("Đã khôi phục thực phẩm");
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể khôi phục thực phẩm");
    },
  });

  const handleCreate = () => {
    if (!draft.name.trim()) {
      toast.error("Vui lòng nhập tên thực phẩm");
      return;
    }

    createMutation.mutate({
      ...draft,
      dataSourceName: draft.dataSourceName.trim() || null,
      verified: isAdmin ? draft.verified : false,
      imageUrl: draft.imageUrl.trim() || null,
    });
  };

  if (foodsQuery.isError) {
    return <ErrorState title="Không thể tải thực phẩm" message="Vui lòng tải lại trang." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Kho thực phẩm" description="Tạo và quản lý dữ liệu thực phẩm dùng trong nhật ký dinh dưỡng." />

      {(
        <Card>
          <CardHeader>
            <CardTitle>{isAdmin ? "Tạo thực phẩm" : "Đề xuất thực phẩm mới"}</CardTitle>
          </CardHeader>

          <CardContent className="grid gap-4 md:grid-cols-3">
            <FormField label="Tên thực phẩm" htmlFor="food-name" hint="Tên món hoặc nguyên liệu dễ nhận biết." required>
              <Input id="food-name" value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} placeholder="Ví dụ: Sữa chua Hy Lạp" />
            </FormField>
            <FormField label="Khẩu phần chuẩn" htmlFor="food-unit" hint="Mọi chỉ số bên dưới được tính cho khẩu phần này." required>
              <Input id="food-unit" value={draft.unit} onChange={(event) => setDraft({ ...draft, unit: event.target.value })} placeholder="Ví dụ: 100g, 1 chén, 1 phần" />
            </FormField>
            <FormField label="Khối lượng một khẩu phần" htmlFor="food-serving-grams" unit="g/ml" hint="Bắt buộc nếu muốn người dùng nhập theo gram hoặc ml.">
              <Input id="food-serving-grams" type="number" min={0.01} step="any" value={draft.servingSizeGrams ?? ""} onChange={(event) => setDraft({ ...draft, servingSizeGrams: event.target.value === "" ? null : Number(event.target.value) })} placeholder="Ví dụ: 100" />
            </FormField>
            <FormField label="Loại nguồn dữ liệu" htmlFor="food-source-type" hint="Giúp đánh giá độ tin cậy của dinh dưỡng.">
              <select id="food-source-type" className="h-10 w-full rounded-md border bg-background px-3 text-sm" value={draft.dataSourceType} onChange={(event) => setDraft({ ...draft, dataSourceType: event.target.value as FoodSourceType })}>
                {Object.entries(sourceLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </FormField>
            <FormField label="Tên nguồn" htmlFor="food-source-name" hint="Ví dụ: nhãn Vinamilk, USDA hoặc công thức nội bộ.">
              <Input id="food-source-name" value={draft.dataSourceName} onChange={(event) => setDraft({ ...draft, dataSourceName: event.target.value })} placeholder="Nguồn tham khảo" />
            </FormField>
            <FormField label="Năng lượng" htmlFor="food-calories" unit="kcal" hint="Tổng năng lượng trong một khẩu phần." required>
              <Input id="food-calories" type="number" min={0} value={draft.calories} onChange={(event) => setDraft({ ...draft, calories: Number(event.target.value) })} />
            </FormField>
            <FormField label="Chất đạm" htmlFor="food-protein" unit="g" required>
              <Input id="food-protein" type="number" min={0} step="any" value={draft.protein} onChange={(event) => setDraft({ ...draft, protein: Number(event.target.value) })} />
            </FormField>
            <FormField label="Tinh bột" htmlFor="food-carbs" unit="g" required>
              <Input id="food-carbs" type="number" min={0} step="any" value={draft.carbs} onChange={(event) => setDraft({ ...draft, carbs: Number(event.target.value) })} />
            </FormField>
            <FormField label="Chất béo" htmlFor="food-fat" unit="g" required>
              <Input id="food-fat" type="number" min={0} step="any" value={draft.fat} onChange={(event) => setDraft({ ...draft, fat: Number(event.target.value) })} />
            </FormField>

            <div className="md:col-span-3">
              <h3 className="font-semibold">Vi chất và thành phần mở rộng</h3>
              <p className="text-xs text-muted-foreground">Để trống nếu chưa biết; chỉ nhập 0 khi nguồn dữ liệu xác nhận thực sự bằng 0.</p>
            </div>

            {([
              ["fiber", "Chất xơ", "g", "Hỗ trợ tiêu hóa và cảm giác no."],
              ["sugar", "Đường", "g", "Tổng lượng đường trong khẩu phần."],
              ["sodium", "Natri", "mg", "Thành phần chính cần theo dõi khi ăn mặn."],
              ["potassium", "Kali", "mg", "Khoáng chất hỗ trợ cơ và tim."],
              ["calcium", "Canxi", "mg", "Khoáng chất hỗ trợ xương và răng."],
              ["iron", "Sắt", "mg", "Khoáng chất tham gia tạo máu."],
              ["vitaminC", "Vitamin C", "mg", "Vitamin hỗ trợ miễn dịch và hấp thu sắt."],
              ["water", "Nước", "ml", "Lượng nước ước tính trong khẩu phần."],
            ] as const).map(([key, label, unit, hint]) => (
              <FormField key={key} label={label} htmlFor={`food-${key}`} unit={unit} hint={hint}>
                <Input
                  id={`food-${key}`}
                  type="number"
                  min={0}
                  step="any"
                  value={draft[key] ?? ""}
                  onChange={(event) => setDraft({ ...draft, [key]: event.target.value === "" ? null : Number(event.target.value) })}
                />
              </FormField>
            ))}

            {isAdmin && (
              <label className="md:col-span-3 flex items-start gap-3 rounded-xl border bg-emerald-50/60 p-4 text-sm">
                <input type="checkbox" className="mt-1" checked={draft.verified} onChange={(event) => setDraft({ ...draft, verified: event.target.checked })} />
                <span><strong>Đã xác minh dữ liệu</strong><br /><span className="text-muted-foreground">Chỉ bật sau khi đã đối chiếu khẩu phần và các chỉ số với nguồn đáng tin cậy.</span></span>
              </label>
            )}

            <div className="md:col-span-3">
              <FoodImageField
                value={draft.imageUrl}
                onChange={(imageUrl) => setDraft({ ...draft, imageUrl })}
                onPreview={() => draft.imageUrl && setPreviewImage({ url: draft.imageUrl, title: draft.name || "Ảnh thực phẩm" })}
              />
            </div>

            <Button className="md:col-span-3" onClick={handleCreate} disabled={createMutation.isPending}>
              {createMutation.isPending ? "Đang gửi..." : isAdmin ? "Tạo thực phẩm" : "Gửi admin duyệt"}
            </Button>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Danh sách thực phẩm</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="flex flex-col gap-3 md:flex-row md:items-center">
            <div className="flex flex-1 gap-2">
              <Input value={keyword} onChange={(event) => setKeyword(event.target.value)} placeholder="Tìm thực phẩm..." />

              <Button onClick={() => { foodPager.resetPage(); setSearchKeyword(keyword); }}>Tìm kiếm</Button>
            </div>

            {isAdmin && (
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={includeInactive}
                  onChange={(event) => { foodPager.resetPage(); setIncludeInactive(event.target.checked); }}
                />
                Hiện mục đã lưu trữ
              </label>
            )}
          </div>

          {foodsQuery.isLoading ? (
            <TableLoading />
          ) : foods.length === 0 ? (
            <EmptyState title="Không tìm thấy thực phẩm" description="Hãy thêm thực phẩm hoặc thử từ khóa khác." />
          ) : (
            <div className="w-full overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Hình ảnh</TableHead>
                    <TableHead>Tên</TableHead>
                    <TableHead>Đơn vị</TableHead>
                    <TableHead>Năng lượng</TableHead>
                    <TableHead>Đạm</TableHead>
                    <TableHead>Tinh bột</TableHead>
                    <TableHead>Chất béo</TableHead>
                    <TableHead>Nguồn dữ liệu</TableHead>
                    <TableHead>Trạng thái</TableHead>
                    {isAdmin && <TableHead>Thao tác</TableHead>}
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {foodPagination.paginatedItems.map((food) => (
                    <TableRow key={food.id} className={!food.active ? "opacity-50" : ""}>
                      <TableCell>
                        {food.imageUrl ? (
                          <button
                            type="button"
                            className="block overflow-hidden rounded-lg border bg-slate-50 transition hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                            onClick={() => setPreviewImage({ url: food.imageUrl!, title: food.name })}
                            aria-label={`Xem ảnh ${food.name}`}
                          >
                            <img
                              src={resolveApiAssetUrl(food.imageUrl)}
                              alt=""
                              loading="lazy"
                              className="h-12 w-16 object-cover"
                            />
                          </button>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      <TableCell className="font-medium">{food.name}</TableCell>
                      <TableCell>{food.unit}</TableCell>
                      <TableCell>{food.calories}</TableCell>
                      <TableCell>{food.protein}g</TableCell>
                      <TableCell>{food.carbs}g</TableCell>
                      <TableCell>{food.fat}g</TableCell>
                      <TableCell>
                        <div className="min-w-36 text-xs">
                          <p className="font-medium">{sourceLabels[food.dataSourceType ?? "ESTIMATED"]}</p>
                          <p className="text-muted-foreground">{food.verified ? "✓ Đã xác minh" : food.dataSourceName || "Chưa xác minh"}</p>
                        </div>
                      </TableCell>

                      <TableCell>
                        {food.approvalStatus === "PENDING" ? (
                          <span className="rounded-full bg-amber-100 px-2 py-1 text-xs text-amber-800">Chờ duyệt</span>
                        ) : food.approvalStatus === "REJECTED" ? (
                          <span className="rounded-full bg-red-100 px-2 py-1 text-xs text-red-700">Từ chối</span>
                        ) : food.active ? (
                          <span className="rounded-full bg-green-100 px-2 py-1 text-xs text-green-700">Đang dùng</span>
                        ) : (
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-xs text-slate-600">Đã lưu trữ</span>
                        )}
                      </TableCell>

                      {isAdmin && (
                        <TableCell className="space-x-2">
                          {food.approvalStatus === "PENDING" ? (
                            <>
                              <Button size="sm" onClick={() => reviewMutation.mutate({ id: food.id, status: "APPROVED" })}>
                                Duyệt
                              </Button>
                              <Button variant="destructive" size="sm" onClick={() => reviewMutation.mutate({ id: food.id, status: "REJECTED" })}>
                                Từ chối
                              </Button>
                            </>
                          ) : (
                            <Button variant="outline" size="sm" onClick={() => setEditingFood(food)} disabled={!food.active}>
                              Sửa
                            </Button>
                          )}

                          {food.approvalStatus !== "PENDING" && (food.active ? (
                            <Button
                              variant="destructive"
                              size="sm"
                              onClick={() => archiveMutation.mutate(food.id)}
                              disabled={archiveMutation.isPending}
                            >
                              Lưu trữ
                            </Button>
                          ) : (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => restoreMutation.mutate(food.id)}
                              disabled={restoreMutation.isPending}
                            >
                              Khôi phục
                            </Button>
                          ))}
                        </TableCell>
                      )}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <DataPagination
                page={foodPagination.page}
                pageSize={foodPagination.pageSize}
                totalItems={foodPagination.totalItems}
                totalPages={foodPagination.totalPages}
                onPageChange={foodPagination.setPage}
                onPageSizeChange={foodPagination.setPageSize}
              />
            </div>
          )}
        </CardContent>
      </Card>

      {isAdmin && (
        <Dialog
          open={!!editingFood}
          onOpenChange={(open) => {
            if (!open) {
              setEditingFood(null);
            }
          }}
        >
          <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
            <DialogHeader>
              <DialogTitle>Sửa thực phẩm</DialogTitle>
            </DialogHeader>

            {editingFood && (
              <div className="space-y-4">
                <div className="grid gap-4 sm:grid-cols-2">
                  <FormField label="Tên thực phẩm" required><Input value={editingFood.name} onChange={(event) => setEditingFood({ ...editingFood, name: event.target.value })} /></FormField>
                  <FormField label="Khẩu phần chuẩn" hint="Ví dụ: 100g hoặc 1 phần." required><Input value={editingFood.unit} onChange={(event) => setEditingFood({ ...editingFood, unit: event.target.value })} /></FormField>
                  <FormField label="Khối lượng một khẩu phần" unit="g/ml" hint="Dùng để quy đổi khi ghi theo gram/ml."><Input type="number" min={0.01} step="any" value={editingFood.servingSizeGrams ?? ""} onChange={(event) => setEditingFood({ ...editingFood, servingSizeGrams: event.target.value === "" ? null : Number(event.target.value) })} /></FormField>
                  <FormField label="Loại nguồn dữ liệu"><select className="h-10 w-full rounded-md border bg-background px-3 text-sm" value={editingFood.dataSourceType ?? "ESTIMATED"} onChange={(event) => setEditingFood({ ...editingFood, dataSourceType: event.target.value as FoodSourceType })}>{Object.entries(sourceLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></FormField>
                  <FormField label="Tên nguồn" hint="Nhãn sản phẩm, cơ sở dữ liệu hoặc công thức."><Input value={editingFood.dataSourceName ?? ""} onChange={(event) => setEditingFood({ ...editingFood, dataSourceName: event.target.value })} /></FormField>
                  <label className="flex items-center gap-3 rounded-xl border p-3 text-sm"><input type="checkbox" checked={Boolean(editingFood.verified)} onChange={(event) => setEditingFood({ ...editingFood, verified: event.target.checked })} /><span><strong>Đã xác minh</strong><br /><span className="text-xs text-muted-foreground">Đã đối chiếu với nguồn đáng tin cậy.</span></span></label>
                  {(["calories", "protein", "carbs", "fat"] as const).map((key) => <FormField key={key} label={{ calories: "Năng lượng", protein: "Chất đạm", carbs: "Tinh bột", fat: "Chất béo" }[key]} unit={key === "calories" ? "kcal" : "g"}><Input type="number" min={0} step="any" value={editingFood[key]} onChange={(event) => setEditingFood({ ...editingFood, [key]: Number(event.target.value) })} /></FormField>)}
                </div>

                <FoodImageField
                  value={editingFood.imageUrl ?? ""}
                  onChange={(imageUrl) => setEditingFood({ ...editingFood, imageUrl })}
                  onPreview={() =>
                    editingFood.imageUrl &&
                    setPreviewImage({ url: editingFood.imageUrl, title: editingFood.name || "Ảnh thực phẩm" })
                  }
                />

                <Button className="w-full" onClick={() => updateMutation.mutate(editingFood)} disabled={updateMutation.isPending}>
                  {updateMutation.isPending ? "Đang lưu..." : "Lưu thay đổi"}
                </Button>
              </div>
            )}
          </DialogContent>
        </Dialog>
      )}

      <Dialog open={!!previewImage} onOpenChange={(open) => !open && setPreviewImage(null)}>
        <DialogContent className="sm:max-w-3xl">
          <DialogHeader>
            <DialogTitle>{previewImage?.title}</DialogTitle>
          </DialogHeader>

          {previewImage && (
            <div className="flex min-h-48 items-center justify-center overflow-hidden rounded-xl bg-slate-100 p-2">
              <img
                src={resolveApiAssetUrl(previewImage.url)}
                alt={previewImage.title}
                className="max-h-[70vh] w-auto max-w-full rounded-lg object-contain"
              />
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

type FoodImageFieldProps = {
  value: string;
  onChange: (value: string) => void;
  onPreview: () => void;
};

function FoodImageField({ value, onChange, onPreview }: FoodImageFieldProps) {
  const isUploadedFile = value.startsWith("data:image/");

  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";

    if (!file) {
      return;
    }

    if (!["image/png", "image/jpeg", "image/webp", "image/gif", "image/avif"].includes(file.type)) {
      toast.error("Chỉ hỗ trợ PNG, JPEG, WebP, GIF hoặc AVIF");
      return;
    }

    if (file.size > MAX_IMAGE_FILE_SIZE) {
      toast.error("Ảnh phải có dung lượng tối đa 1 MB");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === "string") {
        onChange(reader.result);
      }
    };
    reader.onerror = () => toast.error("Không thể đọc ảnh này");
    reader.readAsDataURL(file);
  };

  return (
    <div className="space-y-3 rounded-xl border bg-slate-50/60 p-3">
      <div>
        <p className="text-sm font-medium">Hình ảnh thực phẩm</p>
        <p className="text-xs text-muted-foreground">Dán URL hoặc tải ảnh tối đa 1 MB.</p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <Input
          type="url"
          value={isUploadedFile ? "" : value}
          onChange={(event) => onChange(event.target.value)}
          placeholder={isUploadedFile ? "Đã chọn ảnh từ thiết bị" : "https://example.com/food.jpg"}
        />
        <Input type="file" accept="image/png,image/jpeg,image/webp,image/gif,image/avif" onChange={handleFileChange} />
      </div>

      {value && (
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="overflow-hidden rounded-lg border bg-white transition hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            onClick={onPreview}
            aria-label="Xem trước ảnh thực phẩm"
          >
            <img src={resolveApiAssetUrl(value)} alt="" className="h-16 w-24 object-cover" />
          </button>
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">
              {isUploadedFile ? "Ảnh tải lên đã sẵn sàng để lưu" : "URL ảnh đã sẵn sàng để lưu"}
            </p>
            <Button type="button" variant="outline" size="sm" onClick={() => onChange("")}>
              Xóa ảnh
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
