-- One employee can order more than one portion from the same daily menu.
-- Each portion remains a separate order so payment, nutrition and cancellation
-- continue to be tracked independently.
ALTER TABLE lunch_orders
    DROP CONSTRAINT IF EXISTS uk_lunch_orders_menu_beneficiary;

DROP INDEX IF EXISTS uk_lunch_orders_menu_beneficiary;

CREATE INDEX IF NOT EXISTS idx_lunch_orders_menu_beneficiary_status_created_at
    ON lunch_orders(menu_id, beneficiary_id, status, created_at);

-- A repeated mobile/browser submission must return the same batch instead of
-- creating and debiting another set of portions. Null remains valid for the
-- original single-order endpoint and historical rows.
ALTER TABLE lunch_orders
    ADD COLUMN IF NOT EXISTS batch_request_id varchar(64);

ALTER TABLE lunch_orders
    ADD COLUMN IF NOT EXISTS batch_position integer;

CREATE UNIQUE INDEX IF NOT EXISTS uk_lunch_orders_ordered_by_batch_request
    ON lunch_orders(ordered_by_id, batch_request_id, batch_position)
    WHERE batch_request_id IS NOT NULL;
