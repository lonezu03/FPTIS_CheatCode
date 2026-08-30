ALTER TABLE todos
    ADD COLUMN IF NOT EXISTS recurrence_basis varchar(30) NOT NULL DEFAULT 'SCHEDULED_DATE',
    ADD COLUMN IF NOT EXISTS recurrence_end_at timestamp(6),
    ADD COLUMN IF NOT EXISTS recurrence_max_occurrences integer,
    ADD COLUMN IF NOT EXISTS occurrence_number integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS completed_at timestamp(6),
    ADD COLUMN IF NOT EXISTS skipped_at timestamp(6);

WITH ranked AS (
    SELECT id,
           row_number() OVER (
               PARTITION BY user_id, recurring_series_id
               ORDER BY COALESCE(due_at, start_at, reminder_at, created_at), created_at, id
           ) AS sequence_number
    FROM todos
    WHERE recurring_series_id IS NOT NULL
)
UPDATE todos
SET occurrence_number = ranked.sequence_number
FROM ranked
WHERE todos.id = ranked.id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_todos_series_occurrence
    ON todos(user_id, recurring_series_id, occurrence_number)
    WHERE recurring_series_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_todos_calendar_range ON todos(user_id, start_at, due_at);

ALTER TABLE schedule_items
    ADD COLUMN IF NOT EXISTS repeat_interval integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS repeat_end_at timestamp(6);

CREATE INDEX IF NOT EXISTS idx_schedule_user_enabled_start
    ON schedule_items(user_id, enabled, start_at);
