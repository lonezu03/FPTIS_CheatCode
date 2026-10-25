import { describe, expect, it } from 'vitest';
import { notificationTarget } from './notification-target';
import type { LunchNotification } from '@/api/lunch.api';
import type { AuthUser } from '@/store/auth.store';

const user = { role: 'USER', todoEnabled: true, scheduleEnabled: true, financeEnabled: true } as AuthUser;
const notification = (type: string, referenceType?: string, referenceId?: string) => ({ type, referenceType, referenceId }) as LunchNotification;

describe('notification destinations', () => {
  it('opens the exact Todo or event with encoded identifiers', () => {
    expect(notificationTarget(notification('TODO_REMINDER', 'TODO', 'id/1'), user)).toBe('/todos?todo=id%2F1');
    expect(notificationTarget(notification('SCHEDULE_REMINDER', 'SCHEDULE', 'event-1'), user)).toBe('/schedule?event=event-1');
  });
  it('honors module access and sends generic messages to Dashboard', () => {
    expect(notificationTarget(notification('TODO_REMINDER', 'TODO', '1'), { ...user, todoEnabled: false })).toBe('/dashboard');
    expect(notificationTarget(notification('ANNOUNCEMENT'), user)).toBe('/dashboard');
    expect(notificationTarget(notification('FINANCE_BILL_DUE', 'FINANCE_RECURRING'), user)).toBe('/finance');
  });
  it('retains admin payment links and admin module bypass', () => {
    const admin = { ...user, role: 'ADMIN', todoEnabled: false } as AuthUser;
    expect(notificationTarget(notification('PAYMENT_REQUEST'), admin)).toBe('/admin/lunch?tab=payments');
    expect(notificationTarget(notification('TODO_REMINDER', 'TODO', '1'), admin)).toBe('/todos?todo=1');
  });
});
