-- FitTrack production baseline.
-- Existing databases are baselined at version 0, therefore this migration is
-- intentionally idempotent and can also repair columns introduced before
-- Flyway was adopted.

CREATE TABLE IF NOT EXISTS users (
    id varchar(255) PRIMARY KEY,
    email varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    full_name varchar(255),
    gender varchar(255),
    age integer,
    height float(53),
    weight float(53),
    goal varchar(255),
    activity_level varchar(255),
    role varchar(255),
    active boolean NOT NULL DEFAULT true,
    email_verified boolean NOT NULL DEFAULT true,
    lunch_enabled boolean NOT NULL DEFAULT true,
    fitness_enabled boolean NOT NULL DEFAULT true,
    health_enabled boolean NOT NULL DEFAULT true,
    chatbot_enabled boolean NOT NULL DEFAULT true,
    created_at timestamp(6)
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS active boolean DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified boolean DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS lunch_enabled boolean DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fitness_enabled boolean DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS health_enabled boolean DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS chatbot_enabled boolean DEFAULT true;
UPDATE users SET active = true WHERE active IS NULL;
UPDATE users SET email_verified = true WHERE email_verified IS NULL;
UPDATE users SET lunch_enabled = true WHERE lunch_enabled IS NULL;
UPDATE users SET fitness_enabled = true WHERE fitness_enabled IS NULL;
UPDATE users SET health_enabled = true WHERE health_enabled IS NULL;
UPDATE users SET chatbot_enabled = true WHERE chatbot_enabled IS NULL;
ALTER TABLE users ALTER COLUMN active SET NOT NULL;
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;
ALTER TABLE users ALTER COLUMN lunch_enabled SET NOT NULL;
ALTER TABLE users ALTER COLUMN fitness_enabled SET NOT NULL;
ALTER TABLE users ALTER COLUMN health_enabled SET NOT NULL;
ALTER TABLE users ALTER COLUMN chatbot_enabled SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_users_email ON users (lower(email));

CREATE TABLE IF NOT EXISTS user_auth_tokens (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash varchar(64) NOT NULL,
    type varchar(30) NOT NULL,
    expires_at timestamp(6) NOT NULL,
    used_at timestamp(6),
    created_at timestamp(6) NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_auth_token_hash ON user_auth_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_auth_token_hash ON user_auth_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_auth_token_user_type ON user_auth_tokens(user_id, type);

CREATE TABLE IF NOT EXISTS foods (
    id varchar(255) PRIMARY KEY,
    name varchar(255) NOT NULL,
    calories float(53),
    protein float(53),
    carbs float(53),
    fat float(53),
    fiber float(53),
    sugar float(53),
    sodium float(53),
    potassium float(53),
    calcium float(53),
    iron float(53),
    vitamin_c float(53),
    water float(53),
    unit varchar(255),
    image_url text,
    custom boolean,
    active boolean,
    approval_status varchar(20) NOT NULL DEFAULT 'APPROVED',
    submitted_by_id varchar(255) REFERENCES users(id),
    admin_note varchar(500),
    reviewed_at timestamp(6),
    created_at timestamp(6)
);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS fiber float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS sugar float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS sodium float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS potassium float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS calcium float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS iron float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS vitamin_c float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS water float(53);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS approval_status varchar(20) DEFAULT 'APPROVED';
ALTER TABLE foods ADD COLUMN IF NOT EXISTS submitted_by_id varchar(255);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS admin_note varchar(500);
ALTER TABLE foods ADD COLUMN IF NOT EXISTS reviewed_at timestamp(6);
UPDATE foods SET approval_status = 'APPROVED' WHERE approval_status IS NULL;
ALTER TABLE foods ALTER COLUMN approval_status SET NOT NULL;
CREATE INDEX IF NOT EXISTS idx_foods_active_approval_name ON foods(active, approval_status, name);
CREATE INDEX IF NOT EXISTS idx_foods_submitted_by ON foods(submitted_by_id, created_at DESC);

CREATE TABLE IF NOT EXISTS exercises (
    id varchar(255) PRIMARY KEY,
    name varchar(255) NOT NULL,
    muscle_group varchar(255),
    equipment varchar(255),
    description varchar(255),
    image_url text,
    custom boolean,
    active boolean,
    approval_status varchar(20) NOT NULL DEFAULT 'APPROVED',
    submitted_by_id varchar(255) REFERENCES users(id),
    admin_note varchar(500),
    reviewed_at timestamp(6),
    created_at timestamp(6)
);
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS approval_status varchar(20) DEFAULT 'APPROVED';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS submitted_by_id varchar(255);
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS admin_note varchar(500);
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS reviewed_at timestamp(6);
UPDATE exercises SET approval_status = 'APPROVED' WHERE approval_status IS NULL;
ALTER TABLE exercises ALTER COLUMN approval_status SET NOT NULL;
CREATE INDEX IF NOT EXISTS idx_exercises_active_approval_name ON exercises(active, approval_status, name);
CREATE INDEX IF NOT EXISTS idx_exercises_submitted_by ON exercises(submitted_by_id, created_at DESC);

CREATE TABLE IF NOT EXISTS body_measurements (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) REFERENCES users(id) ON DELETE CASCADE,
    weight float(53),
    waist float(53),
    chest float(53),
    arm float(53),
    thigh float(53),
    record_date date,
    created_at timestamp(6)
);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date ON body_measurements(user_id, record_date DESC);

CREATE TABLE IF NOT EXISTS health_reminders (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type varchar(30) NOT NULL,
    title varchar(180) NOT NULL,
    message varchar(500),
    reminder_time time(6) NOT NULL,
    days_of_week varchar(100) NOT NULL,
    enabled boolean NOT NULL,
    last_triggered_date date,
    created_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_health_reminder_user ON health_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_health_reminder_due ON health_reminders(enabled, reminder_time, last_triggered_date);

CREATE TABLE IF NOT EXISTS meal_logs (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) REFERENCES users(id) ON DELETE CASCADE,
    meal_type varchar(255),
    log_date date,
    total_calories float(53),
    total_protein float(53),
    total_carbs float(53),
    total_fat float(53),
    created_at timestamp(6),
    source_lunch_order_id varchar(80)
);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS source_lunch_order_id varchar(80);
CREATE UNIQUE INDEX IF NOT EXISTS uk_meal_logs_source_lunch_order ON meal_logs(source_lunch_order_id) WHERE source_lunch_order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meal_logs_user_date ON meal_logs(user_id, log_date DESC, created_at DESC);

CREATE TABLE IF NOT EXISTS meal_items (
    id varchar(255) PRIMARY KEY,
    meal_log_id varchar(255) REFERENCES meal_logs(id) ON DELETE CASCADE,
    food_id varchar(255) REFERENCES foods(id),
    quantity float(53),
    calories float(53),
    protein float(53),
    carbs float(53),
    fat float(53),
    fiber float(53),
    sugar float(53),
    sodium float(53),
    potassium float(53),
    calcium float(53),
    iron float(53),
    vitamin_c float(53),
    water float(53)
);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS fiber float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS sugar float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS sodium float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS potassium float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS calcium float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS iron float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS vitamin_c float(53);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS water float(53);
CREATE INDEX IF NOT EXISTS idx_meal_items_log ON meal_items(meal_log_id);

CREATE TABLE IF NOT EXISTS workout_sessions (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) REFERENCES users(id) ON DELETE CASCADE,
    session_date date,
    note varchar(255),
    duration_minutes integer,
    created_at timestamp(6)
);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_date ON workout_sessions(user_id, session_date DESC, created_at DESC);

CREATE TABLE IF NOT EXISTS workout_sets (
    id varchar(255) PRIMARY KEY,
    session_id varchar(255) REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id varchar(255) REFERENCES exercises(id),
    set_number integer,
    weight float(53),
    reps integer,
    rir integer
);
CREATE INDEX IF NOT EXISTS idx_workout_sets_session ON workout_sets(session_id);

CREATE TABLE IF NOT EXISTS workout_plans (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) REFERENCES users(id) ON DELETE CASCADE,
    name varchar(255),
    description varchar(255),
    created_at timestamp(6)
);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_created ON workout_plans(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS workout_plan_days (
    id varchar(255) PRIMARY KEY,
    plan_id varchar(255) REFERENCES workout_plans(id) ON DELETE CASCADE,
    name varchar(255),
    day_order integer
);
CREATE INDEX IF NOT EXISTS idx_workout_plan_days_plan ON workout_plan_days(plan_id, day_order);

CREATE TABLE IF NOT EXISTS workout_plan_exercises (
    id varchar(255) PRIMARY KEY,
    day_id varchar(255) REFERENCES workout_plan_days(id) ON DELETE CASCADE,
    exercise_id varchar(255) REFERENCES exercises(id),
    exercise_order integer,
    target_sets integer,
    target_reps integer,
    target_weight float(53),
    target_rir integer
);
CREATE INDEX IF NOT EXISTS idx_workout_plan_exercises_day ON workout_plan_exercises(day_id, exercise_order);

CREATE TABLE IF NOT EXISTS lunch_menus (
    id varchar(255) PRIMARY KEY,
    menu_date date NOT NULL,
    order_label varchar(255) NOT NULL,
    vendor_name varchar(255),
    cutoff_at timestamp(6) NOT NULL,
    price bigint NOT NULL,
    status varchar(20) NOT NULL,
    raw_menu_text text NOT NULL,
    summary_order_text text,
    summarized_at timestamp(6),
    created_by_id varchar(255) NOT NULL REFERENCES users(id),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    version bigint
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_menus_menu_date ON lunch_menus(menu_date);
CREATE INDEX IF NOT EXISTS idx_lunch_menus_date_status ON lunch_menus(menu_date DESC, status);

CREATE TABLE IF NOT EXISTS lunch_menu_items (
    id varchar(255) PRIMARY KEY,
    menu_id varchar(255) NOT NULL REFERENCES lunch_menus(id) ON DELETE CASCADE,
    name varchar(255) NOT NULL,
    type varchar(20) NOT NULL,
    sort_order integer NOT NULL,
    image_url text,
    calories float(53),
    protein float(53),
    carbs float(53),
    fat float(53),
    nutrition_food_id varchar(255) REFERENCES foods(id)
);
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS calories float(53);
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS protein float(53);
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS carbs float(53);
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS fat float(53);
ALTER TABLE lunch_menu_items ADD COLUMN IF NOT EXISTS nutrition_food_id varchar(255);
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_menu_items_menu_sort ON lunch_menu_items(menu_id, sort_order);

CREATE TABLE IF NOT EXISTS lunch_orders (
    id varchar(255) PRIMARY KEY,
    menu_id varchar(255) NOT NULL REFERENCES lunch_menus(id),
    beneficiary_id varchar(255) NOT NULL REFERENCES users(id),
    payer_id varchar(255) REFERENCES users(id),
    ordered_by_id varchar(255) NOT NULL REFERENCES users(id),
    selection_type varchar(20) NOT NULL,
    price bigint NOT NULL,
    payment_status varchar(30) NOT NULL,
    status varchar(20) NOT NULL DEFAULT 'ACTIVE',
    note varchar(500),
    external_confirmed_by_id varchar(255) REFERENCES users(id),
    external_confirmed_at timestamp(6),
    external_payment_note varchar(500),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    cancelled_at timestamp(6),
    version bigint
);
ALTER TABLE lunch_orders ADD COLUMN IF NOT EXISTS status varchar(20) DEFAULT 'ACTIVE';
ALTER TABLE lunch_orders ADD COLUMN IF NOT EXISTS cancelled_at timestamp(6);
UPDATE lunch_orders SET status = 'ACTIVE' WHERE status IS NULL;
ALTER TABLE lunch_orders ALTER COLUMN status SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_orders_menu_beneficiary ON lunch_orders(menu_id, beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_lunch_orders_payment_status ON lunch_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_lunch_orders_created_at ON lunch_orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lunch_orders_beneficiary_status ON lunch_orders(beneficiary_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS lunch_order_items (
    id varchar(255) PRIMARY KEY,
    order_id varchar(255) NOT NULL REFERENCES lunch_orders(id) ON DELETE CASCADE,
    menu_item_id varchar(255) NOT NULL REFERENCES lunch_menu_items(id),
    item_name_snapshot varchar(255) NOT NULL,
    sort_order integer NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_lunch_order_items_order ON lunch_order_items(order_id, sort_order);

CREATE TABLE IF NOT EXISTS lunch_fund_accounts (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id),
    balance bigint NOT NULL DEFAULT 0,
    debt bigint NOT NULL DEFAULT 0,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    version bigint,
    CONSTRAINT chk_lunch_fund_balance CHECK (balance >= 0),
    CONSTRAINT chk_lunch_fund_debt CHECK (debt >= 0)
);
ALTER TABLE lunch_fund_accounts ADD COLUMN IF NOT EXISTS debt bigint DEFAULT 0;
UPDATE lunch_fund_accounts SET debt = 0 WHERE debt IS NULL;
ALTER TABLE lunch_fund_accounts ALTER COLUMN debt SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_fund_accounts_user ON lunch_fund_accounts(user_id);

CREATE TABLE IF NOT EXISTS lunch_fund_transactions (
    id varchar(255) PRIMARY KEY,
    account_id varchar(255) NOT NULL REFERENCES lunch_fund_accounts(id),
    type varchar(30) NOT NULL,
    amount bigint NOT NULL,
    balance_after bigint NOT NULL,
    order_id varchar(255) REFERENCES lunch_orders(id),
    actor_id varchar(255) NOT NULL REFERENCES users(id),
    note varchar(500),
    created_at timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_lunch_fund_transactions_account_created ON lunch_fund_transactions(account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lunch_fund_transactions_order ON lunch_fund_transactions(order_id);

CREATE TABLE IF NOT EXISTS lunch_payment_requests (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id),
    type varchar(30) NOT NULL,
    amount bigint NOT NULL,
    status varchar(20) NOT NULL,
    note varchar(500),
    reviewed_by_id varchar(255) REFERENCES users(id),
    review_note varchar(500),
    created_at timestamp(6) NOT NULL,
    reviewed_at timestamp(6),
    version bigint
);
CREATE INDEX IF NOT EXISTS idx_lunch_payment_request_status ON lunch_payment_requests(status);
CREATE INDEX IF NOT EXISTS idx_lunch_payment_request_created ON lunch_payment_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lunch_payment_request_user_created ON lunch_payment_requests(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS lunch_payment_settings (
    id varchar(30) PRIMARY KEY,
    qr_image_url text,
    bank_name varchar(120),
    account_name varchar(120),
    account_number varchar(80),
    instructions varchar(500),
    updated_at timestamp(6) NOT NULL,
    version bigint
);

CREATE TABLE IF NOT EXISTS lunch_notifications (
    id varchar(255) PRIMARY KEY,
    recipient_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type varchar(50) NOT NULL,
    title varchar(180) NOT NULL,
    message varchar(800) NOT NULL,
    reference_type varchar(50),
    reference_id varchar(80),
    created_at timestamp(6) NOT NULL,
    read_at timestamp(6)
);
CREATE INDEX IF NOT EXISTS idx_lunch_notification_recipient ON lunch_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_lunch_notification_created ON lunch_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lunch_notification_recipient_read_created ON lunch_notifications(recipient_id, read_at, created_at DESC);

CREATE TABLE IF NOT EXISTS lunch_dish_reviews (
    id varchar(255) PRIMARY KEY,
    order_id varchar(255) NOT NULL REFERENCES lunch_orders(id) ON DELETE CASCADE,
    menu_item_id varchar(255) NOT NULL REFERENCES lunch_menu_items(id),
    reviewer_id varchar(255) NOT NULL REFERENCES users(id),
    rating integer NOT NULL,
    comment varchar(1000),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_lunch_review_rating CHECK (rating BETWEEN 1 AND 5)
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_review_order_item ON lunch_dish_reviews(order_id, menu_item_id);
CREATE INDEX IF NOT EXISTS idx_lunch_review_menu_item ON lunch_dish_reviews(menu_item_id);
