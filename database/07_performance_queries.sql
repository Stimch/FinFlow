-- FinFlow Performance Analysis Queries
-- Примеры запросов для демонстрации оптимизации

-- ============================================
-- ПРИМЕРЫ ЗАПРОСОВ ДЛЯ АНАЛИЗА ПРОИЗВОДИТЕЛЬНОСТИ
-- ============================================

-- Пример 1: Получение транзакций пользователя за период
-- БЕЗ ИНДЕКСА (если удалить индекс idx_transactions_date):
EXPLAIN ANALYZE
SELECT t.*, c.name as category_name, a.name as account_name
FROM transactions t
JOIN accounts a ON t.account_id = a.id
LEFT JOIN categories c ON t.category_id = c.id
WHERE a.user_id = 1
  AND t.date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY t.date DESC
LIMIT 100;

-- С ИНДЕКСОМ (idx_transactions_date, idx_transactions_date_type):
-- Тот же запрос, но с использованием индексов
-- Время выполнения должно значительно уменьшиться

-- Пример 2: Агрегация расходов по категориям за месяц
EXPLAIN ANALYZE
SELECT 
    c.name,
    SUM(t.amount) as total,
    COUNT(*) as count,
    AVG(t.amount) as avg_amount
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN categories c ON t.category_id = c.id
WHERE a.user_id = 1
  AND t.type = 'expense'
  AND t.date >= DATE_TRUNC('month', CURRENT_DATE)
  AND t.date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY c.id, c.name
ORDER BY total DESC;

-- Пример 3: Поиск транзакций по описанию (полнотекстовый поиск)
EXPLAIN ANALYZE
SELECT t.*, a.name as account_name
FROM transactions t
JOIN accounts a ON t.account_id = a.id
WHERE a.user_id = 1
  AND to_tsvector('russian', COALESCE(t.description, '')) 
      @@ to_tsquery('russian', 'продукты | магазин');

-- Пример 4: Получение топ категорий расходов
EXPLAIN ANALYZE
SELECT 
    c.id,
    c.name,
    SUM(t.amount) as total_amount,
    COUNT(t.id) as transaction_count
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN categories c ON t.category_id = c.id
WHERE a.user_id = 1
  AND t.type = 'expense'
  AND t.date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY c.id, c.name
ORDER BY total_amount DESC
LIMIT 10;

-- Пример 5: Статус бюджетов с расчетом потраченных средств
EXPLAIN ANALYZE
SELECT 
    b.id,
    COALESCE(c.name, 'Общий бюджет') as category_name,
    b.amount as budget_amount,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) as spent_amount,
    b.amount - COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0.00) as remaining
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.id
LEFT JOIN transactions t ON (
    (b.category_id IS NULL OR t.category_id = b.category_id)
    AND t.date >= DATE_TRUNC('month', CURRENT_DATE)
    AND t.date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
)
LEFT JOIN accounts a ON t.account_id = a.id AND a.user_id = b.user_id
WHERE b.user_id = 1
  AND b.is_active = TRUE
  AND b.period = 'month'
GROUP BY b.id, c.name, b.amount;

-- Пример 6: Транзакции с тегами
EXPLAIN ANALYZE
SELECT 
    t.id,
    t.amount,
    t.date,
    t.description,
    ARRAY_AGG(tg.name) as tags
FROM transactions t
JOIN accounts a ON t.account_id = a.id
LEFT JOIN transaction_tags tt ON t.id = tt.transaction_id
LEFT JOIN tags tg ON tt.tag_id = tg.id
WHERE a.user_id = 1
  AND t.date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY t.id, t.amount, t.date, t.description
ORDER BY t.date DESC;

-- Пример 7: Использование представления (VIEW)
EXPLAIN ANALYZE
SELECT * FROM v_monthly_financial_summary
WHERE user_id = 1
  AND month >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '6 months'
ORDER BY month DESC;

-- Пример 8: Использование функции
EXPLAIN ANALYZE
SELECT * FROM get_user_financial_report(
    1,
    CURRENT_DATE - INTERVAL '3 months',
    CURRENT_DATE
);

-- ============================================
-- СРАВНЕНИЕ ПРОИЗВОДИТЕЛЬНОСТИ
-- ============================================

-- Для демонстрации улучшения производительности:
-- 1. Выполните запрос БЕЗ индексов (временно удалите индексы)
-- 2. Запишите время выполнения
-- 3. Создайте индексы
-- 4. Выполните тот же запрос
-- 5. Сравните время выполнения

-- Пример удаления индекса для тестирования:
-- DROP INDEX IF EXISTS idx_transactions_date;

-- Пример создания индекса:
-- CREATE INDEX idx_transactions_date ON transactions(date);

-- ============================================
-- СТАТИСТИКА ИСПОЛЬЗОВАНИЯ ИНДЕКСОВ
-- ============================================

-- Просмотр статистики использования индексов
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Просмотр размера индексов
SELECT 
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;





