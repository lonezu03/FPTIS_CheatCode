CREATE TABLE IF NOT EXISTS exercise_preferences (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id varchar(255) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    preference varchar(20) NOT NULL,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_exercise_preference
        CHECK (preference IN ('FAVORITE', 'NORMAL', 'LESS', 'EXCLUDED'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_exercise_preferences_user_exercise
    ON exercise_preferences(user_id, exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_preferences_user_preference
    ON exercise_preferences(user_id, preference);

CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_completed
    ON workout_sets(exercise_id, completed);
