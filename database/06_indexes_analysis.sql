-- FinFlow Indexes and Performance Analysis
-- Дополнительные индексы и скрипты для анализа производительности

-- ============================================
-- ДОПОЛНИТЕЛЬНЫЕ ИНДЕКСЫ
-- ============================================

-- Составной индекс для частых запросов по пользователю и дате
CREATE INDEX IF NOT EXISTS idx_transactions_user_date_type 
ON transactions(account_id, date DESC, type) 
INCLUDE (amount, category_id);

-- Индекс для полнотекстового поиска в описаниях
CREATE INDEX IF NOT EXISTS idx_transactions_description_gin 
ON transactions USING gin(to_tsvector('russian', COALESCE(description, '')));

-- Индекс для поиска по получателю платежа
CREATE INDEX IF NOT EXISTS idx_transactions_payee 
ON transactions(payee) 
WHERE payee IS NOT NULL;

-- Частичный индекс для активных счетов
CREATE INDEX IF NOT EXISTS idx_accounts_active_user 
ON accounts(user_id, type) 
WHERE is_active = TRUE;

-- Индекс для поиска по email (уже есть UNIQUE, но для полноты)
-- CREATE UNIQUE INDEX уже создан в схеме

-- Индекс для категорий с родительской категорией
CREATE INDEX IF NOT EXISTS idx_categories_user_parent 
ON categories(user_id, parent_id) 
WHERE parent_id IS NOT NULL;

-- Индекс для активных бюджетов
CREATE INDEX IF NOT EXISTS idx_budgets_active_user_period 
ON budgets(user_id, period, start_date) 
WHERE is_active = TRUE;

-- Индекс для незавершенных целей
CREATE INDEX IF NOT EXISTS idx_goals_active_user_deadline 
ON goals(user_id, deadline) 
WHERE is_completed = FALSE;

-- ============================================
-- ФУНКЦИИ ДЛЯ АНАЛИЗА ПРОИЗВОДИТЕЛЬНОСТИ
-- ============================================

-- Функция для анализа производительности запроса
CREATE OR REPLACE FUNCTION analyze_query_performance(p_query TEXT)
RETURNS TABLE (
    plan_type TEXT,
    plan_content TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'EXPLAIN'::TEXT,
        (EXPLAIN (FORMAT TEXT) p_query)::TEXT;
    
    RETURN QUERY
    SELECT 
        'EXPLAIN ANALYZE'::TEXT,
        (EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) p_query)::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ПРИМЕРЫ ЗАПРОСОВ ДЛЯ АНАЛИЗА
-- ============================================

-- Пример 1: Получение транзакций пользователя за период
-- EXPLAIN ANALYZE
-- SELECT t.*, c.name as category_name, a.name as account_name
-- FROM transactions t
-- JOIN accounts a ON t.account_id = a.id
-- LEFT JOIN categories c ON t.category_id = c.id
-- WHERE a.user_id = 1
--   AND t.date BETWEEN '2023-01-01' AND '2023-12-31'
-- ORDER BY t.date DESC;

-- Пример 2: Агрегация расходов по категориям
-- EXPLAIN ANALYZE
-- SELECT 
--     c.name,
--     SUM(t.amount) as total,
--     COUNT(*) as count
-- FROM transactions t
-- JOIN accounts a ON t.account_id = a.id
-- JOIN categories c ON t.category_id = c.id
-- WHERE a.user_id = 1
--   AND t.type = 'expense'
--   AND t.date >= DATE_TRUNC('month', CURRENT_DATE)
-- GROUP BY c.id, c.name
-- ORDER BY total DESC;

-- Пример 3: Поиск транзакций по описанию
-- EXPLAIN ANALYZE
-- SELECT t.*
-- FROM transactions t
-- JOIN accounts a ON t.account_id = a.id
-- WHERE a.user_id = 1
--   AND to_tsvector('russian', COALESCE(t.description, '')) @@ to_tsquery('russian', 'продукты');

-- ============================================
-- СТАТИСТИКА И МОНИТОРИНГ
-- ============================================

-- Функция для получения статистики по таблицам
CREATE OR REPLACE FUNCTION get_table_statistics()
RETURNS TABLE (
    table_name TEXT,
    row_count BIGINT,
    table_size TEXT,
    index_size TEXT,
    total_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = t.tablename)::BIGINT,
        pg_size_pretty(pg_total_relation_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename)))::TEXT,
        pg_size_pretty(pg_indexes_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename)))::TEXT,
        pg_size_pretty(pg_total_relation_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename)))::TEXT
    FROM pg_tables t
    WHERE t.schemaname = 'public'
    ORDER BY pg_total_relation_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename)) DESC;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения статистики по индексам
CREATE OR REPLACE FUNCTION get_index_statistics()
RETURNS TABLE (
    table_name TEXT,
    index_name TEXT,
    index_size TEXT,
    index_usage_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        i.indexname::TEXT,
        pg_size_pretty(pg_relation_size(quote_ident(i.schemaname)||'.'||quote_ident(i.indexname)))::TEXT,
        COALESCE(s.idx_scan, 0)::BIGINT
    FROM pg_indexes i
    JOIN pg_tables t ON i.tablename = t.tablename AND i.schemaname = t.schemaname
    LEFT JOIN pg_stat_user_indexes s ON s.indexrelname = i.indexname
    WHERE i.schemaname = 'public'
    ORDER BY pg_relation_size(quote_ident(i.schemaname)||'.'||quote_ident(i.indexname)) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION analyze_query_performance(TEXT) IS 'Анализирует план выполнения запроса';
COMMENT ON FUNCTION get_table_statistics() IS 'Возвращает статистику по таблицам базы данных';
COMMENT ON FUNCTION get_index_statistics() IS 'Возвращает статистику по индексам базы данных';





