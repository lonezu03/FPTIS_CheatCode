ALTER TABLE workout_plan_exercises ADD COLUMN group_key varchar(60), ADD COLUMN group_type varchar(12),
 ADD COLUMN group_rounds integer, ADD COLUMN between_exercise_rest_seconds integer, ADD COLUMN between_round_rest_seconds integer;
ALTER TABLE workout_sets ADD COLUMN group_key varchar(60), ADD COLUMN group_type varchar(12),
 ADD COLUMN group_rounds integer, ADD COLUMN between_exercise_rest_seconds integer, ADD COLUMN between_round_rest_seconds integer;
CREATE TABLE training_cycles (
 id varchar(255) PRIMARY KEY, user_id varchar(255) NOT NULL REFERENCES users(id),
 name varchar(180) NOT NULL, start_date date NOT NULL, weeks_json text NOT NULL,
 version bigint NOT NULL DEFAULT 0, created_at timestamp NOT NULL
);
CREATE INDEX idx_training_cycles_user_start ON training_cycles(user_id,start_date DESC);
