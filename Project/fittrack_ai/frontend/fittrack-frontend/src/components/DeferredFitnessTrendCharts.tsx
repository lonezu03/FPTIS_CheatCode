import { lazy, Suspense, useEffect, useRef, useState } from "react";
import type { ProgressPoint } from "@/api/dashboard.api";

const FitnessTrendCharts = lazy(() => import("./FitnessTrendCharts"));

export default function DeferredFitnessTrendCharts({ points }: { points: ProgressPoint[] }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(
    () => typeof window !== "undefined" && !("IntersectionObserver" in window),
  );

  useEffect(() => {
    const element = containerRef.current;
    if (!element || visible) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: "300px" },
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, [visible]);

  return (
    <div ref={containerRef} className="min-h-[280px]">
      {visible ? (
        <Suspense fallback={<ChartSkeleton />}>
          <FitnessTrendCharts points={points} />
        </Suspense>
      ) : (
        <ChartSkeleton />
      )}
    </div>
  );
}

function ChartSkeleton() {
  return (
    <div className="grid animate-pulse gap-4 md:gap-6 lg:grid-cols-2" aria-label="Đang tải biểu đồ">
      <div className="h-[330px] rounded-2xl border bg-muted/35" />
      <div className="h-[330px] rounded-2xl border bg-muted/35" />
    </div>
  );
}
