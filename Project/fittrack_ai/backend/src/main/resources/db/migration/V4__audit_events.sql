CREATE TABLE IF NOT EXISTS audit_events (
    id varchar(255) PRIMARY KEY,
    actor_id varchar(255),
    actor_email varchar(255),
    action varchar(80) NOT NULL,
    resource_type varchar(80) NOT NULL,
    resource_id varchar(255),
    details text,
    request_id varchar(64),
    client_address varchar(80),
    created_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_events_created ON audit_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_actor ON audit_events(actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_resource ON audit_events(resource_type, resource_id);
