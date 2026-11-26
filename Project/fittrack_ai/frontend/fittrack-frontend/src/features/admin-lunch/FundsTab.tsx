import { AlertTriangle, HandCoins, Users } from "lucide-react";

import type { LunchFundAdjustmentAction, LunchMember } from "@/api/lunch.api";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { formatCurrency } from "@/lib/format";
import { AdminEmptyState, AdminListSkeleton, AdminQueryError, Field } from "./AdminLunchParts";
import MembersTable from "./MembersTable";
import { FUND_PRESETS, fundActionHint, fundAmountLabel, fundButtonVerb } from "./admin-lunch-utils";
import type { FundAdjustmentState } from "./useFundAdjustment";

/** "Quỹ & công nợ" tab: manual adjustment form and member balances. */
export default function FundsTab({ fund, membersQuery, members }: {
  fund: FundAdjustmentState;
  membersQuery: { isLoading: boolean; isError: boolean; error: unknown; refetch: () => unknown };
  members: LunchMember[];
}) {
  const selectedMember = members.find((member) => member.id === fund.selectedMemberId);
  return (
    <div className="grid gap-4 lg:grid-cols-[minmax(280px,0.7fr)_minmax(0,1.3fr)] lg:gap-6">
      <Card className="h-fit">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HandCoins className="h-5 w-5" aria-hidden="true" />
            Điều chỉnh quỹ & công nợ
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <Field label="Thành viên" htmlFor="fund-member">
            <select
              id="fund-member"
              value={fund.selectedMemberId}
              onChange={(event) => fund.setSelectedMemberId(event.target.value)}
              disabled={membersQuery.isLoading}
              className="h-9 w-full rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50"
            >
              <option value="">Chọn người đã nộp tiền...</option>
              {members.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.fullName} · {formatCurrency(member.walletBalance)}
                </option>
              ))}
            </select>
          </Field>

          {selectedMember && (
            <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-50 p-3 text-sm">
              <div>
                <p className="text-xs text-muted-foreground">Số dư hiện tại</p>
                <p className="mt-1 font-bold">{formatCurrency(selectedMember.walletBalance)}</p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Công nợ</p>
                <p className={selectedMember.outstandingDebt > 0 ? "mt-1 font-bold text-red-700" : "mt-1 font-bold"}>
                  {formatCurrency(selectedMember.outstandingDebt)}
                </p>
              </div>
            </div>
          )}

          <Field label="Thao tác" htmlFor="fund-action">
            <select
              id="fund-action"
              value={fund.action}
              onChange={(event) => fund.setAction(event.target.value as LunchFundAdjustmentAction)}
              className="h-9 w-full rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
            >
              <option value="ADD_FUND">Cộng tiền vào quỹ</option>
              <option value="REMOVE_FUND">Trừ tiền khỏi quỹ</option>
              <option value="ADD_DEBT">Ghi tăng công nợ</option>
              <option value="REMOVE_DEBT">Ghi giảm công nợ</option>
            </select>
          </Field>

          <Field label={fundAmountLabel(fund.action)} htmlFor="fund-amount">
            <Input
              id="fund-amount"
              type="number"
              min={1_000}
              step={1_000}
              value={fund.amount}
              onChange={(event) => fund.setAmount(Number(event.target.value))}
            />
          </Field>
          <div className="grid grid-cols-3 gap-2">
            {FUND_PRESETS.map((amount) => (
              <Button
                key={amount}
                type="button"
                size="sm"
                variant={fund.amount === amount ? "secondary" : "outline"}
                onClick={() => fund.setAmount(amount)}
              >
                {amount / 1_000}k
              </Button>
            ))}
          </div>

          <Field label="Ghi chú đối soát" htmlFor="fund-note">
            <Input
              id="fund-note"
              value={fund.note}
              onChange={(event) => fund.setNote(event.target.value)}
              maxLength={250}
              placeholder="Ví dụ: nhận chuyển khoản 25-07"
            />
          </Field>

          <Alert>
            <AlertTriangle />
            <AlertTitle>Điều chỉnh có kiểm soát</AlertTitle>
            <AlertDescription>{fundActionHint(fund.action)}</AlertDescription>
          </Alert>

          <Button
            type="button"
            className="w-full"
            onClick={fund.submit}
            disabled={!fund.selectedMemberId || fund.pending}
          >
            <HandCoins aria-hidden="true" />
            {fund.pending ? "Đang ghi nhận..." : `${fundButtonVerb(fund.action)} ${formatCurrency(fund.amount)}`}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-3">
            <CardTitle>Quỹ thành viên</CardTitle>
            <Badge variant="secondary">{members.length} người</Badge>
          </div>
        </CardHeader>
        <CardContent>
          {membersQuery.isLoading ? (
            <AdminListSkeleton />
          ) : membersQuery.isError ? (
            <AdminQueryError
              title="Không tải được danh sách thành viên"
              error={membersQuery.error}
              onRetry={() => void membersQuery.refetch()}
            />
          ) : members.length === 0 ? (
            <AdminEmptyState
              icon={Users}
              title="Chưa có thành viên"
              description="Tài khoản nhân viên sẽ xuất hiện tại đây."
            />
          ) : (
            <MembersTable members={members} onSelect={fund.setSelectedMemberId} />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
