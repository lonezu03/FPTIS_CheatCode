CREATE TABLE music_practice_sessions (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instrument varchar(10) NOT NULL,
    practiced_on date NOT NULL,
    minutes integer NOT NULL,
    exercise_key varchar(60) NOT NULL,
    bpm integer,
    note varchar(500),
    created_at timestamp(6) NOT NULL,
    CONSTRAINT music_practice_sessions_instrument_check CHECK (instrument IN ('GUITAR', 'FLUTE')),
    CONSTRAINT music_practice_sessions_minutes_check CHECK (minutes BETWEEN 1 AND 600),
    CONSTRAINT music_practice_sessions_bpm_check CHECK (bpm IS NULL OR bpm BETWEEN 20 AND 300),
    CONSTRAINT music_practice_sessions_exercise_key_check CHECK (char_length(exercise_key) BETWEEN 1 AND 60)
);

CREATE INDEX idx_music_practice_user_practiced_on
    ON music_practice_sessions (user_id, practiced_on);
