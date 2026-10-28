CREATE TABLE focus_sessions (
 id varchar(255) PRIMARY KEY, owner_id varchar(255) NOT NULL REFERENCES users(id), todo_id varchar(255),
 title varchar(180) NOT NULL, category varchar(30) NOT NULL, mode varchar(10) NOT NULL CHECK(mode IN ('FOCUS','BREAK')),
 state varchar(12) NOT NULL CHECK(state IN ('RUNNING','PAUSED','COMPLETED','CANCELLED')),
 planned_seconds integer NOT NULL CHECK(planned_seconds BETWEEN 60 AND 10800),
 accumulated_seconds integer NOT NULL DEFAULT 0 CHECK(accumulated_seconds BETWEEN 0 AND 28800),
 created_at timestamp NOT NULL, running_since timestamp, ended_at timestamp, review_required boolean NOT NULL DEFAULT false,
 version bigint NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX uq_focus_active_owner ON focus_sessions(owner_id) WHERE state IN ('RUNNING','PAUSED');
CREATE INDEX idx_focus_owner_created ON focus_sessions(owner_id,created_at DESC,id);
CREATE TABLE focus_operations (
 id varchar(255) PRIMARY KEY, owner_id varchar(255) NOT NULL REFERENCES users(id), operation_id varchar(80) NOT NULL,
 fingerprint varchar(64) NOT NULL, result_json text NOT NULL, UNIQUE(owner_id,operation_id)
);
