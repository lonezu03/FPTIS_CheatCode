CREATE TABLE rate_limit_buckets (
 bucket_key varchar(200) PRIMARY KEY,
 hit_count integer NOT NULL CHECK(hit_count >= 1),
 window_ends_at timestamp with time zone NOT NULL
);
CREATE INDEX idx_rate_limit_buckets_window_ends_at ON rate_limit_buckets(window_ends_at);
