-- New accounts start with lunch ordering only. Existing account permissions
-- are intentionally preserved and remain manageable by administrators.
ALTER TABLE users ALTER COLUMN lunch_enabled SET DEFAULT true;
ALTER TABLE users ALTER COLUMN fitness_enabled SET DEFAULT false;
ALTER TABLE users ALTER COLUMN health_enabled SET DEFAULT false;
ALTER TABLE users ALTER COLUMN chatbot_enabled SET DEFAULT false;
