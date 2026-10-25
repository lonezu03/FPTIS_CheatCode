CREATE TABLE finance_balance_reconciliations (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id),
    account_id varchar(255) NOT NULL REFERENCES finance_accounts(id),
    balance_before numeric(24,2) NOT NULL,
    balance_after numeric(24,2) NOT NULL,
    difference numeric(24,2) NOT NULL,
    opening_before numeric(18,2) NOT NULL,
    opening_after numeric(18,2) NOT NULL,
    note varchar(500) NOT NULL,
    created_at timestamp(6) NOT NULL,
    CONSTRAINT chk_finance_reconciliation_difference CHECK (difference = balance_after - balance_before)
);
CREATE INDEX idx_finance_reconciliation_owner_account
    ON finance_balance_reconciliations(user_id, account_id, created_at DESC, id);
