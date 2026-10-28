ALTER TABLE workout_sets ADD COLUMN original_exercise_id varchar(255) REFERENCES exercises(id);
ALTER TABLE workout_sets ADD COLUMN replacement_kind varchar(12) CHECK(replacement_kind IN ('MANUAL','ALTERNATIVE'));
ALTER TABLE personal_tracking_entries ADD COLUMN habit_archived_on date;
UPDATE personal_tracking_entries SET habit_archived_on=(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date WHERE kind='HABIT' AND archived=true;
CREATE TABLE habit_schedule_history (
 id varchar(255) PRIMARY KEY,
 entry_id varchar(255) NOT NULL REFERENCES personal_tracking_entries(id) ON DELETE CASCADE,
 effective_from date NOT NULL,
 weekdays varchar(20) NOT NULL DEFAULT '',
 CONSTRAINT uq_habit_schedule_effective UNIQUE(entry_id,effective_from)
);
-- Existing periods have no trustworthy historical weekday schedule. Start verification now.
INSERT INTO habit_schedule_history(id,entry_id,effective_from,weekdays)
SELECT id,id,GREATEST(start_date,(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date),COALESCE(weekdays,'')
FROM personal_tracking_entries WHERE kind='HABIT';
