-- FinFlow Database Schema
-- Система учета личных финансов и бюджетирования

-- Удаление существующих объектов (для пересоздания)
DROP TABLE IF EXISTS transaction_tags CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS recurring_transactions CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;

-- Удаление типов
DROP TYPE IF EXISTS account_type CASCADE;
DROP TYPE IF EXISTS transaction_type CASCADE;
DROP TYPE IF EXISTS category_type CASCADE;
DROP TYPE IF EXISTS budget_period CASCADE;
DROP TYPE IF EXISTS recurring_interval CASCADE;
DROP TYPE IF EXISTS audit_action CASCADE;

-- Создание пользовательских типов
CREATE TYPE account_type AS ENUM ('cash', 'debit_card', 'credit_card', 'deposit', 'investment');
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');
CREATE TYPE category_type AS ENUM ('income', 'expense');
CREATE TYPE budget_period AS ENUM ('month', 'year');
CREATE TYPE recurring_interval AS ENUM ('daily', 'weekly', 'monthly', 'yearly');
CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- 1. Таблица пользователей
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    currency VARCHAR(3) NOT NULL DEFAULT 'RUB',
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE
);

-- 2. Таблица счетов
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(255) NOT NULL,
    type account_type NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'RUB',
    bank_name VARCHAR(255),
    account_number VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT balance_non_negative CHECK (balance >= 0)
);

-- 3. Таблица категорий
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(255) NOT NULL,
    type category_type NOT NULL,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE,
    budget_limit DECIMAL(15, 2),
    icon VARCHAR(50),
    color VARCHAR(7),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_category UNIQUE (user_id, name),
    CONSTRAINT budget_limit_positive CHECK (budget_limit IS NULL OR budget_limit > 0)
);

-- 4. Таблица транзакций
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    type transaction_type NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    payee VARCHAR(255),
    location VARCHAR(255),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_transaction_id INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT date_not_future CHECK (date <= CURRENT_DATE)
);

-- 5. Таблица тегов
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_tag UNIQUE (user_id, name)
);

-- 6. Связующая таблица транзакций и тегов (N:M)
CREATE TABLE transaction_tags (
    transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE ON UPDATE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (transaction_id, tag_id)
);

-- 7. Таблица бюджетов
CREATE TABLE budgets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    period budget_period NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

-- 8. Таблица финансовых целей
CREATE TABLE goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount DECIMAL(15, 2) NOT NULL,
    current_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    deadline DATE,
    priority INTEGER DEFAULT 5,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT target_amount_positive CHECK (target_amount > 0),
    CONSTRAINT current_amount_non_negative CHECK (current_amount >= 0),
    CONSTRAINT current_not_exceed_target CHECK (current_amount <= target_amount),
    CONSTRAINT priority_range CHECK (priority >= 1 AND priority <= 10)
);

-- 9. Таблица регулярных транзакций
CREATE TABLE recurring_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE,
    description TEXT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    type transaction_type NOT NULL,
    interval recurring_interval NOT NULL,
    next_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT valid_end_date CHECK (end_date IS NULL OR end_date >= next_date)
);

-- 10. Таблица журнала аудита
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action audit_action NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Создание индексов для оптимизации запросов
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date_type ON transactions(date, type);
CREATE INDEX idx_transaction_tags_transaction_id ON transaction_tags(transaction_id);
CREATE INDEX idx_transaction_tags_tag_id ON transaction_tags(tag_id);
CREATE INDEX idx_tags_user_id ON tags(user_id);
CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_period ON budgets(period);
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_deadline ON goals(deadline);
CREATE INDEX idx_goals_is_completed ON goals(is_completed);
CREATE INDEX idx_recurring_transactions_user_id ON recurring_transactions(user_id);
CREATE INDEX idx_recurring_transactions_next_date ON recurring_transactions(next_date);
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON audit_log(changed_at);
CREATE INDEX idx_audit_log_action ON audit_log(action);

-- Комментарии к таблицам
COMMENT ON TABLE users IS 'Пользователи системы';
COMMENT ON TABLE accounts IS 'Финансовые счета пользователей';
COMMENT ON TABLE categories IS 'Категории доходов и расходов';
COMMENT ON TABLE transactions IS 'Транзакции (доходы, расходы, переводы)';
COMMENT ON TABLE tags IS 'Теги для классификации транзакций';
COMMENT ON TABLE transaction_tags IS 'Связь транзакций и тегов (многие ко многим)';
COMMENT ON TABLE budgets IS 'Бюджеты по категориям на период';
COMMENT ON TABLE goals IS 'Финансовые цели пользователей';
COMMENT ON TABLE recurring_transactions IS 'Регулярные платежи и доходы';
COMMENT ON TABLE audit_log IS 'Журнал аудита изменений в базе данных';





