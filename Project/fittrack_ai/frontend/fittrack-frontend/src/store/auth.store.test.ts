import { beforeEach, describe, expect, it } from 'vitest';
import { useAuthStore, type AuthUser } from './auth.store';

describe('logout draft cleanup', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); });
  it('clears the current account drafts but retains preferences and other accounts', () => {
    useAuthStore.setState({ user: { userId: 'one' } as AuthUser, token: 'test' });
    const keys = ['fittrack:todo:one:draft', 'fittrack:schedule:one:draft', 'fittrack:finance-draft:one', 'fittrack:meal-draft:one:2026-10-25:LUNCH', 'fittrack-session-draft:one:workout'];
    keys.forEach(key => localStorage.setItem(key, 'draft'));
    sessionStorage.setItem('fittrack-session-draft:one:journal-entry:new', 'private');
    localStorage.setItem('fittrack:todo:one:filters', 'preferences');
    localStorage.setItem('fittrack:finance-draft:one-other', 'other account');
    useAuthStore.getState().logout();
    keys.forEach(key => expect(localStorage.getItem(key)).toBeNull());
    expect(sessionStorage.getItem('fittrack-session-draft:one:journal-entry:new')).toBeNull();
    expect(localStorage.getItem('fittrack:todo:one:filters')).toBe('preferences');
    expect(localStorage.getItem('fittrack:finance-draft:one-other')).toBe('other account');
    expect(useAuthStore.getState().token).toBeNull();
  });
});
