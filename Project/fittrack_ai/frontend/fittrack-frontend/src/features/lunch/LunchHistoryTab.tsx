import type { UseQueryResult } from "@tanstack/react-query";
import { History, ReceiptText } from "lucide-react";

import type { LunchOrder } from "@/api/lunch.api";
import LunchOrderCard from "@/components/lunch/LunchOrderCard";
import { getApiErrorMessage } from "@/lib/format";
import { EmptySection, ListSkeleton, QueryError, SectionHeading } from "./lunch-ui";

/** Tab "Lịch sử": các phần đã đặt; chỉ người nhận được đánh giá món. */
export default function LunchHistoryTab({
  historyQuery,
  currentUserId,
  onReview,
}: {
  historyQuery: UseQueryResult<LunchOrder[]>;
  currentUserId?: string;
  onReview: (order: LunchOrder) => void;
}) {
  const history = historyQuery.data ?? [];
  return (
    <>
      <SectionHeading icon={History} title="Lịch sử đặt cơm" />
      {historyQuery.isLoading ? (
        <ListSkeleton />
      ) : historyQuery.isError ? (
        <QueryError
          title="Không tải được lịch sử"
          message={getApiErrorMessage(historyQuery.error, "Vui lòng thử lại.")}
          onRetry={() => void historyQuery.refetch()}
        />
      ) : history.length === 0 ? (
        <EmptySection icon={ReceiptText} title="Chưa có lịch sử" description="Các phần đã đặt sẽ xuất hiện tại đây." />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {history.map((order) => (
            <LunchOrderCard
              key={order.id}
              order={order}
              onReview={order.beneficiary.id === currentUserId ? onReview : undefined}
            />
          ))}
        </div>
      )}
    </>
  );
}
