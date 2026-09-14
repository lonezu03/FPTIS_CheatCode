ALTER TABLE foods ADD COLUMN barcode varchar(80);

CREATE UNIQUE INDEX uk_foods_barcode_active
    ON foods(barcode)
    WHERE barcode IS NOT NULL AND active = true;

CREATE TABLE progress_photos (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url text NOT NULL,
    taken_date date NOT NULL,
    pose varchar(30) NOT NULL,
    note varchar(500),
    weight numeric(8,2),
    created_at timestamp(6) NOT NULL,
    CONSTRAINT chk_progress_photo_pose CHECK (pose IN ('FRONT', 'SIDE', 'BACK', 'OTHER'))
);

CREATE INDEX idx_progress_photos_user_date
    ON progress_photos(user_id, taken_date DESC, created_at DESC);

CREATE TABLE todo_reminder_entries (
    id varchar(255) PRIMARY KEY,
    todo_id varchar(255) NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    scheduled_at timestamp(6) NOT NULL,
    sent_at timestamp(6),
    created_at timestamp(6) NOT NULL,
    CONSTRAINT uk_todo_reminder_time UNIQUE (todo_id, scheduled_at)
);

CREATE INDEX idx_todo_reminder_due
    ON todo_reminder_entries(scheduled_at, sent_at);
