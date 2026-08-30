ALTER TABLE workout_sets
    ADD COLUMN IF NOT EXISTS exercise_order integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS set_type varchar(20) NOT NULL DEFAULT 'NORMAL',
    ADD COLUMN IF NOT EXISTS rest_seconds integer NOT NULL DEFAULT 90,
    ADD COLUMN IF NOT EXISTS completed boolean NOT NULL DEFAULT true;

ALTER TABLE workout_sets
    DROP CONSTRAINT IF EXISTS workout_sets_set_type_check;

ALTER TABLE workout_sets
    ADD CONSTRAINT workout_sets_set_type_check
        CHECK (set_type IN ('WARMUP', 'NORMAL', 'DROP', 'FAILURE'));

ALTER TABLE workout_sets
    DROP CONSTRAINT IF EXISTS workout_sets_rest_seconds_check;

ALTER TABLE workout_sets
    ADD CONSTRAINT workout_sets_rest_seconds_check
        CHECK (rest_seconds BETWEEN 0 AND 1800);

CREATE INDEX IF NOT EXISTS idx_workout_sets_session_exercise_order
    ON workout_sets(session_id, exercise_order, set_number);
