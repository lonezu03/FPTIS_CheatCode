CREATE TABLE template_shares (
 id varchar(255) PRIMARY KEY,
 owner_id varchar(255) NOT NULL REFERENCES users(id), recipient_id varchar(255) NOT NULL REFERENCES users(id),
 kind varchar(30) NOT NULL CHECK (kind IN ('WORKOUT_PLAN','MEAL_COLLECTION','MEAL_WEEK')),
 source_id varchar(255) NOT NULL, title varchar(180) NOT NULL, snapshot text NOT NULL,
 operation_id varchar(100) NOT NULL, request_digest varchar(64) NOT NULL,
 active boolean NOT NULL, created_at timestamp NOT NULL, expires_at timestamp NOT NULL,
 copied_at timestamp, copy_result text, version bigint NOT NULL DEFAULT 0,
 CONSTRAINT uq_share_owner_operation UNIQUE(owner_id,operation_id),
 CONSTRAINT ck_share_not_self CHECK(owner_id <> recipient_id)
);
CREATE INDEX idx_share_recipient_created ON template_shares(recipient_id,created_at DESC);
CREATE INDEX idx_share_owner_created ON template_shares(owner_id,created_at DESC);
