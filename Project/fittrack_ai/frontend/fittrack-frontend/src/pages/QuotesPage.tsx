import axios from "axios";
import { useMemo, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Archive,
  BookOpen,
  Check,
  Clipboard,
  Clock3,
  ExternalLink,
  Eye,
  EyeOff,
  History,
  MoreHorizontal,
  Pencil,
  Plus,
  Quote as QuoteIcon,
  RotateCcw,
  Search,
  Trash2,
} from "lucide-react";
import { toast } from "sonner";
import {
  archiveQuote,
  checkQuoteDuplicate,
  createQuote,
  deleteQuote,
  getQuote,
  getQuoteHistory,
  getQuotes,
  getQuoteTags,
  restoreQuote,
  updateQuote,
  type FavoriteQuote,
  type QuotePayload,
  type QuoteSourceType,
  type QuoteStatus,
} from "@/api/quote.api";
import DataPagination from "@/components/common/DataPagination";
import ErrorState from "@/components/common/ErrorState";
import PageLoading from "@/components/common/PageLoading";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useServerPagination } from "@/hooks/useServerPagination";

const SOURCE_LABELS: Record<QuoteSourceType, string> = {
  BOOK: "Sách",
  ARTICLE: "Bài viết",
  VIDEO: "Video",
  PODCAST: "Podcast",
  SONG: "Bài hát",
  MOVIE: "Phim",
  CONVERSATION: "Cuộc trò chuyện",
  SOCIAL_POST: "Bài đăng mạng xã hội",
  OTHER: "Khác",
};

type PendingSave = { payload: QuotePayload; id?: string };

export default function QuotesPage() {
  const queryClient = useQueryClient();
  const pager = useServerPagination(20);
  const [searchInput, setSearchInput] = useState("");
  const [query, setQuery] = useState("");
  const [tag, setTag] = useState("");
  const [status, setStatus] = useState<QuoteStatus | "">("ACTIVE");
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<FavoriteQuote | null>(null);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [pendingSave, setPendingSave] = useState<PendingSave | null>(null);
  const [duplicate, setDuplicate] = useState<FavoriteQuote | null>(null);
  const [checkingDuplicate, setCheckingDuplicate] = useState(false);

  const quotesQuery = useQuery({
    queryKey: ["quotes", "list", query, tag, status, pager.page, pager.pageSize],
    queryFn: () => getQuotes({
      q: query,
      tag,
      status: status || undefined,
      page: pager.page - 1,
      size: pager.pageSize,
    }),
  });
  const tagsQuery = useQuery({ queryKey: ["quotes", "tags"], queryFn: getQuoteTags });

  const invalidate = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["quotes"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] }),
    ]);
  };

  const saveMutation = useMutation({
    mutationFn: ({ payload, id }: PendingSave) => id
      ? updateQuote(id, payload)
      : createQuote(payload),
    onSuccess: async () => {
      toast.success(editing ? "Đã cập nhật câu nói" : "Đã lưu câu nói");
      setFormOpen(false);
      setEditing(null);
      setPendingSave(null);
      setDuplicate(null);
      await invalidate();
    },
    onError: (error) => toast.error(errorMessage(error, "Không thể lưu câu nói")),
  });

  const stateMutation = useMutation({
    mutationFn: ({ id, action }: { id: string; action: "archive" | "restore" }) =>
      action === "archive" ? archiveQuote(id) : restoreQuote(id),
    onSuccess: async (_, variables) => {
      toast.success(variables.action === "archive" ? "Đã lưu trữ câu nói" : "Đã khôi phục câu nói");
      await invalidate();
    },
    onError: (error) => toast.error(errorMessage(error, "Không thể thay đổi trạng thái")),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteQuote,
    onSuccess: async () => {
      toast.success("Đã xóa câu nói");
      setDetailId(null);
      await invalidate();
    },
    onError: (error) => toast.error(errorMessage(error, "Không thể xóa câu nói")),
  });

  const dailyMutation = useMutation({
    mutationFn: (quote: FavoriteQuote) => updateQuote(quote.id, {
      content: quote.content,
      author: quote.author ?? "",
      sourceType: quote.sourceType ?? undefined,
      sourceTitle: quote.sourceTitle ?? "",
      sourceUrl: quote.sourceUrl ?? "",
      sourceLocation: quote.sourceLocation ?? "",
      personalNote: quote.personalNote ?? "",
      includeInDaily: !quote.includeInDaily,
      language: quote.language ?? "vi",
      tags: quote.tags,
    }),
    onSuccess: async (quote) => {
      toast.success(quote.includeInDaily ? "Đã đưa vào Câu nói hôm nay" : "Đã tắt hiển thị hằng ngày");
      await invalidate();
    },
    onError: (error) => toast.error(errorMessage(error, "Không thể thay đổi hiển thị hằng ngày")),
  });

  const handleSave = async (payload: QuotePayload) => {
    const candidate = { payload, id: editing?.id };
    setCheckingDuplicate(true);
    try {
      const result = await checkQuoteDuplicate(payload.content, editing?.id);
      if (result.duplicate && result.existingQuote) {
        setPendingSave(candidate);
        setDuplicate(result.existingQuote);
        return;
      }
      saveMutation.mutate(candidate);
    } catch (error) {
      toast.error(errorMessage(error, "Không thể kiểm tra câu nói trùng"));
    } finally {
      setCheckingDuplicate(false);
    }
  };

  const forceSave = () => {
    if (!pendingSave) return;
    saveMutation.mutate({
      ...pendingSave,
      payload: { ...pendingSave.payload, allowDuplicate: true },
    });
  };

  const copyQuote = async (quote: FavoriteQuote) => {
    await navigator.clipboard.writeText(quote.content);
    toast.success("Đã sao chép câu nói");
  };

  if (quotesQuery.isLoading) return <PageLoading />;
  if (quotesQuery.isError || !quotesQuery.data) {
    return <ErrorState title="Không thể tải kho câu nói" message="Vui lòng thử lại sau." />;
  }

  const pageData = quotesQuery.data;
  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          title="Kho câu nói"
          description="Lưu những câu khiến bạn muốn dừng lại, suy nghĩ và đọc lại đúng lúc."
        />
          <div className="flex flex-wrap gap-2">
            <Button type="button" variant="outline" onClick={() => setHistoryOpen(true)}>
              <History className="size-4" /> Lịch sử
            </Button>
            <Button type="button" onClick={() => { setEditing(null); setFormOpen(true); }}>
              <Plus className="size-4" /> Thêm câu nói
            </Button>
          </div>
      </div>

      <Card>
        <CardContent className="space-y-4 p-4 sm:p-5">
          <form
            className="flex flex-col gap-3 lg:flex-row"
            onSubmit={(event) => {
              event.preventDefault();
              pager.resetPage();
              setQuery(searchInput.trim());
            }}
          >
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                placeholder="Tìm trong câu nói, tác giả, nguồn, ghi chú hoặc nhãn..."
                className="pl-9"
              />
            </div>
            <select
              value={tag}
              onChange={(event) => { setTag(event.target.value); pager.resetPage(); }}
              className="h-10 rounded-xl border border-input bg-background px-3 text-sm outline-none focus:border-emerald-500"
              aria-label="Lọc theo nhãn"
            >
              <option value="">Tất cả nhãn</option>
              {(tagsQuery.data ?? []).map((item) => <option key={item} value={item}>#{item}</option>)}
            </select>
            <Button type="submit">Tìm kiếm</Button>
          </form>
          <div className="flex flex-wrap gap-2">
            {([
              ["ACTIVE", "Đang dùng"],
              ["ARCHIVED", "Đã lưu trữ"],
              ["", "Tất cả"],
            ] as const).map(([value, label]) => (
              <Button
                key={label}
                type="button"
                size="sm"
                variant={status === value ? "default" : "outline"}
                onClick={() => { setStatus(value); pager.resetPage(); }}
              >
                {label}
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {pageData.content.length === 0 ? (
        <Card className="border-dashed border-emerald-200 bg-emerald-50/30">
          <CardContent className="flex flex-col items-center py-14 text-center">
            <span className="grid size-16 place-items-center rounded-3xl bg-white text-emerald-700 shadow-sm">
              <QuoteIcon className="size-8" />
            </span>
            <h2 className="mt-5 text-xl font-semibold">{query || tag ? "Không tìm thấy câu phù hợp" : "Bạn chưa có câu nói nào"}</h2>
            <p className="mt-2 max-w-md text-sm leading-6 text-muted-foreground">
              {query || tag
                ? "Thử đổi từ khóa, nhãn hoặc trạng thái để xem thêm kết quả."
                : "Lưu lại những câu khiến bạn muốn dừng lại và suy nghĩ."}
            </p>
            {!query && !tag && (
              <Button className="mt-5" onClick={() => { setEditing(null); setFormOpen(true); }}>
                <Plus className="size-4" /> Thêm câu đầu tiên
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="grid gap-4 md:grid-cols-2 2xl:grid-cols-3">
            {pageData.content.map((quote) => (
              <QuoteCard
                key={quote.id}
                quote={quote}
                onCopy={() => copyQuote(quote)}
                onDetail={() => setDetailId(quote.id)}
                onEdit={() => { setEditing(quote); setFormOpen(true); }}
                onArchive={() => stateMutation.mutate({ id: quote.id, action: "archive" })}
                onRestore={() => stateMutation.mutate({ id: quote.id, action: "restore" })}
                onToggleDaily={() => dailyMutation.mutate(quote)}
                onDelete={() => {
                  if (window.confirm("Xóa vĩnh viễn câu nói này và lịch sử xuất hiện của nó?")) {
                    deleteMutation.mutate(quote.id);
                  }
                }}
              />
            ))}
          </div>
          <Card className="overflow-hidden">
            <DataPagination
              page={pager.page}
              pageSize={pager.pageSize}
              totalItems={pageData.totalElements}
              totalPages={Math.max(pageData.totalPages, 1)}
              onPageChange={pager.setPage}
              onPageSizeChange={pager.setPageSize}
            />
          </Card>
        </>
      )}

      {formOpen && (
        <QuoteFormDialog
          open
          quote={editing}
          saving={checkingDuplicate || saveMutation.isPending}
          onOpenChange={(open) => {
            setFormOpen(open);
            if (!open) setEditing(null);
          }}
          onSubmit={handleSave}
        />
      )}
      <QuoteDetailDialog
        id={detailId}
        open={Boolean(detailId)}
        onOpenChange={(open) => { if (!open) setDetailId(null); }}
      />
      <QuoteHistoryDialog open={historyOpen} onOpenChange={setHistoryOpen} />

      <Dialog open={Boolean(duplicate)} onOpenChange={(open) => { if (!open) { setDuplicate(null); setPendingSave(null); } }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Bạn đã lưu câu này trước đó</DialogTitle>
            <DialogDescription>
              Kiểm tra câu đã có để tránh kho câu nói bị trùng lặp.
            </DialogDescription>
          </DialogHeader>
          {duplicate && (
            <div className="rounded-2xl border bg-muted/35 p-4">
              <p className="font-medium leading-6">“{duplicate.content}”</p>
              {duplicate.author && <p className="mt-2 text-sm text-muted-foreground">— {duplicate.author}</p>}
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => {
              if (duplicate) setDetailId(duplicate.id);
              setDuplicate(null);
              setPendingSave(null);
              setFormOpen(false);
              setEditing(null);
            }}>
              Xem câu đã lưu
            </Button>
            <Button onClick={forceSave} disabled={saveMutation.isPending}>Vẫn lưu</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function QuoteCard({
  quote,
  onCopy,
  onDetail,
  onEdit,
  onArchive,
  onRestore,
  onToggleDaily,
  onDelete,
}: {
  quote: FavoriteQuote;
  onCopy: () => void;
  onDetail: () => void;
  onEdit: () => void;
  onArchive: () => void;
  onRestore: () => void;
  onToggleDaily: () => void;
  onDelete: () => void;
}) {
  return (
    <Card className="group relative overflow-visible transition hover:-translate-y-0.5 hover:shadow-md">
      <CardContent className="flex min-h-64 flex-col p-5 sm:p-6">
        <div className="flex items-start justify-between gap-3">
          <QuoteIcon className="size-7 shrink-0 text-emerald-600/65" />
          <details className="relative">
            <summary className="grid size-9 cursor-pointer list-none place-items-center rounded-xl text-muted-foreground hover:bg-muted" aria-label="Thao tác câu nói">
              <MoreHorizontal className="size-5" />
            </summary>
            <div className="absolute right-0 z-20 mt-1 w-56 rounded-xl border bg-popover p-1.5 text-sm shadow-xl">
              <ActionButton icon={BookOpen} label="Xem chi tiết" onClick={onDetail} />
              <ActionButton icon={Pencil} label="Chỉnh sửa" onClick={onEdit} />
              {quote.status === "ACTIVE" && (
                <ActionButton
                  icon={quote.includeInDaily ? EyeOff : Eye}
                  label={quote.includeInDaily ? "Không hiển thị hằng ngày" : "Hiển thị hằng ngày"}
                  onClick={onToggleDaily}
                />
              )}
              {quote.status === "ACTIVE"
                ? <ActionButton icon={Archive} label="Lưu trữ" onClick={onArchive} />
                : <ActionButton icon={RotateCcw} label="Khôi phục" onClick={onRestore} />}
              <ActionButton icon={Trash2} label="Xóa vĩnh viễn" onClick={onDelete} destructive />
            </div>
          </details>
        </div>
        <button type="button" onClick={onDetail} className="mt-4 text-left">
          <blockquote className="text-lg font-medium leading-7 tracking-[-0.01em]">“{quote.content}”</blockquote>
        </button>
        <div className="mt-4 text-sm text-muted-foreground">
          {quote.author && <p className="font-medium text-foreground/75">— {quote.author}</p>}
          {quote.sourceTitle && <p className="mt-1">{quote.sourceTitle}{quote.sourceLocation ? ` · ${quote.sourceLocation}` : ""}</p>}
        </div>
        <div className="mt-auto pt-5">
          {quote.tags.length > 0 && (
            <div className="mb-4 flex flex-wrap gap-1.5">
              {quote.tags.map((item) => <span key={item} className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs text-emerald-800">#{item}</span>)}
            </div>
          )}
          <div className="flex items-center justify-between border-t pt-4">
            <span className={`inline-flex items-center gap-1.5 text-xs ${quote.includeInDaily && quote.status === "ACTIVE" ? "text-emerald-700" : "text-muted-foreground"}`}>
              {quote.includeInDaily && quote.status === "ACTIVE" ? <Check className="size-3.5" /> : <Archive className="size-3.5" />}
              {quote.status === "ARCHIVED" ? "Đã lưu trữ" : quote.includeInDaily ? "Có trong câu hằng ngày" : "Không hiện hằng ngày"}
            </span>
            <Button type="button" size="sm" variant="ghost" onClick={onCopy}>
              <Clipboard className="size-4" /> Sao chép
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ActionButton({ icon: Icon, label, onClick, destructive = false }: { icon: typeof Pencil; label: string; onClick: () => void; destructive?: boolean }) {
  return (
    <button
      type="button"
      className={`flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left hover:bg-muted ${destructive ? "text-red-600" : ""}`}
      onClick={onClick}
    >
      <Icon className="size-4" /> {label}
    </button>
  );
}

function QuoteFormDialog({ open, quote, saving, onOpenChange, onSubmit }: {
  open: boolean;
  quote: FavoriteQuote | null;
  saving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (payload: QuotePayload) => void;
}) {
  const [form, setForm] = useState<QuotePayload>(() => quote ? {
      content: quote.content,
      author: quote.author ?? "",
      sourceType: quote.sourceType ?? undefined,
      sourceTitle: quote.sourceTitle ?? "",
      sourceUrl: quote.sourceUrl ?? "",
      sourceLocation: quote.sourceLocation ?? "",
      personalNote: quote.personalNote ?? "",
      includeInDaily: quote.includeInDaily,
      language: quote.language ?? "vi",
      tags: quote.tags,
    } : emptyPayload());
  const [tagInput, setTagInput] = useState(() => quote?.tags.join(", ") ?? "");
  const [advanced, setAdvanced] = useState(() => Boolean(
    quote?.sourceType || quote?.sourceUrl || quote?.sourceLocation || quote?.personalNote || quote?.tags.length,
  ));

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (!form.content.trim()) {
      toast.error("Vui lòng nhập nội dung câu nói");
      return;
    }
    onSubmit({ ...form, tags: parseTags(tagInput) });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{quote ? "Chỉnh sửa câu nói" : "Thêm câu nói"}</DialogTitle>
          <DialogDescription>Chỉ nội dung câu nói là bắt buộc. Bạn có thể bổ sung ngữ cảnh sau.</DialogDescription>
        </DialogHeader>
        <form id="quote-form" className="space-y-4" onSubmit={submit}>
          <div className="space-y-2">
            <Label htmlFor="quote-content">Câu nói <span className="text-red-500">*</span></Label>
            <textarea
              id="quote-content"
              autoFocus
              rows={4}
              maxLength={10_000}
              value={form.content}
              onChange={(event) => setForm({ ...form, content: event.target.value })}
              placeholder="Nhập câu bạn muốn lưu lại..."
              className="w-full resize-y rounded-2xl border border-input bg-background px-4 py-3 text-sm leading-6 outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Tác giả" value={form.author ?? ""} placeholder="Ví dụ: Lão Tử" onChange={(value) => setForm({ ...form, author: value })} />
            <Field label="Tên nguồn" value={form.sourceTitle ?? ""} placeholder="Ví dụ: Đạo Đức Kinh" onChange={(value) => setForm({ ...form, sourceTitle: value })} />
          </div>
          <button type="button" className="text-sm font-semibold text-emerald-700" onClick={() => setAdvanced((value) => !value)}>
            {advanced ? "− Thu gọn thông tin" : "+ Thêm nguồn, ghi chú và nhãn"}
          </button>
          {advanced && (
            <div className="space-y-4 rounded-2xl border bg-muted/25 p-4">
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="space-y-2 text-sm font-medium">
                  <span>Loại nguồn</span>
                  <select
                    value={form.sourceType ?? ""}
                    onChange={(event) => setForm({ ...form, sourceType: (event.target.value || undefined) as QuoteSourceType | undefined })}
                    className="h-10 w-full rounded-xl border border-input bg-background px-3 font-normal outline-none focus:border-emerald-500"
                  >
                    <option value="">Chưa chọn</option>
                    {Object.entries(SOURCE_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                  </select>
                </label>
                <Field label="Vị trí trong nguồn" value={form.sourceLocation ?? ""} placeholder="Trang 152, Chương 8, 01:12:32..." onChange={(value) => setForm({ ...form, sourceLocation: value })} />
              </div>
              <Field label="Đường dẫn nguồn" type="url" value={form.sourceUrl ?? ""} placeholder="https://..." onChange={(value) => setForm({ ...form, sourceUrl: value })} />
              <div className="space-y-2">
                <Label htmlFor="quote-note">Ghi chú của tôi</Label>
                <textarea
                  id="quote-note"
                  rows={3}
                  value={form.personalNote ?? ""}
                  onChange={(event) => setForm({ ...form, personalNote: event.target.value })}
                  placeholder="Tại sao câu này quan trọng với bạn?"
                  className="w-full resize-y rounded-xl border border-input bg-background px-3 py-2.5 text-sm outline-none focus:border-emerald-500"
                />
              </div>
              <Field
                label="Nhãn"
                value={tagInput}
                placeholder="triết-lý, công-việc, kỷ-luật"
                hint="Ngăn cách bằng dấu phẩy. Không bắt buộc nhập dấu #."
                onChange={setTagInput}
              />
            </div>
          )}
          <label className="flex cursor-pointer items-start gap-3 rounded-2xl border p-4">
            <input
              type="checkbox"
              checked={form.includeInDaily}
              onChange={(event) => setForm({ ...form, includeInDaily: event.target.checked })}
              className="mt-0.5 size-4 accent-emerald-700"
            />
            <span>
              <span className="block text-sm font-semibold">Đưa vào Câu nói hôm nay</span>
              <span className="mt-1 block text-xs leading-5 text-muted-foreground">Câu này có thể xuất hiện trên Dashboard theo vòng quay không lặp.</span>
            </span>
          </label>
        </form>
        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button type="submit" form="quote-form" disabled={saving}>{saving ? "Đang lưu..." : "Lưu câu nói"}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function Field({ label, value, placeholder, hint, type = "text", onChange }: { label: string; value: string; placeholder?: string; hint?: string; type?: string; onChange: (value: string) => void }) {
  const id = useMemo(() => `quote-${label.toLowerCase().replaceAll(" ", "-")}`, [label]);
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      <Input id={id} type={type} value={value} placeholder={placeholder} onChange={(event) => onChange(event.target.value)} />
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}

function QuoteDetailDialog({ id, open, onOpenChange }: { id: string | null; open: boolean; onOpenChange: (open: boolean) => void }) {
  const query = useQuery({ queryKey: ["quotes", "detail", id], queryFn: () => getQuote(id!), enabled: Boolean(id) });
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader><DialogTitle>Chi tiết câu nói</DialogTitle><DialogDescription>Nguồn, ngữ cảnh và những lần câu nói đã xuất hiện.</DialogDescription></DialogHeader>
        {query.isLoading && <PageLoading />}
        {query.data && <QuoteDetailContent quote={query.data.quote} dates={query.data.displayedDates} />}
        {query.isError && <p className="text-sm text-red-600">Không thể tải chi tiết câu nói.</p>}
      </DialogContent>
    </Dialog>
  );
}

function QuoteDetailContent({ quote, dates }: { quote: FavoriteQuote; dates: string[] }) {
  return (
    <div className="space-y-5">
      <div className="rounded-2xl bg-emerald-50/60 p-5">
        <blockquote className="text-xl font-medium leading-8">“{quote.content}”</blockquote>
        {quote.author && <p className="mt-3 text-sm font-semibold text-emerald-900">— {quote.author}</p>}
      </div>
      {(quote.sourceTitle || quote.sourceType || quote.sourceLocation || quote.sourceUrl) && (
        <section>
          <h3 className="text-sm font-semibold">Nguồn</h3>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            {quote.sourceType ? SOURCE_LABELS[quote.sourceType] : "Nguồn khác"}
            {quote.sourceTitle ? ` · ${quote.sourceTitle}` : ""}
            {quote.sourceLocation ? ` · ${quote.sourceLocation}` : ""}
          </p>
          {quote.sourceUrl && <a href={quote.sourceUrl} target="_blank" rel="noreferrer" className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-emerald-700">Xem nguồn <ExternalLink className="size-3.5" /></a>}
        </section>
      )}
      {quote.tags.length > 0 && <section><h3 className="text-sm font-semibold">Nhãn</h3><div className="mt-2 flex flex-wrap gap-2">{quote.tags.map((tag) => <span key={tag} className="rounded-full bg-emerald-50 px-3 py-1 text-xs text-emerald-800">#{tag}</span>)}</div></section>}
      {quote.personalNote && <section><h3 className="text-sm font-semibold">Ghi chú của tôi</h3><p className="mt-2 whitespace-pre-wrap rounded-2xl bg-muted/45 p-4 text-sm leading-6">{quote.personalNote}</p></section>}
      <section><h3 className="flex items-center gap-2 text-sm font-semibold"><Clock3 className="size-4" /> Đã xuất hiện</h3><p className="mt-2 text-sm text-muted-foreground">{dates.length ? dates.map(formatDate).join(" · ") : "Chưa từng xuất hiện trên Dashboard."}</p></section>
    </div>
  );
}

function QuoteHistoryDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const query = useQuery({ queryKey: ["quotes", "history"], queryFn: () => getQuoteHistory(0, 100), enabled: open });
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader><DialogTitle>Lịch sử câu nói</DialogTitle><DialogDescription>Các câu từng được hiển thị trên Dashboard của bạn.</DialogDescription></DialogHeader>
        <div className="max-h-[60vh] space-y-3 overflow-y-auto pr-1">
          {query.isLoading && <PageLoading />}
          {query.data?.content.length === 0 && <p className="rounded-2xl border border-dashed p-8 text-center text-sm text-muted-foreground">Chưa có lịch sử hiển thị.</p>}
          {query.data?.content.map((item) => <div key={item.id} className="rounded-2xl border p-4"><p className="text-xs font-semibold text-emerald-700">{formatDate(item.displayDate)}</p><p className="mt-2 font-medium leading-6">“{item.quote.content}”</p>{item.quote.author && <p className="mt-2 text-sm text-muted-foreground">— {item.quote.author}</p>}</div>)}
          {query.isError && <p className="text-sm text-red-600">Không thể tải lịch sử câu nói.</p>}
        </div>
      </DialogContent>
    </Dialog>
  );
}

function emptyPayload(): QuotePayload {
  return { content: "", author: "", sourceTitle: "", includeInDaily: true, language: "vi", tags: [] };
}

function parseTags(value: string): string[] {
  return value.split(",").map((item) => item.trim().replace(/^#+/, "")).filter(Boolean).slice(0, 10);
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" }).format(new Date(`${value}T00:00:00`));
}

function errorMessage(error: unknown, fallback: string): string {
  return axios.isAxiosError<{ message?: string }>(error) ? error.response?.data?.message ?? fallback : fallback;
}
