-- Favorite quotes are an independently grantable module. New and existing
-- regular accounts remain disabled until an administrator grants access.
ALTER TABLE users
    ADD COLUMN quote_enabled BOOLEAN NOT NULL DEFAULT FALSE;
