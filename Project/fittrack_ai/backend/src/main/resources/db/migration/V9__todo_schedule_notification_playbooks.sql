ALTER TABLE users ADD COLUMN IF NOT EXISTS todo_enabled boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS schedule_enabled boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS todos (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title varchar(180) NOT NULL,
    description varchar(1000),
    status varchar(20) NOT NULL DEFAULT 'OPEN',
    priority varchar(20) NOT NULL DEFAULT 'MEDIUM',
    due_at timestamp(6),
    reminder_at timestamp(6),
    reminder_enabled boolean NOT NULL DEFAULT false,
    reminder_sent_at timestamp(6),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_todos_user_status_due ON todos(user_id, status, due_at);
CREATE INDEX IF NOT EXISTS idx_todos_reminders ON todos(reminder_enabled, reminder_at, reminder_sent_at);

CREATE TABLE IF NOT EXISTS schedule_items (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title varchar(180) NOT NULL,
    description varchar(1000),
    category varchar(30) NOT NULL DEFAULT 'PERSONAL',
    start_at timestamp(6) NOT NULL,
    end_at timestamp(6),
    repeat_rule varchar(20) NOT NULL DEFAULT 'NONE',
    days_of_week varchar(100),
    reminder_minutes integer NOT NULL DEFAULT 10,
    reminder_enabled boolean NOT NULL DEFAULT true,
    enabled boolean NOT NULL DEFAULT true,
    last_reminded_at timestamp(6),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_schedule_user_start ON schedule_items(user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_schedule_reminders ON schedule_items(enabled, reminder_enabled, start_at);

CREATE TABLE IF NOT EXISTS notification_playbooks (
    id varchar(255) PRIMARY KEY,
    created_by_id varchar(255) REFERENCES users(id),
    name varchar(180) NOT NULL,
    category varchar(30) NOT NULL DEFAULT 'WELLNESS',
    mode varchar(20) NOT NULL DEFAULT 'FIXED',
    trigger_time time(6) NOT NULL,
    days_of_week varchar(100) NOT NULL DEFAULT 'MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY',
    messages text NOT NULL,
    condition_type varchar(30) NOT NULL DEFAULT 'ANY',
    threshold numeric(12,2),
    enabled boolean NOT NULL DEFAULT true,
    last_triggered_date date,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_notification_playbooks_due ON notification_playbooks(enabled, trigger_time, last_triggered_date);
