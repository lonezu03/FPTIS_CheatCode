CREATE TABLE training_appointments (
 id varchar(255) PRIMARY KEY, user_id varchar(255) NOT NULL REFERENCES users(id),
 title varchar(255) NOT NULL, plan_id varchar(255), cycle_id varchar(255), week_number integer,
 start_at timestamp NOT NULL, snapshot_json text NOT NULL, completed_session_id varchar(255),
 completed_at timestamp, version bigint NOT NULL DEFAULT 0, created_at timestamp NOT NULL,
 CONSTRAINT uq_training_appointment_session UNIQUE(completed_session_id)
);
CREATE INDEX idx_training_appointments_user_start ON training_appointments(user_id,start_at);
CREATE INDEX idx_training_appointments_cycle ON training_appointments(user_id,cycle_id);
