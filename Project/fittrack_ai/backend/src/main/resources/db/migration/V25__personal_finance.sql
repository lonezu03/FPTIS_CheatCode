ALTER TABLE users ADD COLUMN finance_enabled boolean NOT NULL DEFAULT false;

CREATE TABLE finance_accounts (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name varchar(120) NOT NULL,
    account_type varchar(20) NOT NULL,
    currency_code varchar(3) NOT NULL DEFAULT 'VND',
    opening_balance numeric(18,2) NOT NULL DEFAULT 0,
    active boolean NOT NULL DEFAULT true,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_finance_account_type CHECK (account_type IN ('CASH','BANK','EWALLET','SAVINGS','OTHER'))
);
CREATE INDEX idx_finance_accounts_owner ON finance_accounts(user_id, active, created_at);

CREATE TABLE finance_categories (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id varchar(255) REFERENCES finance_categories(id),
    name varchar(120) NOT NULL,
    transaction_kind varchar(20) NOT NULL,
    expense_nature varchar(30),
    icon varchar(40),
    active boolean NOT NULL DEFAULT true,
    system_category boolean NOT NULL DEFAULT false,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_finance_category_kind CHECK (transaction_kind IN ('EXPENSE','INCOME')),
    CONSTRAINT chk_finance_expense_nature CHECK (expense_nature IS NULL OR expense_nature IN
        ('FIXED_MANDATORY','ESSENTIAL_VARIABLE','TRUE_EXPENSE','SAVING','DISCRETIONARY')),
    CONSTRAINT uk_finance_category_name UNIQUE (user_id, transaction_kind, name)
);
CREATE INDEX idx_finance_categories_owner ON finance_categories(user_id, transaction_kind, active);

CREATE TABLE finance_transactions (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id varchar(255) NOT NULL REFERENCES finance_accounts(id),
    destination_account_id varchar(255) REFERENCES finance_accounts(id),
    category_id varchar(255) REFERENCES finance_categories(id),
    expense_nature varchar(30),
    type varchar(20) NOT NULL,
    amount numeric(18,2) NOT NULL,
    occurred_at timestamp(6) NOT NULL,
    merchant varchar(160),
    note varchar(1000),
    source_type varchar(50),
    source_id varchar(255),
    status varchar(20) NOT NULL DEFAULT 'POSTED',
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    deleted_at timestamp(6),
    CONSTRAINT chk_finance_transaction_type CHECK (type IN ('EXPENSE','INCOME','TRANSFER')),
    CONSTRAINT chk_finance_transaction_amount CHECK (amount > 0),
    CONSTRAINT chk_finance_transaction_status CHECK (status IN ('POSTED','VOID')),
    CONSTRAINT chk_finance_transaction_nature CHECK (expense_nature IS NULL OR expense_nature IN
        ('FIXED_MANDATORY','ESSENTIAL_VARIABLE','TRUE_EXPENSE','SAVING','DISCRETIONARY')),
    CONSTRAINT chk_finance_transfer_accounts CHECK (
        (type = 'TRANSFER' AND destination_account_id IS NOT NULL AND destination_account_id <> account_id AND category_id IS NULL)
        OR (type <> 'TRANSFER' AND destination_account_id IS NULL AND category_id IS NOT NULL)
    )
);
CREATE INDEX idx_finance_transactions_owner_time ON finance_transactions(user_id, occurred_at DESC);
CREATE INDEX idx_finance_transactions_account ON finance_transactions(account_id, status);
CREATE UNIQUE INDEX uk_finance_transaction_source ON finance_transactions(user_id, source_type, source_id)
    WHERE source_type IS NOT NULL AND source_id IS NOT NULL;

CREATE TABLE finance_budgets (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id varchar(255) NOT NULL REFERENCES finance_categories(id),
    month_start date NOT NULL,
    amount numeric(18,2) NOT NULL,
    rollover_enabled boolean NOT NULL DEFAULT false,
    warned_80_at timestamp(6),
    warned_100_at timestamp(6),
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_finance_budget_amount CHECK (amount > 0),
    CONSTRAINT uk_finance_budget_month UNIQUE (user_id, category_id, month_start)
);
CREATE INDEX idx_finance_budgets_owner_month ON finance_budgets(user_id, month_start);

CREATE TABLE finance_recurring_rules (
    id varchar(255) PRIMARY KEY,
    user_id varchar(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name varchar(160) NOT NULL,
    transaction_type varchar(20) NOT NULL,
    account_id varchar(255) NOT NULL REFERENCES finance_accounts(id),
    destination_account_id varchar(255) REFERENCES finance_accounts(id),
    category_id varchar(255) REFERENCES finance_categories(id),
    expense_nature varchar(30),
    amount numeric(18,2) NOT NULL,
    frequency varchar(20) NOT NULL,
    next_due_date date NOT NULL,
    remind_days_before integer NOT NULL DEFAULT 1,
    active boolean NOT NULL DEFAULT true,
    last_notified_for date,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT chk_finance_recurring_type CHECK (transaction_type IN ('EXPENSE','INCOME','TRANSFER')),
    CONSTRAINT chk_finance_recurring_frequency CHECK (frequency IN ('WEEKLY','MONTHLY','YEARLY')),
    CONSTRAINT chk_finance_recurring_amount CHECK (amount > 0),
    CONSTRAINT chk_finance_recurring_remind CHECK (remind_days_before BETWEEN 0 AND 30),
    CONSTRAINT chk_finance_recurring_nature CHECK (expense_nature IS NULL OR expense_nature IN
        ('FIXED_MANDATORY','ESSENTIAL_VARIABLE','TRUE_EXPENSE','SAVING','DISCRETIONARY'))
);
CREATE INDEX idx_finance_recurring_due ON finance_recurring_rules(active, next_due_date);
