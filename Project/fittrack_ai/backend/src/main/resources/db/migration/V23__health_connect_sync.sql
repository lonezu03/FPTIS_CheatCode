CREATE TABLE health_connect_records (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider varchar(40) NOT NULL,
    external_id varchar(255) NOT NULL,
    record_type varchar(40) NOT NULL,
    source_name varchar(160),
    start_at timestamp(6) NOT NULL,
    end_at timestamp(6),
    numeric_value numeric(18,4),
    unit varchar(40),
    created_at timestamp(6) NOT NULL,
    CONSTRAINT uk_health_connect_external UNIQUE (user_id, provider, external_id),
    CONSTRAINT chk_health_connect_type
        CHECK (record_type IN ('WEIGHT', 'STEPS', 'HEART_RATE', 'EXERCISE_SESSION'))
);

CREATE INDEX idx_health_connect_user_type_time
    ON health_connect_records(user_id, record_type, start_at DESC);
