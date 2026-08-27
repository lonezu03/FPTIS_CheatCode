-- FitTrack lunch concurrency: several coordinators may publish a menu for the same date.
ALTER TABLE lunch_menus
    DROP CONSTRAINT IF EXISTS uk_lunch_menus_menu_date;

CREATE INDEX IF NOT EXISTS idx_lunch_menus_menu_date_created_at
    ON lunch_menus (menu_date, created_at);

ALTER TABLE lunch_menu_items
    ADD COLUMN IF NOT EXISTS unit_price BIGINT;

ALTER TABLE lunch_menu_items
    ADD CONSTRAINT ck_lunch_menu_items_unit_price_positive
    CHECK (unit_price IS NULL OR unit_price > 0);
