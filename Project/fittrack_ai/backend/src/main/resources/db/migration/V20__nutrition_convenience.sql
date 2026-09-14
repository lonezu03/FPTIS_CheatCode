CREATE TABLE food_preferences (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_id varchar(255) NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
    favorite boolean NOT NULL DEFAULT false,
    use_count integer NOT NULL DEFAULT 0,
    last_used_at timestamp(6),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT uk_food_preferences_user_food UNIQUE (user_id, food_id),
    CONSTRAINT chk_food_preferences_use_count CHECK (use_count >= 0)
);

CREATE INDEX idx_food_preferences_user_recent
    ON food_preferences(user_id, last_used_at DESC);
CREATE INDEX idx_food_preferences_user_favorite
    ON food_preferences(user_id, favorite) WHERE favorite = true;

CREATE TABLE nutrition_collections (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name varchar(160) NOT NULL,
    description varchar(500),
    type varchar(20) NOT NULL,
    servings numeric(10,2) NOT NULL DEFAULT 1,
    active boolean NOT NULL DEFAULT true,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_nutrition_collection_type
        CHECK (type IN ('SAVED_MEAL', 'RECIPE')),
    CONSTRAINT chk_nutrition_collection_servings CHECK (servings > 0)
);

CREATE INDEX idx_nutrition_collections_user_type
    ON nutrition_collections(user_id, type, active, updated_at DESC);

CREATE TABLE nutrition_collection_items (
    id varchar(255) PRIMARY KEY,
    collection_id varchar(255) NOT NULL REFERENCES nutrition_collections(id) ON DELETE CASCADE,
    food_id varchar(255) NOT NULL REFERENCES foods(id),
    serving_amount numeric(12,3) NOT NULL,
    serving_unit varchar(20) NOT NULL,
    item_order integer NOT NULL,
    CONSTRAINT chk_nutrition_collection_amount CHECK (serving_amount > 0),
    CONSTRAINT chk_nutrition_collection_unit
        CHECK (serving_unit IN ('SERVING', 'GRAM', 'ML')),
    CONSTRAINT uk_nutrition_collection_item_order UNIQUE (collection_id, item_order)
);

CREATE INDEX idx_nutrition_collection_items_collection
    ON nutrition_collection_items(collection_id, item_order);
