CREATE TABLE catalog_import_batches (
 id varchar(255) PRIMARY KEY, actor_id varchar(255) NOT NULL,
 kind varchar(255) NOT NULL, snapshot text NOT NULL,
 created_at timestamp NOT NULL, committed_at timestamp,
 commit_digest varchar(255), source_digest varchar(64), version bigint NOT NULL DEFAULT 0
);
CREATE INDEX idx_catalog_import_actor ON catalog_import_batches(actor_id,kind,created_at DESC);
