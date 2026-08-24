ALTER TABLE user_auth_tokens
    ADD COLUMN IF NOT EXISTS failed_attempts integer DEFAULT 0;

UPDATE user_auth_tokens
SET failed_attempts = 0
WHERE failed_attempts IS NULL;

ALTER TABLE user_auth_tokens
    ALTER COLUMN failed_attempts SET NOT NULL;
