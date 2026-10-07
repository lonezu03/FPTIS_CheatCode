-- Defaults affect only future rows. Preserve permissions of existing users.
ALTER TABLE users ALTER COLUMN lunch_enabled SET DEFAULT false;
ALTER TABLE users ALTER COLUMN fitness_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN health_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN chatbot_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN todo_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN schedule_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN quote_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN finance_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN journal_enabled SET DEFAULT true;

-- Calendar reads start with the owner, then prune by the bounded window.
CREATE INDEX IF NOT EXISTS idx_todos_calendar_owner_anchor
    ON todos (user_id, (coalesce(start_at, due_at)))
    WHERE coalesce(start_at, due_at) IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_schedule_calendar_owner_repeat
    ON schedule_items (user_id, repeat_rule, start_at, repeat_end_at)
    WHERE enabled = true;
CREATE INDEX IF NOT EXISTS idx_schedule_reminder_active_window
    ON schedule_items (repeat_rule, start_at, repeat_end_at)
    WHERE enabled = true AND reminder_enabled = true;
