-- FinFlow Database Views
-- Представления для аналитических запросов

-- ============================================
-- ПРЕДСТАВЛЕНИЯ
-- ============================================

-- 1. Представление: Сводка по счетам пользователя
CREATE OR REPLACE VIEW v_user_accounts_summary AS
SELECT 
    u.id AS user_id,
    u.email,
    COUNT(DISTINCT a.id) AS total_accounts,
    COUNT(DISTINCT CASE WHEN a.is_active THEN a.id END) AS active_accounts,
    SUM(CASE WHEN a.is_active THEN a.balance ELSE 0 END) AS total_balance,
    SUM(CASE WHEN a.type = 'cash' AND a.is_active THEN a.balance ELSE 0 END) AS cash_balance,
    SUM(CASE WHEN a.type = 'debit_card' AND a.is_active THEN a.balance ELSE 0 END) AS debit_balance,
    SUM(CASE WHEN a.type = 'credit_card' AND a.is_active THEN a.balance ELSE 0 END) AS credit_balance,
    SUM(CASE WHEN a.type = 'deposit' AND a.is_active THEN a.balance ELSE 0 END) AS deposit_balance
FROM users u
LEFT JOIN accounts a ON u.id = a.user_id
GROUP BY u.id, u.email;

COMMENT ON VIEW v_user_accounts_summary IS 'Сводная информация по счетам пользователей';

-- 2. Представление: Месячные доходы и расходы
CREATE OR REPLACE VIEW v_monthly_financial_summary AS
SELECT 
    a.user_id,
    DATE_TRUNC('month', t.date)::DATE AS month,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) AS total_expense,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) - 
    SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) AS net_income,
    COUNT(CASE WHEN t.type = 'income' THEN 1 END) AS income_count,
    COUNT(CASE WHEN t.type = 'expense' THEN 1 END) AS expense_count,
    COUNT(*) AS total_transactions
FROM transactions t
JOIN accounts a ON t.account_id = a.id
GROUP BY a.user_id, DATE_TRUNC('month', t.date)
ORDER BY a.user_id, month DESC;

COMMENT ON VIEW v_monthly_financial_summary IS 'Месячная сводка доходов и расходов по пользователям';

-- 3. Представление: Расходы по категориям за текущий месяц
CREATE OR REPLACE VIEW v_current_month_expenses_by_category AS
SELECT 
    a.user_id,
    c.id AS category_id,
    c.name AS category_name,
    c.parent_id,
    COALESCE(parent_cat.name, 'Без родительской категории') AS parent_category_name,
    SUM(t.amount) AS total_amount,
    COUNT(t.id) AS transaction_count,
    AVG(t.amount) AS avg_amount,
    MIN(t.amount) AS min_amount,
    MAX(t.amount) AS max_amount,
    c.budget_limit,
    CASE 
        WHEN c.budget_limit > 0 THEN 
            (SUM(t.amount) / c.budget_limit) * 100.00
        ELSE NULL
    END AS budget_usage_percent
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN categories c ON t.category_id = c.id
LEFT JOIN categories parent_cat ON c.parent_id = parent_cat.id
WHERE t.type = 'expense'
  AND DATE_TRUNC('month', t.date) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY a.user_id, c.id, c.name, c.parent_id, parent_cat.name, c.budget_limit
ORDER BY a.user_id, total_amount DESC;

COMMENT ON VIEW v_current_month_expenses_by_category IS 'Расходы по категориям за текущий месяц с анализом бюджета';

-- 4. Представление: Статус финансовых целей
CREATE OR REPLACE VIEW v_goals_status AS
SELECT 
    g.id AS goal_id,
    g.user_id,
    u.email,
    g.name AS goal_name,
    g.target_amount,
    g.current_amount,
    g.deadline,
    g.priority,
    g.is_completed,
    g.completed_at,
    CASE 
        WHEN g.target_amount > 0 THEN 
            LEAST(100.00, (g.current_amount / g.target_amount) * 100.00)
        ELSE 0.00
    END AS progress_percent,
    CASE 
        WHEN g.deadline IS NOT NULL THEN 
            g.deadline - CURRENT_DATE
        ELSE NULL
    END AS days_remaining,
    CASE 
        WHEN g.deadline IS NOT NULL AND g.deadline < CURRENT_DATE AND NOT g.is_completed THEN 
            TRUE
        ELSE FALSE
    END AS is_overdue,
    g.target_amount - g.current_amount AS amount_remaining,
    CASE 
        WHEN g.deadline IS NOT NULL AND g.deadline > CURRENT_DATE THEN 
            (g.target_amount - g.current_amount) / GREATEST(1, g.deadline - CURRENT_DATE)
        ELSE NULL
    END AS required_daily_saving
FROM goals g
JOIN users u ON g.user_id = u.id
ORDER BY g.user_id, g.priority DESC, g.deadline;

COMMENT ON VIEW v_goals_status IS 'Детальный статус финансовых целей с расчетом прогресса';

-- 5. Представление: Топ транзакций по сумме
CREATE OR REPLACE VIEW v_top_transactions AS
SELECT 
    t.id AS transaction_id,
    a.user_id,
    a.name AS account_name,
    c.name AS category_name,
    t.amount,
    t.type,
    t.date,
    t.description,
    t.payee,
    ROW_NUMBER() OVER (
        PARTITION BY a.user_id, t.type 
        ORDER BY t.amount DESC, t.date DESC
    ) AS rank_by_type
FROM transactions t
JOIN accounts a ON t.account_id = a.id
LEFT JOIN categories c ON t.category_id = c.id
ORDER BY a.user_id, t.type, t.amount DESC;

COMMENT ON VIEW v_top_transactions IS 'Топ транзакций по сумме с ранжированием';

-- 6. Представление: Анализ регулярных платежей
CREATE OR REPLACE VIEW v_recurring_transactions_analysis AS
SELECT 
    rt.id AS recurring_id,
    rt.user_id,
    u.email,
    rt.description,
    rt.amount,
    rt.type,
    rt.interval,
    rt.next_date,
    rt.end_date,
    rt.is_active,
    COUNT(t.id) AS executed_count,
    SUM(t.amount) AS total_executed_amount,
    MIN(t.date) AS first_execution_date,
    MAX(t.date) AS last_execution_date,
    CASE 
        WHEN rt.interval = 'daily' THEN rt.amount * 30
        WHEN rt.interval = 'weekly' THEN rt.amount * 4
        WHEN rt.interval = 'monthly' THEN rt.amount
        WHEN rt.interval = 'yearly' THEN rt.amount / 12
        ELSE 0
    END AS estimated_monthly_amount
FROM recurring_transactions rt
JOIN users u ON rt.user_id = u.id
LEFT JOIN transactions t ON rt.id = t.recurring_transaction_id
GROUP BY rt.id, rt.user_id, u.email, rt.description, rt.amount, rt.type, 
         rt.interval, rt.next_date, rt.end_date, rt.is_active
ORDER BY rt.user_id, estimated_monthly_amount DESC;

COMMENT ON VIEW v_recurring_transactions_analysis IS 'Анализ регулярных транзакций с расчетом статистики';

-- 7. Представление: Сводка по тегам
CREATE OR REPLACE VIEW v_tags_summary AS
SELECT 
    tg.user_id,
    tg.id AS tag_id,
    tg.name AS tag_name,
    COUNT(DISTINCT tt.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS avg_amount,
    MIN(t.date) AS first_use_date,
    MAX(t.date) AS last_use_date
FROM tags tg
LEFT JOIN transaction_tags tt ON tg.id = tt.tag_id
LEFT JOIN transactions t ON tt.transaction_id = t.id
GROUP BY tg.user_id, tg.id, tg.name
ORDER BY tg.user_id, transaction_count DESC;

COMMENT ON VIEW v_tags_summary IS 'Сводная информация по использованию тегов';

-- 8. Представление: Бюджеты с текущим статусом
CREATE OR REPLACE VIEW v_budgets_with_status AS
SELECT 
    b.id AS budget_id,
    b.user_id,
    b.category_id,
    COALESCE(c.name, 'Общий бюджет') AS category_name,
    b.amount AS budget_amount,
    b.period,
    b.start_date,
    b.end_date,
    b.is_active,
    CASE 
        WHEN b.period = 'month' THEN 
            DATE_TRUNC('month', CURRENT_DATE)::DATE
        WHEN b.period = 'year' THEN 
            DATE_TRUNC('year', CURRENT_DATE)::DATE
    END AS current_period_start,
    CASE 
        WHEN b.period = 'month' THEN 
            (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
        WHEN b.period = 'year' THEN 
            (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year - 1 day')::DATE
    END AS current_period_end,
    COALESCE(SUM(CASE 
        WHEN t.type = 'expense' 
        AND t.date >= CASE 
            WHEN b.period = 'month' THEN DATE_TRUNC('month', CURRENT_DATE)::DATE
            WHEN b.period = 'year' THEN DATE_TRUNC('year', CURRENT_DATE)::DATE
        END
        AND t.date <= CASE 
            WHEN b.period = 'month' THEN (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
            WHEN b.period = 'year' THEN (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year - 1 day')::DATE
        END
        THEN t.amount ELSE 0 
    END), 0.00) AS spent_amount,
    GREATEST(0.00, b.amount - COALESCE(SUM(CASE 
        WHEN t.type = 'expense' 
        AND t.date >= CASE 
            WHEN b.period = 'month' THEN DATE_TRUNC('month', CURRENT_DATE)::DATE
            WHEN b.period = 'year' THEN DATE_TRUNC('year', CURRENT_DATE)::DATE
        END
        AND t.date <= CASE 
            WHEN b.period = 'month' THEN (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
            WHEN b.period = 'year' THEN (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year - 1 day')::DATE
        END
        THEN t.amount ELSE 0 
    END), 0.00)) AS remaining_amount,
    CASE 
        WHEN b.amount > 0 THEN 
            LEAST(100.00, (COALESCE(SUM(CASE 
                WHEN t.type = 'expense' 
                AND t.date >= CASE 
                    WHEN b.period = 'month' THEN DATE_TRUNC('month', CURRENT_DATE)::DATE
                    WHEN b.period = 'year' THEN DATE_TRUNC('year', CURRENT_DATE)::DATE
                END
                AND t.date <= CASE 
                    WHEN b.period = 'month' THEN (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
                    WHEN b.period = 'year' THEN (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year - 1 day')::DATE
                END
                THEN t.amount ELSE 0 
            END), 0.00) / b.amount) * 100.00)
        ELSE 0.00
    END AS usage_percent
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.id
LEFT JOIN transactions t ON (
    (b.category_id IS NULL OR t.category_id = b.category_id)
)
LEFT JOIN accounts a ON t.account_id = a.id AND a.user_id = b.user_id
WHERE b.is_active = TRUE
GROUP BY b.id, b.user_id, b.category_id, c.name, b.amount, b.period, 
         b.start_date, b.end_date, b.is_active
ORDER BY b.user_id, usage_percent DESC;

COMMENT ON VIEW v_budgets_with_status IS 'Бюджеты с текущим статусом использования за текущий период';





