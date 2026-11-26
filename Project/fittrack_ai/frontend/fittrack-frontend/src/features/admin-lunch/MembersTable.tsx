import { HandCoins } from "lucide-react";

import type { LunchMember } from "@/api/lunch.api";
import DataPagination from "@/components/common/DataPagination";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { usePagination } from "@/hooks/usePagination";
import { formatCurrency } from "@/lib/format";

/** Member balances and debts; choosing a member fills the adjustment form. */
export default function MembersTable({
  members,
  onSelect,
}: {
  members: LunchMember[];
  onSelect: (memberId: string) => void;
}) {
  const pagination = usePagination(members);
  return (
    <>
      <div className="hidden md:block">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Thành viên</TableHead>
              <TableHead>Số dư</TableHead>
              <TableHead>Công nợ</TableHead>
              <TableHead className="text-right">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pagination.paginatedItems.map((member) => (
              <TableRow key={member.id}>
                <TableCell>
                  <div>
                    <p className="font-medium">{member.fullName}</p>
                    <p className="text-xs text-muted-foreground">{member.email}</p>
                  </div>
                </TableCell>
                <TableCell className={member.walletBalance < 0 ? "font-semibold text-red-700" : "font-semibold"}>
                  {formatCurrency(member.walletBalance)}
                </TableCell>
                <TableCell>
                  {member.outstandingDebt > 0 ? (
                    <Badge className="border-amber-200 bg-amber-50 text-amber-800" variant="outline">
                      {formatCurrency(member.outstandingDebt)}
                    </Badge>
                  ) : (
                    <span className="text-xs text-muted-foreground">Không có</span>
                  )}
                </TableCell>
                <TableCell className="text-right">
                  <Button type="button" variant="outline" size="sm" onClick={() => onSelect(member.id)}>
                    <HandCoins aria-hidden="true" />
                    Nạp quỹ
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="grid gap-2 md:hidden">
        {pagination.paginatedItems.map((member) => (
          <button
            key={member.id}
            type="button"
            onClick={() => onSelect(member.id)}
            className="flex items-center justify-between gap-3 rounded-xl border bg-white p-3 text-left transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400"
          >
            <span className="min-w-0">
              <span className="block truncate font-semibold">{member.fullName}</span>
              <span className="block truncate text-xs text-muted-foreground">{member.email}</span>
            </span>
            <span className="shrink-0 text-right">
              <span className="block font-bold">{formatCurrency(member.walletBalance)}</span>
              <span className={member.outstandingDebt > 0 ? "block text-xs text-red-700" : "block text-xs text-muted-foreground"}>
                Nợ {formatCurrency(member.outstandingDebt)}
              </span>
            </span>
          </button>
        ))}
      </div>
      <DataPagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        totalItems={pagination.totalItems}
        totalPages={pagination.totalPages}
        onPageChange={pagination.setPage}
        onPageSizeChange={pagination.setPageSize}
      />
    </>
  );
}
