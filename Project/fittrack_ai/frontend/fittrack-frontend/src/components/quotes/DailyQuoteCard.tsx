import { useQuery } from "@tanstack/react-query";
import { ArrowRight, Clipboard, Quote as QuoteIcon } from "lucide-react";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import { getTodayQuote } from "@/api/quote.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

export default function DailyQuoteCard() {
  const query = useQuery({
    queryKey: ["quotes", "today"],
    queryFn: getTodayQuote,
    staleTime: 5 * 60_000,
    retry: 1,
  });

  if (query.isLoading) {
    return <div className="h-44 animate-pulse rounded-3xl bg-emerald-50" aria-label="Đang tải câu nói hôm nay" />;
  }

  if (query.isError) {
    return null;
  }

  const quote = query.data?.quote;
  if (!quote) {
    return (
      <Card className="border-dashed border-emerald-200 bg-emerald-50/35">
        <CardContent className="flex flex-col items-center gap-3 py-8 text-center sm:flex-row sm:text-left">
          <span className="grid size-12 shrink-0 place-items-center rounded-2xl bg-white text-emerald-700 shadow-sm">
            <QuoteIcon className="size-6" />
          </span>
          <div className="flex-1">
            <p className="font-semibold">Bạn chưa có câu nói nào</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Lưu lại những câu khiến bạn muốn dừng lại và suy nghĩ.
            </p>
          </div>
          <Button asChild variant="outline">
            <Link to="/quotes">Thêm câu đầu tiên</Link>
          </Button>
        </CardContent>
      </Card>
    );
  }

  const copy = async () => {
    await navigator.clipboard.writeText(quote.content);
    toast.success("Đã sao chép câu nói");
  };

  return (
    <Card className="overflow-hidden border-0 bg-gradient-to-br from-[#0c2821] via-[#123c31] to-emerald-800 text-white shadow-xl shadow-emerald-950/10">
      <CardContent className="relative px-6 py-7 sm:px-8 sm:py-8">
        <QuoteIcon className="absolute right-6 top-6 size-14 text-emerald-200/15" />
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-200/75">
          Câu nói hôm nay
        </p>
        <blockquote className="mt-5 max-w-4xl text-xl font-medium leading-relaxed tracking-[-0.02em] sm:text-2xl">
          “{quote.content}”
        </blockquote>
        {(quote.author || quote.sourceTitle) && (
          <div className="mt-5 text-sm text-emerald-50/75">
            {quote.author && <p className="font-semibold text-emerald-100">— {quote.author}</p>}
            {quote.sourceTitle && (
              <p className="mt-1">
                {quote.sourceTitle}
                {quote.sourceLocation ? ` · ${quote.sourceLocation}` : ""}
              </p>
            )}
          </div>
        )}
        <div className="mt-6 flex flex-wrap gap-2">
          <Button
            type="button"
            variant="outline"
            onClick={copy}
            className="border-white/20 bg-white/10 text-white hover:bg-white/20 hover:text-white"
          >
            <Clipboard className="size-4" /> Sao chép
          </Button>
          <Button asChild className="bg-emerald-300 text-[#0c2821] hover:bg-emerald-200">
            <Link to="/quotes">Xem kho <ArrowRight className="size-4" /></Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
