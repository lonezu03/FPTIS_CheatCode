CREATE TABLE pantry_batches (
 id varchar(255) PRIMARY KEY, user_id varchar(255) NOT NULL REFERENCES users(id),
 food_id varchar(255) NOT NULL REFERENCES foods(id), location varchar(120) NOT NULL,
 unit varchar(20) NOT NULL CHECK(unit IN ('SERVING','GRAM','ML')),
 quantity numeric(18,3) NOT NULL CHECK(quantity >= 0), expires_on date,
 note varchar(1000), active boolean NOT NULL DEFAULT true, version bigint NOT NULL DEFAULT 0,
 created_at timestamp NOT NULL
);
CREATE INDEX idx_pantry_owner ON pantry_batches(user_id,active,created_at DESC);
CREATE INDEX idx_pantry_expiry ON pantry_batches(expires_on,id) WHERE active AND quantity > 0;
CREATE TABLE pantry_operations (
 id varchar(255) PRIMARY KEY, batch_id varchar(255) NOT NULL REFERENCES pantry_batches(id),
 user_id varchar(255) NOT NULL REFERENCES users(id), operation_id varchar(80) NOT NULL,
 fingerprint varchar(64) NOT NULL, type varchar(20) NOT NULL CHECK(type IN ('ADD','CONSUME','DISCARD','CORRECTION')),
 amount numeric(18,3) NOT NULL, balance_after numeric(18,3) NOT NULL CHECK(balance_after>=0),
 note varchar(1000), created_at timestamp NOT NULL, UNIQUE(user_id,operation_id)
);
CREATE INDEX idx_pantry_history ON pantry_operations(batch_id,created_at DESC);
CREATE TABLE food_purchase_prices (
 id varchar(255) PRIMARY KEY, user_id varchar(255) NOT NULL REFERENCES users(id),
 food_id varchar(255) NOT NULL REFERENCES foods(id), amount numeric(18,3) NOT NULL CHECK(amount>0),
 unit varchar(20) NOT NULL CHECK(unit IN ('SERVING','GRAM','ML')),
 total_price numeric(18,0) NOT NULL CHECK(total_price>0), purchased_on date NOT NULL,
 store varchar(160), note varchar(1000), active boolean NOT NULL DEFAULT true,
 operation_id varchar(80) NOT NULL, fingerprint varchar(64) NOT NULL,
 version bigint NOT NULL DEFAULT 0, created_at timestamp NOT NULL, UNIQUE(user_id,operation_id)
);
CREATE INDEX idx_purchase_owner_food ON food_purchase_prices(user_id,food_id,purchased_on DESC) WHERE active;
CREATE INDEX idx_purchase_latest_unit ON food_purchase_prices(user_id,food_id,unit,purchased_on DESC,created_at DESC,id DESC) WHERE active;
CREATE INDEX idx_purchase_owner_history ON food_purchase_prices(user_id,active,purchased_on DESC,created_at DESC);
