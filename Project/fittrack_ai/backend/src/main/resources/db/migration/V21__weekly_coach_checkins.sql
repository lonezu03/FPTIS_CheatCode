ALTER TABLE users
    ADD COLUMN calorie_target_override numeric(10,2),
    ADD COLUMN protein_target_override numeric(10,2);

ALTER TABLE users
    ADD CONSTRAINT chk_users_calorie_target_override
        CHECK (calorie_target_override IS NULL OR calorie_target_override BETWEEN 800 AND 10000),
    ADD CONSTRAINT chk_users_protein_target_override
        CHECK (protein_target_override IS NULL OR protein_target_override BETWEEN 10 AND 1000);

CREATE TABLE weekly_checkins (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start date NOT NULL,
    week_end date NOT NULL,
    status varchar(20) NOT NULL,
    data_sufficient boolean NOT NULL,
    confidence_percent numeric(6,2) NOT NULL,
    complete_days integer NOT NULL,
    workout_days integer NOT NULL,
    weight_change numeric(10,2),
    current_calories numeric(10,2) NOT NULL,
    proposed_calories numeric(10,2) NOT NULL,
    current_protein numeric(10,2) NOT NULL,
    proposed_protein numeric(10,2) NOT NULL,
    rationale varchar(1000) NOT NULL,
    created_at timestamp(6) NOT NULL,
    decided_at timestamp(6),
    CONSTRAINT uk_weekly_checkins_user_week UNIQUE (user_id, week_start),
    CONSTRAINT chk_weekly_checkin_status CHECK (status IN ('PENDING', 'ACCEPTED', 'IGNORED'))
);

CREATE INDEX idx_weekly_checkins_user_week
    ON weekly_checkins(user_id, week_start DESC);
