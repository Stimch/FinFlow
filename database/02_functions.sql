-- FinFlow Database Functions
-- Скалярные и табличные функции

-- ============================================
-- СКАЛЯРНЫЕ ФУНКЦИИ
-- ============================================

-- Функция расчета общего баланса пользователя
CREATE OR REPLACE FUNCTION get_user_total_balance(p_user_id INTEGER)
RETURNS DECIMAL(15, 2) AS $$
BEGIN
    RETURN COALESCE(
        (SELECT SUM(balance) FROM accounts WHERE user_id = p_user_id AND is_active = TRUE),
        0.00
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_total_balance(INTEGER) IS 'Возвращает общий баланс всех активных счетов пользователя';

-- Функция расчета суммы транзакций за период
CREATE OR REPLACE FUNCTION get_transactions_sum(
    p_user_id INTEGER,
    p_start_date DATE,
    p_end_date DATE,
    p_type transaction_type DEFAULT NULL
)
RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_sum DECIMAL(15, 2);
BEGIN
    SELECT COALESCE(SUM(t.amount), 0.00) INTO v_sum
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    WHERE a.user_id = p_user_id
      AND t.date BETWEEN p_start_date AND p_end_date
      AND (p_type IS NULL OR t.type = p_type);
    
    RETURN v_sum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_transactions_sum(INTEGER, DATE, DATE, transaction_type) IS 
'Возвращает сумму транзакций пользователя за указанный период';

-- Функция расчета процента выполнения цели
CREATE OR REPLACE FUNCTION get_goal_progress(p_goal_id INTEGER)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
    v_progress DECIMAL(5, 2);
BEGIN
    SELECT 
        CASE 
            WHEN target_amount > 0 THEN 
                LEAST(100.00, (current_amount / target_amount) * 100.00)
            ELSE 0.00
        END
    INTO v_progress
    FROM goals
    WHERE id = p_goal_id;
    
    RETURN COALESCE(v_progress, 0.00);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_goal_progress(INTEGER) IS 'Возвращает процент выполнения финансовой цели';

-- Функция расчета превышения бюджета
CREATE OR REPLACE FUNCTION get_budget_exceeded(
    p_budget_id INTEGER,
    p_period_start DATE,
    p_period_end DATE
)
RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_budget_amount DECIMAL(15, 2);
    v_spent DECIMAL(15, 2);
    v_exceeded DECIMAL(15, 2);
BEGIN
    -- Получаем сумму бюджета
    SELECT amount INTO v_budget_amount
    FROM budgets
    WHERE id = p_budget_id;
    
    -- Получаем сумму потраченных средств
    SELECT COALESCE(SUM(t.amount), 0.00) INTO v_spent
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    JOIN budgets b ON b.category_id = t.category_id
    WHERE b.id = p_budget_id
      AND t.type = 'expense'
      AND t.date BETWEEN p_period_start AND p_period_end;
    
    -- Рассчитываем превышение
    v_exceeded := v_spent - v_budget_amount;
    
    RETURN GREATEST(0.00, v_exceeded);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_budget_exceeded(INTEGER, DATE, DATE) IS 
'Возвращает сумму превышения бюджета за указанный период';

-- Функция расчета среднего расхода по категории
CREATE OR REPLACE FUNCTION get_category_avg_expense(
    p_category_id INTEGER,
    p_months INTEGER DEFAULT 3
)
RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_avg DECIMAL(15, 2);
BEGIN
    SELECT COALESCE(AVG(amount), 0.00) INTO v_avg
    FROM transactions
    WHERE category_id = p_category_id
      AND type = 'expense'
      AND date >= CURRENT_DATE - INTERVAL '1 month' * p_months;
    
    RETURN v_avg;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_category_avg_expense(INTEGER, INTEGER) IS 
'Возвращает средний расход по категории за последние N месяцев';

-- ============================================
-- ТАБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

-- Функция получения финансового отчета пользователя
CREATE OR REPLACE FUNCTION get_user_financial_report(
    p_user_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    category_name VARCHAR(255),
    category_type category_type,
    total_income DECIMAL(15, 2),
    total_expense DECIMAL(15, 2),
    transaction_count BIGINT,
    avg_amount DECIMAL(15, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name AS category_name,
        c.type AS category_type,
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0.00) AS total_income,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) AS total_expense,
        COUNT(t.id) AS transaction_count,
        COALESCE(AVG(t.amount), 0.00) AS avg_amount
    FROM categories c
    LEFT JOIN transactions t ON c.id = t.category_id
        AND t.date BETWEEN p_start_date AND p_end_date
    LEFT JOIN accounts a ON t.account_id = a.id
    WHERE c.user_id = p_user_id
      AND (a.user_id = p_user_id OR a.user_id IS NULL)
    GROUP BY c.id, c.name, c.type
    ORDER BY total_expense DESC, total_income DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_financial_report(INTEGER, DATE, DATE) IS 
'Возвращает финансовый отчет по категориям за указанный период';

-- Функция получения топ категорий расходов
CREATE OR REPLACE FUNCTION get_top_expense_categories(
    p_user_id INTEGER,
    p_limit INTEGER DEFAULT 10,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    category_id INTEGER,
    category_name VARCHAR(255),
    total_amount DECIMAL(15, 2),
    transaction_count BIGINT,
    percentage DECIMAL(5, 2)
) AS $$
DECLARE
    v_total DECIMAL(15, 2);
BEGIN
    -- Общая сумма расходов
    SELECT COALESCE(SUM(t.amount), 0.00) INTO v_total
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    WHERE a.user_id = p_user_id
      AND t.type = 'expense'
      AND (p_start_date IS NULL OR t.date >= p_start_date)
      AND (p_end_date IS NULL OR t.date <= p_end_date);
    
    RETURN QUERY
    SELECT 
        c.id AS category_id,
        c.name AS category_name,
        COALESCE(SUM(t.amount), 0.00) AS total_amount,
        COUNT(t.id) AS transaction_count,
        CASE 
            WHEN v_total > 0 THEN (SUM(t.amount) / v_total) * 100.00
            ELSE 0.00
        END AS percentage
    FROM categories c
    LEFT JOIN transactions t ON c.id = t.category_id
        AND t.type = 'expense'
        AND (p_start_date IS NULL OR t.date >= p_start_date)
        AND (p_end_date IS NULL OR t.date <= p_end_date)
    LEFT JOIN accounts a ON t.account_id = a.id
    WHERE c.user_id = p_user_id
      AND c.type = 'expense'
      AND (a.user_id = p_user_id OR a.user_id IS NULL)
    GROUP BY c.id, c.name
    HAVING SUM(t.amount) > 0
    ORDER BY total_amount DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_top_expense_categories(INTEGER, INTEGER, DATE, DATE) IS 
'Возвращает топ категорий расходов с процентами';

-- Функция получения месячного отчета по бюджетам
CREATE OR REPLACE FUNCTION get_budget_status_report(
    p_user_id INTEGER,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    budget_id INTEGER,
    category_name VARCHAR(255),
    budget_amount DECIMAL(15, 2),
    spent_amount DECIMAL(15, 2),
    remaining DECIMAL(15, 2),
    percentage_used DECIMAL(5, 2),
    is_exceeded BOOLEAN
) AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    v_start_date := DATE_TRUNC('month', MAKE_DATE(p_year, p_month, 1));
    v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;
    
    RETURN QUERY
    SELECT 
        b.id AS budget_id,
        COALESCE(c.name, 'Общий бюджет') AS category_name,
        b.amount AS budget_amount,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) AS spent_amount,
        GREATEST(0.00, b.amount - COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00)) AS remaining,
        CASE 
            WHEN b.amount > 0 THEN 
                LEAST(100.00, (COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) / b.amount) * 100.00)
            ELSE 0.00
        END AS percentage_used,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) > b.amount AS is_exceeded
    FROM budgets b
    LEFT JOIN categories c ON b.category_id = c.id
    LEFT JOIN transactions t ON (
        (b.category_id IS NULL OR t.category_id = b.category_id)
        AND t.date BETWEEN v_start_date AND v_end_date
    )
    LEFT JOIN accounts a ON t.account_id = a.id
    WHERE b.user_id = p_user_id
      AND b.is_active = TRUE
      AND b.period = 'month'
      AND (a.user_id = p_user_id OR a.user_id IS NULL)
    GROUP BY b.id, c.name, b.amount
    ORDER BY percentage_used DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_budget_status_report(INTEGER, INTEGER, INTEGER) IS 
'Возвращает отчет о статусе бюджетов за указанный месяц';

-- Функция получения транзакций с тегами
CREATE OR REPLACE FUNCTION get_transactions_with_tags(
    p_user_id INTEGER,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_tag_ids INTEGER[] DEFAULT NULL
)
RETURNS TABLE (
    transaction_id INTEGER,
    account_name VARCHAR(255),
    category_name VARCHAR(255),
    amount DECIMAL(15, 2),
    type transaction_type,
    date DATE,
    description TEXT,
    tags TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS transaction_id,
        a.name AS account_name,
        c.name AS category_name,
        t.amount,
        t.type,
        t.date,
        t.description,
        ARRAY_AGG(DISTINCT tg.name ORDER BY tg.name) FILTER (WHERE tg.name IS NOT NULL) AS tags
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    LEFT JOIN categories c ON t.category_id = c.id
    LEFT JOIN transaction_tags tt ON t.id = tt.transaction_id
    LEFT JOIN tags tg ON tt.tag_id = tg.id
    WHERE a.user_id = p_user_id
      AND (p_start_date IS NULL OR t.date >= p_start_date)
      AND (p_end_date IS NULL OR t.date <= p_end_date)
      AND (p_tag_ids IS NULL OR tg.id = ANY(p_tag_ids))
    GROUP BY t.id, a.name, c.name, t.amount, t.type, t.date, t.description
    ORDER BY t.date DESC, t.id DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_transactions_with_tags(INTEGER, DATE, DATE, INTEGER[]) IS 
'Возвращает транзакции с привязанными тегами';





