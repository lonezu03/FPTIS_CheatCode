import { type ChangeEvent, useEffect, useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { resolveApiAssetUrl } from "@/api/axios";
import { CatalogImportDialog } from "@/components/catalog/CatalogImportDialog";
import { getExerciseCatalogFacets } from "@/api/exercise.api";

import PageHeader from "../components/PageHeader";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";
import DataPagination from "../components/common/DataPagination";
import { useServerPagination } from "../hooks/useServerPagination";
import FormField from "../components/common/FormField";

import {
  createExerciseApi,
  deleteExerciseApi,
  getExercisesPageApi,
  reviewExerciseApi,
  restoreExerciseApi,
  suggestExerciseApi,
  updateExerciseApi,
  type Exercise,
} from "../api/exercise.api";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAuthStore } from "@/store/auth.store";

type ExerciseDraft = {
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
  imageUrl: string;
};

const emptyDraft: ExerciseDraft = {
  name: "",
  muscleGroup: "",
  equipment: "",
  description: "",
  imageUrl: "",
};

const MAX_IMAGE_FILE_SIZE = 1024 * 1024;

export default function ExercisesPage() {
  const ownerId = useAuthStore(state => state.user?.userId);
  return <ExercisesWorkspace key={ownerId ?? 'anonymous'} />;
}

function ExercisesWorkspace() {
  const queryClient = useQueryClient();
  const isAdmin = useAuthStore((state) => state.user?.role === "ADMIN");
  const ownerId = useAuthStore(state => state.user?.userId);
  const storageKey = `fittrack:exercises:${ownerId ?? 'anonymous'}:filters`;
  const [preferences] = useState(() => {
    try { const raw = localStorage.getItem(storageKey); const parsed = raw ? JSON.parse(raw) : null; return { keyword: typeof parsed?.keyword === 'string' ? parsed.keyword : '', includeInactive: typeof parsed?.includeInactive === 'boolean' ? parsed.includeInactive : isAdmin }; } catch { return { keyword: '', includeInactive: isAdmin }; }
  });
  const [keyword, setKeyword] = useState(preferences.keyword);
  const [searchKeyword, setSearchKeyword] = useState(preferences.keyword);
  const [includeInactive, setIncludeInactive] = useState(preferences.includeInactive);
  const [importOpen, setImportOpen] = useState(false);
  const [muscleFilter, setMuscleFilter] = useState("");
  const [equipmentFilter, setEquipmentFilter] = useState("");
  const facets = useQuery({ queryKey: ['exercise-catalog-facets'], queryFn: getExerciseCatalogFacets });
  useEffect(() => { if (ownerId) { try { localStorage.setItem(storageKey, JSON.stringify({ keyword: searchKeyword, includeInactive })); } catch { /* Optional browser preference. */ } } }, [ownerId, storageKey, searchKeyword, includeInactive]);

  const [draft, setDraft] = useState<ExerciseDraft>({
    name: "Đẩy ngực với tạ đơn",
    muscleGroup: "Ngực",
    equipment: "Tạ đơn",
    description: "Đẩy tạ đơn khi nằm trên ghế hoặc sàn.",
    imageUrl: "",
  });

  const [editingExercise, setEditingExercise] = useState<Exercise | null>(null);
  const [detailExercise, setDetailExercise] = useState<Exercise | null>(null);
  const exercisePager = useServerPagination(20);
  const [previewImage, setPreviewImage] = useState<{ url: string; title: string } | null>(null);

  const exercisesQuery = useQuery({
    queryKey: ["exercises-management", searchKeyword, isAdmin && includeInactive, exercisePager.page, exercisePager.pageSize, muscleFilter, equipmentFilter],
    queryFn: () => getExercisesPageApi(
      searchKeyword,
      isAdmin && includeInactive,
      exercisePager.page - 1,
      exercisePager.pageSize,
      muscleFilter, equipmentFilter,
    ),
    placeholderData: (previous) => previous,
  });

  const exercises = exercisesQuery.data?.content ?? [];
  const exercisePagination = {
    ...exercisePager,
    paginatedItems: exercises,
    totalItems: exercisesQuery.data?.totalElements ?? 0,
    totalPages: Math.max(1, exercisesQuery.data?.totalPages ?? 1),
  };

  const createMutation = useMutation({
    mutationFn: isAdmin ? createExerciseApi : suggestExerciseApi,
    onSuccess: () => {
      toast.success(isAdmin ? "Đã tạo bài tập" : "Đã gửi bài tập để admin duyệt");
      setDraft(emptyDraft);
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể tạo bài tập");
    },
  });

  const reviewMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: "APPROVED" | "REJECTED" }) =>
      reviewExerciseApi(id, status),
    onSuccess: () => {
      toast.success("Đã xử lý đề xuất bài tập");
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xử lý đề xuất");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: Exercise) =>
      updateExerciseApi(payload.id, {
        name: payload.name,
        muscleGroup: payload.muscleGroup,
        equipment: payload.equipment,
        description: payload.description,
        imageUrl: payload.imageUrl?.trim() || null,
      }),
    onSuccess: () => {
      toast.success("Đã cập nhật bài tập");
      setEditingExercise(null);
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể cập nhật bài tập");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteExerciseApi,
    onSuccess: () => {
      toast.success("Đã lưu trữ bài tập");
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xóa bài tập vì có thể đang được sử dụng.");
    },
  });

  const restoreMutation = useMutation({
    mutationFn: restoreExerciseApi,
    onSuccess: () => {
      toast.success("Đã khôi phục bài tập");
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể khôi phục bài tập");
    },
  });

  const handleCreate = () => {
    if (!draft.name.trim()) {
      toast.error("Vui lòng nhập tên bài tập");
      return;
    }

    createMutation.mutate({
      ...draft,
      imageUrl: draft.imageUrl.trim() || null,
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Bạn có chắc muốn lưu trữ bài tập này?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  if (exercisesQuery.isError) {
    return <ErrorState title="Không thể tải bài tập" message="Vui lòng tải lại trang." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Kho bài tập" description="Tạo và quản lý bài tập dùng trong buổi tập và giáo án." />
      {isAdmin && <><Button variant="outline" onClick={() => setImportOpen(true)}>Nhập hàng loạt</Button><CatalogImportDialog kind="EXERCISE" open={importOpen} onOpenChange={setImportOpen} onImported={() => { setImportOpen(false); void queryClient.invalidateQueries({ queryKey: ['exercises-management'] }); void queryClient.invalidateQueries({ queryKey: ['exercises'] }); void queryClient.invalidateQueries({ queryKey: ['exercise-catalog-facets'] }); }} /></>}
      <datalist id="catalog-muscles">{(facets.data?.muscleGroups ?? []).map(value => <option key={value} value={value} />)}</datalist>
      <datalist id="catalog-equipment">{(facets.data?.equipment ?? []).map(value => <option key={value} value={value} />)}</datalist>

      {(
        <Card>
          <CardHeader>
            <CardTitle>{isAdmin ? "Tạo bài tập" : "Đề xuất bài tập mới"}</CardTitle>
          </CardHeader>

          <CardContent className="grid gap-4 md:grid-cols-2">
            <FormField label="Tên bài tập" htmlFor="exercise-name" hint="Dùng tên phổ biến để mọi người dễ tìm." required>
              <Input id="exercise-name" value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} placeholder="Ví dụ: Đẩy vai với tạ đơn" />
            </FormField>
            <FormField label="Nhóm cơ chính" htmlFor="exercise-muscle" hint="Nhóm cơ chịu tải chính của động tác." required>
              <Input id="exercise-muscle" list="catalog-muscles" value={draft.muscleGroup} onChange={(event) => setDraft({ ...draft, muscleGroup: event.target.value })} placeholder="Chọn nhóm cơ có sẵn hoặc nhập nhóm mới" />
            </FormField>
            <FormField label="Dụng cụ" htmlFor="exercise-equipment" hint="Nhập 'Không' nếu là bài tập trọng lượng cơ thể.">
              <Input id="exercise-equipment" list="catalog-equipment" value={draft.equipment} onChange={(event) => setDraft({ ...draft, equipment: event.target.value })} placeholder="Chọn dụng cụ có sẵn hoặc nhập dụng cụ mới" />
            </FormField>
            <FormField label="Hướng dẫn thực hiện" htmlFor="exercise-description" hint="Mô tả tư thế và chuyển động chính để tập an toàn.">
              <textarea id="exercise-description" maxLength={2000} rows={4} className="w-full rounded-xl border bg-background p-3 text-sm" value={draft.description} onChange={(event) => setDraft({ ...draft, description: event.target.value })} placeholder="Tư thế bắt đầu, chuyển động, lưu ý an toàn…" />
            </FormField>

            <div className="md:col-span-2">
              <ExerciseImageField
                value={draft.imageUrl}
                onChange={(imageUrl) => setDraft({ ...draft, imageUrl })}
                onPreview={() => draft.imageUrl && setPreviewImage({ url: draft.imageUrl, title: draft.name || "Exercise image" })}
              />
            </div>

            <Button className="md:col-span-2" onClick={handleCreate} disabled={createMutation.isPending}>
              {createMutation.isPending ? "Đang gửi..." : isAdmin ? "Tạo bài tập" : "Gửi admin duyệt"}
            </Button>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Danh sách bài tập</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="grid gap-3 sm:grid-cols-2"><FormField label="Lọc nhóm cơ"><select className="h-10 w-full rounded-md border bg-background px-3 text-sm" value={muscleFilter} onChange={event => { setMuscleFilter(event.target.value); exercisePager.resetPage(); }}><option value="">Tất cả nhóm cơ</option>{(facets.data?.muscleGroups ?? []).map(value => <option key={value} value={value}>{value}</option>)}</select></FormField><FormField label="Lọc dụng cụ"><select className="h-10 w-full rounded-md border bg-background px-3 text-sm" value={equipmentFilter} onChange={event => { setEquipmentFilter(event.target.value); exercisePager.resetPage(); }}><option value="">Tất cả dụng cụ</option>{(facets.data?.equipment ?? []).map(value => <option key={value} value={value}>{value}</option>)}</select></FormField></div>
          <div className="flex flex-col gap-3 md:flex-row md:items-center">
            <div className="flex min-w-0 flex-1 gap-2">
              <Input value={keyword} onChange={(event) => setKeyword(event.target.value)} placeholder="Tìm bài tập..." />

              <Button onClick={() => { exercisePager.resetPage(); setSearchKeyword(keyword); }}>Tìm kiếm</Button>
            </div>

            {isAdmin && (
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={includeInactive}
                  onChange={(event) => { exercisePager.resetPage(); setIncludeInactive(event.target.checked); }}
                />
                Hiện mục đã lưu trữ
              </label>
            )}
            {(keyword || searchKeyword || muscleFilter || equipmentFilter || (isAdmin && includeInactive)) && <Button variant="ghost" onClick={() => { setKeyword(''); setSearchKeyword(''); setMuscleFilter(''); setEquipmentFilter(''); setIncludeInactive(false); exercisePager.resetPage(); }}>Xóa bộ lọc</Button>}
          </div>

          {exercisesQuery.isLoading ? (
            <TableLoading />
          ) : exercises.length === 0 ? (
            <EmptyState kind="workout" title="Không tìm thấy bài tập" description="Hãy thêm bài tập hoặc thử từ khóa khác." />
          ) : (
            <div className="w-full overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Hình ảnh</TableHead>
                    <TableHead>Tên</TableHead>
                    <TableHead>Nhóm cơ</TableHead>
                    <TableHead>Dụng cụ</TableHead>
                    <TableHead>Tự tạo</TableHead>
                    <TableHead>Trạng thái</TableHead>
                    {isAdmin && <TableHead>Thao tác</TableHead>}
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {exercisePagination.paginatedItems.map((exercise) => (
                    <TableRow key={exercise.id} className={!exercise.active ? "opacity-50" : ""}>
                      <TableCell>
                        {exercise.imageUrl ? (
                          <button
                            type="button"
                            className="block overflow-hidden rounded-lg border bg-slate-50 transition hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                            onClick={() => setPreviewImage({ url: exercise.imageUrl!, title: exercise.name })}
                            aria-label={`Xem ảnh ${exercise.name}`}
                          >
                            <img
                              src={resolveApiAssetUrl(exercise.imageUrl)}
                              alt=""
                              loading="lazy"
                              className="h-12 w-16 object-cover"
                            />
                          </button>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      <TableCell className="font-medium"><button type="button" className="text-left underline-offset-4 hover:underline" onClick={() => setDetailExercise(exercise)}>{exercise.name}<span className="mt-1 block text-xs font-normal text-muted-foreground">Xem hướng dẫn</span></button></TableCell>
                      <TableCell>{exercise.muscleGroup}</TableCell>
                      <TableCell>{exercise.equipment}</TableCell>
                      <TableCell>{exercise.custom ? "Có" : "Không"}</TableCell>
                      <TableCell>
                        {exercise.approvalStatus === "PENDING" ? (
                          <span className="rounded-full bg-amber-100 px-2 py-1 text-xs text-amber-800">Chờ duyệt</span>
                        ) : exercise.approvalStatus === "REJECTED" ? (
                          <span className="rounded-full bg-red-100 px-2 py-1 text-xs text-red-700">Từ chối</span>
                        ) : exercise.active ? (
                          <span className="rounded-full bg-green-100 px-2 py-1 text-xs text-green-700">Đang dùng</span>
                        ) : (
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-xs text-slate-600">Đã lưu trữ</span>
                        )}
                      </TableCell>
                      {isAdmin && (
                        <TableCell className="space-x-2">
                          {exercise.approvalStatus === "PENDING" ? (
                            <>
                              <Button size="sm" onClick={() => reviewMutation.mutate({ id: exercise.id, status: "APPROVED" })}>
                                Duyệt
                              </Button>
                              <Button variant="destructive" size="sm" onClick={() => reviewMutation.mutate({ id: exercise.id, status: "REJECTED" })}>
                                Từ chối
                              </Button>
                            </>
                          ) : (
                            <Button variant="outline" size="sm" onClick={() => setEditingExercise(exercise)} disabled={!exercise.active}>
                              Sửa
                            </Button>
                          )}

                          {exercise.approvalStatus !== "PENDING" && (exercise.active ? (
                            <Button
                              variant="destructive"
                              size="sm"
                              onClick={() => handleDelete(exercise.id)}
                              disabled={deleteMutation.isPending}
                            >
                              Lưu trữ
                            </Button>
                          ) : (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => restoreMutation.mutate(exercise.id)}
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
                page={exercisePagination.page}
                pageSize={exercisePagination.pageSize}
                totalItems={exercisePagination.totalItems}
                totalPages={exercisePagination.totalPages}
                onPageChange={exercisePagination.setPage}
                onPageSizeChange={exercisePagination.setPageSize}
              />
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog
        open={!!editingExercise}
        onOpenChange={(open) => {
          if (!open) {
            setEditingExercise(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Sửa bài tập</DialogTitle>
          </DialogHeader>

          {editingExercise && (
            <div className="space-y-4">
              <Input
                value={editingExercise.name}
                onChange={(event) => setEditingExercise({ ...editingExercise, name: event.target.value })}
                placeholder="Tên bài tập"
              />

              <Input
                value={editingExercise.muscleGroup}
                onChange={(event) => setEditingExercise({ ...editingExercise, muscleGroup: event.target.value })}
                placeholder="Nhóm cơ"
              />

              <Input
                value={editingExercise.equipment}
                onChange={(event) => setEditingExercise({ ...editingExercise, equipment: event.target.value })}
                placeholder="Dụng cụ"
              />

              <textarea rows={4} maxLength={2000} className="w-full rounded-xl border bg-background p-3 text-sm"
                value={editingExercise.description}
                onChange={(event) => setEditingExercise({ ...editingExercise, description: event.target.value })}
                placeholder="Mô tả"
              />

              <ExerciseImageField
                value={editingExercise.imageUrl ?? ""}
                onChange={(imageUrl) => setEditingExercise({ ...editingExercise, imageUrl })}
                onPreview={() =>
                  editingExercise.imageUrl &&
                  setPreviewImage({ url: editingExercise.imageUrl, title: editingExercise.name || "Exercise image" })
                }
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingExercise)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={!!detailExercise} onOpenChange={open => !open && setDetailExercise(null)}><DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-2xl"><DialogHeader><DialogTitle>{detailExercise?.name}</DialogTitle></DialogHeader>{detailExercise && <div className="space-y-4">{detailExercise.imageUrl && <img src={resolveApiAssetUrl(detailExercise.imageUrl)} alt={detailExercise.name} className="max-h-72 w-full rounded-xl object-contain" />}<div className="flex flex-wrap gap-2 text-sm"><span className="rounded-full bg-emerald-50 px-3 py-1">Nhóm cơ: {detailExercise.muscleGroup || 'Chưa có'}</span><span className="rounded-full bg-slate-100 px-3 py-1">Dụng cụ: {detailExercise.equipment || 'Chưa có'}</span></div><p className="whitespace-pre-wrap text-sm leading-relaxed">{detailExercise.description || 'Chưa có hướng dẫn. Bạn có thể đề nghị admin bổ sung.'}</p><p className="text-xs text-muted-foreground">Chọn mức tạ phù hợp và dừng nếu đau bất thường.</p></div>}</DialogContent></Dialog>
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

type ExerciseImageFieldProps = {
  value: string;
  onChange: (value: string) => void;
  onPreview: () => void;
};

function ExerciseImageField({ value, onChange, onPreview }: ExerciseImageFieldProps) {
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
      toast.error("Image must be 1 MB or smaller");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === "string") {
        onChange(reader.result);
      }
    };
    reader.onerror = () => toast.error("Cannot read this image");
    reader.readAsDataURL(file);
  };

  return (
    <div className="space-y-3 rounded-xl border bg-slate-50/60 p-3">
      <div>
        <p className="text-sm font-medium">Exercise image</p>
        <p className="text-xs text-muted-foreground">Paste an image URL or upload an image up to 1 MB.</p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <Input
          type="url"
          value={isUploadedFile ? "" : value}
          onChange={(event) => onChange(event.target.value)}
          placeholder={isUploadedFile ? "Image selected from your device" : "https://example.com/exercise.jpg"}
        />
        <Input type="file" accept="image/png,image/jpeg,image/webp,image/gif,image/avif" onChange={handleFileChange} />
      </div>

      {value && (
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="overflow-hidden rounded-lg border bg-white transition hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            onClick={onPreview}
            aria-label="Preview exercise image"
          >
            <img src={resolveApiAssetUrl(value)} alt="" className="h-16 w-24 object-cover" />
          </button>
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">
              {isUploadedFile ? "Uploaded image ready to save" : "Image URL ready to save"}
            </p>
            <Button type="button" variant="outline" size="sm" onClick={() => onChange("")}>
              Remove image
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
