ALTER TABLE foods
    ADD COLUMN IF NOT EXISTS serving_size_grams double precision,
    ADD COLUMN IF NOT EXISTS data_source_type varchar(30) NOT NULL DEFAULT 'ESTIMATED',
    ADD COLUMN IF NOT EXISTS data_source_name varchar(255),
    ADD COLUMN IF NOT EXISTS verified boolean NOT NULL DEFAULT false;

UPDATE foods
SET serving_size_grams = 100
WHERE serving_size_grams IS NULL
  AND lower(coalesce(unit, '')) ~ '^\s*100\s*(g|gram|ml)\s*$';

ALTER TABLE foods
    DROP CONSTRAINT IF EXISTS foods_data_source_type_check;

ALTER TABLE foods
    ADD CONSTRAINT foods_data_source_type_check CHECK (
        data_source_type IN (
            'VERIFIED_DATABASE',
            'PRODUCT_LABEL',
            'RECIPE_CALCULATED',
            'COMMUNITY',
            'ESTIMATED'
        )
    );

ALTER TABLE meal_items
    ADD COLUMN IF NOT EXISTS serving_amount double precision,
    ADD COLUMN IF NOT EXISTS serving_unit varchar(20) NOT NULL DEFAULT 'SERVING',
    ADD COLUMN IF NOT EXISTS grams_equivalent double precision;

UPDATE meal_items
SET serving_amount = quantity
WHERE serving_amount IS NULL;

ALTER TABLE meal_items
    DROP CONSTRAINT IF EXISTS meal_items_serving_unit_check;

ALTER TABLE meal_items
    ADD CONSTRAINT meal_items_serving_unit_check
        CHECK (serving_unit IN ('SERVING', 'GRAM', 'ML'));

CREATE TABLE IF NOT EXISTS nutrition_day_states (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date date NOT NULL,
    status varchar(20) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT uk_nutrition_day_state_user_date UNIQUE (user_id, log_date),
    CONSTRAINT nutrition_day_state_status_check CHECK (
        status IN ('COMPLETE', 'PARTIAL', 'UNLOGGED', 'FASTING')
    )
);

CREATE INDEX IF NOT EXISTS idx_nutrition_day_states_user_date
    ON nutrition_day_states(user_id, log_date DESC);

CREATE TABLE IF NOT EXISTS water_logs (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_ml integer NOT NULL,
    logged_at timestamp(6) NOT NULL,
    CONSTRAINT water_logs_amount_check CHECK (amount_ml BETWEEN 1 AND 10000)
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_logged_at
    ON water_logs(user_id, logged_at DESC);
