CREATE TABLE nutrition_planned_meals (
 id varchar(255) PRIMARY KEY, version bigint NOT NULL DEFAULT 0,
 user_id varchar(255) NOT NULL REFERENCES users(id), date date NOT NULL,
 meal_type varchar(20) NOT NULL CHECK(meal_type IN ('BREAKFAST','LUNCH','DINNER','SNACK')),
 name varchar(160) NOT NULL, notes varchar(1000), snapshot text NOT NULL,
 logged_meal_id varchar(255), created_at timestamp NOT NULL
);
CREATE INDEX idx_planned_meals_owner_date ON nutrition_planned_meals(user_id,date);
CREATE TABLE nutrition_grocery_weeks (
 id varchar(255) PRIMARY KEY, version bigint NOT NULL DEFAULT 0,
 user_id varchar(255) NOT NULL REFERENCES users(id), week date NOT NULL, items text NOT NULL,
 CONSTRAINT uq_grocery_owner_week UNIQUE(user_id,week)
);
CREATE TABLE nutrition_planning_copies (
 id varchar(255) PRIMARY KEY, user_id varchar(255) NOT NULL REFERENCES users(id),
 operation_id varchar(80) NOT NULL, fingerprint varchar(100) NOT NULL, copied_count integer NOT NULL,
 CONSTRAINT uq_planning_copy_operation UNIQUE(user_id,operation_id)
);
