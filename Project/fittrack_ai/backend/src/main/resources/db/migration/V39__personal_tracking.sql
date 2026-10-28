CREATE TABLE personal_tracking_entries (
 id varchar(255) PRIMARY KEY, owner_id varchar(255) NOT NULL REFERENCES users(id), kind varchar(20) NOT NULL,
 title varchar(160) NOT NULL, note varchar(2000), metric varchar(40), unit varchar(20), baseline numeric(18,3), target numeric(18,3),
 start_date date, target_date date, weekdays varchar(20), sleep_start timestamp, sleep_end timestamp,
 quality integer, fatigue integer, soreness integer, archived boolean NOT NULL DEFAULT false, content_revision bigint NOT NULL DEFAULT 0, version bigint NOT NULL DEFAULT 0,
 CONSTRAINT tracking_kind_check CHECK (kind IN ('BODY_GOAL','WORKOUT_GOAL','HABIT','RECOVERY')),
 CONSTRAINT tracking_ratings_check CHECK ((quality IS NULL OR quality BETWEEN 1 AND 5) AND (fatigue IS NULL OR fatigue BETWEEN 1 AND 5) AND (soreness IS NULL OR soreness BETWEEN 1 AND 5))
);
CREATE INDEX idx_tracking_owner_kind ON personal_tracking_entries(owner_id,kind,start_date);
CREATE TABLE personal_tracking_checkins (
 id varchar(255) PRIMARY KEY, entry_id varchar(255) NOT NULL REFERENCES personal_tracking_entries(id), checkin_date date NOT NULL,
 status varchar(12) NOT NULL, metric_value numeric(18,3), note varchar(1000), evidence varchar(500), UNIQUE(entry_id,checkin_date)
);
CREATE TABLE personal_goal_phases (
 id varchar(255) PRIMARY KEY, goal_id varchar(255) NOT NULL REFERENCES personal_tracking_entries(id), title varchar(120) NOT NULL,
 target_date date, target numeric(18,3) NOT NULL, position integer NOT NULL
);
CREATE INDEX idx_goal_phases ON personal_goal_phases(goal_id,position);
