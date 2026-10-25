ALTER TABLE exercises ALTER COLUMN description TYPE TEXT;
ALTER TABLE exercises ADD COLUMN seed_key VARCHAR(255);
ALTER TABLE exercises ADD COLUMN search_text TEXT;
CREATE UNIQUE INDEX uk_exercises_seed_key ON exercises(seed_key);
ALTER TABLE foods ADD COLUMN seed_key VARCHAR(255);
ALTER TABLE foods ADD COLUMN search_text TEXT;
CREATE UNIQUE INDEX uk_foods_seed_key ON foods(seed_key);
ALTER TABLE meal_items ADD COLUMN food_name_snapshot VARCHAR(255);
ALTER TABLE meal_items ADD COLUMN food_unit_snapshot VARCHAR(255);
ALTER TABLE meal_items ADD COLUMN food_source_snapshot VARCHAR(255);
ALTER TABLE meal_items ADD COLUMN food_source_type_snapshot VARCHAR(255);
ALTER TABLE meal_items ADD COLUMN food_verified_snapshot BOOLEAN;
ALTER TABLE meal_items ADD COLUMN serving_size_snapshot DOUBLE PRECISION;
-- Existing rows retain numeric snapshots. Labels cannot be reconstructed historically;
-- use the currently linked label as the initial snapshot and preserve it thereafter.
UPDATE meal_items m SET food_name_snapshot = f.name, food_unit_snapshot = f.unit,
 food_source_snapshot = f.data_source_name, food_source_type_snapshot = f.data_source_type,
 food_verified_snapshot = f.verified, serving_size_snapshot = f.serving_size_grams
 FROM foods f WHERE m.food_id = f.id;
