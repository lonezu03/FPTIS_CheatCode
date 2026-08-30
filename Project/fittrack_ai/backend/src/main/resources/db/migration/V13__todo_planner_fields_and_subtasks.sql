ALTER TABLE todos
    ADD COLUMN IF NOT EXISTS start_at timestamp(6),
    ADD COLUMN IF NOT EXISTS estimated_minutes integer,
    ADD COLUMN IF NOT EXISTS category varchar(30) NOT NULL DEFAULT 'PERSONAL',
    ADD COLUMN IF NOT EXISTS recurrence_rule varchar(20) NOT NULL DEFAULT 'NONE',
    ADD COLUMN IF NOT EXISTS recurrence_interval integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS days_of_week varchar(100),
    ADD COLUMN IF NOT EXISTS recurring_series_id varchar(255);

CREATE INDEX IF NOT EXISTS idx_todos_user_start ON todos(user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_todos_user_category ON todos(user_id, category, due_at);
CREATE INDEX IF NOT EXISTS idx_todos_recurring_series ON todos(user_id, recurring_series_id);

CREATE TABLE IF NOT EXISTS todo_subtasks (
    id varchar(255) PRIMARY KEY,
    todo_id varchar(255) NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    title varchar(240) NOT NULL,
    completed boolean NOT NULL DEFAULT false,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_todo_subtasks_todo_order ON todo_subtasks(todo_id, sort_order);
