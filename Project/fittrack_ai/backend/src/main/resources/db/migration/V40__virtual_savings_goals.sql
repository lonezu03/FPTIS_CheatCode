-- Virtual progress only: deliberately no reference or insert into finance_transactions/accounts.
CREATE TABLE finance_savings_goals (
 id varchar(255) PRIMARY KEY, owner_id varchar(255) NOT NULL REFERENCES users(id), title varchar(160) NOT NULL,
 target numeric(18,2) NOT NULL CHECK(target>0), progress numeric(18,2) NOT NULL DEFAULT 0 CHECK(progress>=0), currency_code varchar(3) NOT NULL,
 target_date date, note varchar(1000), archived boolean NOT NULL DEFAULT false, version bigint NOT NULL DEFAULT 0
);
CREATE INDEX idx_savings_owner ON finance_savings_goals(owner_id);
CREATE TABLE finance_savings_operations (
 id varchar(255) PRIMARY KEY, goal_id varchar(255) NOT NULL REFERENCES finance_savings_goals(id), operation_id varchar(80) NOT NULL,
 type varchar(10) NOT NULL CHECK(type IN ('ADD','RELEASE')), amount numeric(18,2) NOT NULL CHECK(amount>0), currency_code varchar(3) NOT NULL,
 note varchar(1000), created_at timestamp NOT NULL, UNIQUE(goal_id,operation_id)
);
CREATE INDEX idx_savings_operations ON finance_savings_operations(goal_id,created_at);
