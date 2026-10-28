CREATE TABLE shared_expense_groups (
 id varchar(255) PRIMARY KEY, owner_id varchar(255) NOT NULL REFERENCES users(id), name varchar(160) NOT NULL,
 description varchar(1000), archived boolean NOT NULL DEFAULT false, created_at timestamp NOT NULL,
 version bigint NOT NULL DEFAULT 0, revision bigint NOT NULL DEFAULT 0
);
CREATE TABLE shared_expense_members (
 id varchar(255) PRIMARY KEY, group_id varchar(255) NOT NULL REFERENCES shared_expense_groups(id),
 user_id varchar(255) NOT NULL REFERENCES users(id), display_name varchar(160) NOT NULL,
 status varchar(16) NOT NULL CHECK(status IN ('INVITED','ACTIVE','REMOVED','DECLINED')),
 invited_at timestamp NOT NULL, accepted_at timestamp, UNIQUE(group_id,user_id)
);
CREATE INDEX ix_shared_members_user_status ON shared_expense_members(user_id,status,invited_at DESC);
CREATE TABLE shared_expenses (
 id varchar(255) PRIMARY KEY, group_id varchar(255) NOT NULL REFERENCES shared_expense_groups(id),
 creator_id varchar(255) NOT NULL REFERENCES users(id), payer_id varchar(255) NOT NULL REFERENCES users(id),
 title varchar(180) NOT NULL, amount numeric(16,0) NOT NULL CHECK(amount>0 AND amount<=1000000000000),
 spent_on date NOT NULL, splits text NOT NULL, voided boolean NOT NULL DEFAULT false, note varchar(1000),
 created_at timestamp NOT NULL, version bigint NOT NULL DEFAULT 0
);
CREATE INDEX ix_shared_expenses_group ON shared_expenses(group_id,spent_on DESC,created_at DESC);
CREATE TABLE shared_expense_settlements (
 id varchar(255) PRIMARY KEY, group_id varchar(255) NOT NULL REFERENCES shared_expense_groups(id),
 initiator_id varchar(255) NOT NULL REFERENCES users(id), debtor_id varchar(255) NOT NULL REFERENCES users(id),
 creditor_id varchar(255) NOT NULL REFERENCES users(id), amount numeric(16,0) NOT NULL CHECK(amount>0 AND amount<=1000000000000),
 status varchar(16) NOT NULL CHECK(status IN ('PENDING','CONFIRMED','REJECTED')),
 note varchar(1000), created_at timestamp NOT NULL, resolved_at timestamp, version bigint NOT NULL DEFAULT 0,
 CHECK(debtor_id<>creditor_id), CHECK(initiator_id=debtor_id OR initiator_id=creditor_id)
);
CREATE INDEX ix_shared_settlements_group ON shared_expense_settlements(group_id,status,created_at DESC);
CREATE TABLE shared_expense_audit (
 id varchar(255) PRIMARY KEY, group_id varchar(255) NOT NULL REFERENCES shared_expense_groups(id),
 actor_id varchar(255) NOT NULL REFERENCES users(id), operation_id varchar(80) NOT NULL,
 digest varchar(64) NOT NULL, action varchar(40) NOT NULL, detail text NOT NULL, result text NOT NULL,
 created_at timestamp NOT NULL, UNIQUE(actor_id,operation_id)
);
CREATE INDEX ix_shared_audit_group ON shared_expense_audit(group_id,created_at DESC);
