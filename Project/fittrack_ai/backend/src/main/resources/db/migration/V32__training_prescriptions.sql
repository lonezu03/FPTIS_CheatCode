ALTER TABLE workout_plan_exercises
    ADD COLUMN rest_seconds integer,
    ADD COLUMN min_reps integer,
    ADD COLUMN max_reps integer,
    ADD COLUMN coaching_note varchar(1000);
ALTER TABLE workout_plans ADD COLUMN version bigint NOT NULL DEFAULT 0;
ALTER TABLE workout_plans ADD COLUMN updated_at timestamp;
