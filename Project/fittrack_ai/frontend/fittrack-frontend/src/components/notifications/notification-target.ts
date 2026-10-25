import type { LunchNotification } from '@/api/lunch.api';
import type { AuthUser } from '@/store/auth.store';
import { canUseFeature } from '@/lib/feature-access';

export function notificationTarget(notification: LunchNotification, user: AuthUser | null): string {
  const reference = notification.referenceType;
  const id = notification.referenceId ? encodeURIComponent(notification.referenceId) : '';
  if (reference === 'TODO' || notification.type === 'TODO_REMINDER') {
    return canUseFeature(user, 'todoEnabled') ? `/todos${id ? `?todo=${id}` : ''}` : '/dashboard';
  }
  if (reference === 'SCHEDULE' || notification.type === 'SCHEDULE_REMINDER') {
    return canUseFeature(user, 'scheduleEnabled') ? `/schedule${id ? `?event=${id}` : ''}` : '/dashboard';
  }
  if (reference === 'JOURNAL' || notification.type === 'JOURNAL_REMINDER') {
    return canUseFeature(user, 'journalEnabled') ? '/journal' : '/dashboard';
  }
  if (reference === 'FINANCE' || notification.type.startsWith('FINANCE_')) {
    return canUseFeature(user, 'financeEnabled') ? '/finance' : '/dashboard';
  }
  if (notification.type.startsWith('HEALTH_')) {
    return canUseFeature(user, 'healthEnabled') ? '/health' : '/dashboard';
  }
  if (user?.role === 'ADMIN' && notification.type === 'MODULE_ACCESS_REQUEST') return '/admin/users';
  if (user?.role === 'ADMIN' && notification.type === 'PAYMENT_REQUEST') return '/admin/lunch?tab=payments';
  if (notification.type.startsWith('PAYMENT_')) return canUseFeature(user, 'lunchEnabled') ? '/lunch?tab=payment' : '/dashboard';
  if (reference?.startsWith('LUNCH') || notification.type.startsWith('MENU_') || notification.type.startsWith('ORDER_')) {
    return canUseFeature(user, 'lunchEnabled') ? '/lunch' : '/dashboard';
  }
  return '/dashboard';
}
