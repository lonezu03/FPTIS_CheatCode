ALTER TABLE journal_settings
    ADD COLUMN failed_unlock_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN locked_until TIMESTAMP(6);

ALTER TABLE journal_settings
    ADD CONSTRAINT chk_journal_failed_unlock_attempts CHECK (failed_unlock_attempts >= 0);
