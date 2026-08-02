ALTER TABLE health_reminders ADD COLUMN IF NOT EXISTS last_triggered_at timestamp(6);
ALTER TABLE health_reminders ADD COLUMN IF NOT EXISTS next_run_at timestamp(6);
ALTER TABLE health_reminders ADD COLUMN IF NOT EXISTS version bigint;

ALTER TABLE lunch_notifications ADD COLUMN IF NOT EXISTS deduplication_key varchar(180);
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_notifications_deduplication
    ON lunch_notifications(deduplication_key)
    WHERE deduplication_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_health_reminders_due_v2
    ON health_reminders(enabled, next_run_at);
