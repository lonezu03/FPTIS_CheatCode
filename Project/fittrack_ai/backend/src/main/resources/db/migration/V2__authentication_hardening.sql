ALTER TABLE users ADD COLUMN IF NOT EXISTS password_change_required boolean DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS token_version bigint DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS assistant_consent boolean DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS assistant_consent_at timestamp(6);

UPDATE users SET password_change_required = false WHERE password_change_required IS NULL;
UPDATE users SET token_version = 0 WHERE token_version IS NULL;
UPDATE users SET assistant_consent = false WHERE assistant_consent IS NULL;

-- Existing administrators using a legacy/bootstrap password must explicitly
-- confirm a new password on their next session.
UPDATE users
SET password_change_required = true
WHERE upper(coalesce(role, 'USER')) = 'ADMIN';

ALTER TABLE users ALTER COLUMN password_change_required SET NOT NULL;
ALTER TABLE users ALTER COLUMN token_version SET NOT NULL;
ALTER TABLE users ALTER COLUMN assistant_consent SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_auth_tokens_expires_at
    ON user_auth_tokens(expires_at);
