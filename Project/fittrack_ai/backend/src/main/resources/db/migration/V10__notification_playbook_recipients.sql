ALTER TABLE notification_playbooks
    ADD COLUMN IF NOT EXISTS recipient_mode varchar(20) NOT NULL DEFAULT 'ALL_ACTIVE';

CREATE TABLE IF NOT EXISTS notification_playbook_recipients (
    playbook_id varchar(255) NOT NULL REFERENCES notification_playbooks(id) ON DELETE CASCADE,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (playbook_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_playbook_recipients_user
    ON notification_playbook_recipients(user_id);
