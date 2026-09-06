CREATE TABLE favorite_quotes (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content text NOT NULL,
    author varchar(255),
    source_type varchar(30),
    source_title varchar(500),
    source_url text,
    source_location varchar(255),
    personal_note text,
    include_in_daily boolean NOT NULL DEFAULT true,
    status varchar(20) NOT NULL DEFAULT 'ACTIVE',
    language varchar(10),
    content_hash varchar(64) NOT NULL,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    archived_at timestamp(6),
    CONSTRAINT favorite_quotes_status_check CHECK (status IN ('ACTIVE', 'ARCHIVED')),
    CONSTRAINT favorite_quotes_source_type_check CHECK (
        source_type IS NULL OR source_type IN (
            'BOOK', 'ARTICLE', 'VIDEO', 'PODCAST', 'SONG', 'MOVIE',
            'CONVERSATION', 'SOCIAL_POST', 'OTHER'
        )
    )
);

CREATE INDEX idx_favorite_quotes_user_status_updated
    ON favorite_quotes(user_id, status, updated_at DESC);
CREATE INDEX idx_favorite_quotes_user_hash
    ON favorite_quotes(user_id, content_hash);

CREATE TABLE quote_tags (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name varchar(80) NOT NULL,
    created_at timestamp(6) NOT NULL,
    CONSTRAINT uq_quote_tags_user_name UNIQUE (user_id, name)
);

CREATE INDEX idx_quote_tags_user_name ON quote_tags(user_id, name);

CREATE TABLE quote_tag_links (
    quote_id varchar(255) NOT NULL REFERENCES favorite_quotes(id) ON DELETE CASCADE,
    tag_id varchar(255) NOT NULL REFERENCES quote_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (quote_id, tag_id)
);

CREATE TABLE daily_quote_displays (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quote_id varchar(255) NOT NULL REFERENCES favorite_quotes(id) ON DELETE CASCADE,
    display_date date NOT NULL,
    cycle_number integer NOT NULL,
    created_at timestamp(6) NOT NULL,
    CONSTRAINT daily_quote_cycle_positive CHECK (cycle_number > 0),
    CONSTRAINT uq_daily_quote_user_date UNIQUE (user_id, display_date),
    CONSTRAINT uq_daily_quote_user_quote_cycle UNIQUE (user_id, quote_id, cycle_number)
);

CREATE INDEX idx_daily_quote_user_cycle
    ON daily_quote_displays(user_id, cycle_number);
CREATE INDEX idx_daily_quote_user_date
    ON daily_quote_displays(user_id, display_date DESC);
