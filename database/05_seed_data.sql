-- FinFlow Seed Data
-- Скрипт для генерации тестовых данных

-- Очистка данных (в обратном порядке зависимостей)
TRUNCATE TABLE transaction_tags CASCADE;
TRUNCATE TABLE transactions CASCADE;
TRUNCATE TABLE recurring_transactions CASCADE;
TRUNCATE TABLE budgets CASCADE;
TRUNCATE TABLE goals CASCADE;
TRUNCATE TABLE tags CASCADE;
TRUNCATE TABLE categories CASCADE;
TRUNCATE TABLE accounts CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE audit_log CASCADE;

-- Сброс последовательностей
ALTER SEQUENCE users_id_seq RESTART WITH 1;
ALTER SEQUENCE accounts_id_seq RESTART WITH 1;
ALTER SEQUENCE categories_id_seq RESTART WITH 1;
ALTER SEQUENCE transactions_id_seq RESTART WITH 1;
ALTER SEQUENCE tags_id_seq RESTART WITH 1;
ALTER SEQUENCE budgets_id_seq RESTART WITH 1;
ALTER SEQUENCE goals_id_seq RESTART WITH 1;
ALTER SEQUENCE recurring_transactions_id_seq RESTART WITH 1;
ALTER SEQUENCE audit_log_id_seq RESTART WITH 1;

-- Вставка тестовых пользователей (10 пользователей)
INSERT INTO users (email, password_hash, full_name, currency, timezone) VALUES
('user1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Иван Иванов', 'RUB', 'Europe/Moscow'),
('user2@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Мария Петрова', 'RUB', 'Europe/Moscow'),
('user3@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Алексей Сидоров', 'USD', 'America/New_York'),
('user4@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Елена Козлова', 'EUR', 'Europe/Berlin'),
('user5@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Дмитрий Волков', 'RUB', 'Europe/Moscow'),
('user6@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Ольга Новикова', 'RUB', 'Europe/Moscow'),
('user7@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Сергей Морозов', 'RUB', 'Europe/Moscow'),
('user8@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Анна Лебедева', 'RUB', 'Europe/Moscow'),
('user9@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Павел Соколов', 'RUB', 'Europe/Moscow'),
('user10@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqJZ5q5q5q', 'Татьяна Орлова', 'RUB', 'Europe/Moscow');

-- Вставка категорий (для каждого пользователя создаем базовые категории)
DO $$
DECLARE
    user_rec RECORD;
    cat_id INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        -- Родительские категории доходов
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Зарплата', 'income', NULL, '💰', '#4CAF50') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Инвестиции', 'income', NULL, '📈', '#2196F3') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Подарки', 'income', NULL, '🎁', '#FF9800') RETURNING id INTO cat_id;
        
        -- Родительские категории расходов
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Продукты', 'expense', NULL, '🛒', '#F44336') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Транспорт', 'expense', NULL, '🚗', '#9C27B0') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Развлечения', 'expense', NULL, '🎬', '#E91E63') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Здоровье', 'expense', NULL, '🏥', '#00BCD4') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Образование', 'expense', NULL, '📚', '#3F51B5') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Коммунальные услуги', 'expense', NULL, '🏠', '#795548') RETURNING id INTO cat_id;
        
        INSERT INTO categories (user_id, name, type, parent_id, icon, color) VALUES
        (user_rec.id, 'Одежда', 'expense', NULL, '👕', '#FF5722') RETURNING id INTO cat_id;
    END LOOP;
END $$;

-- Вставка счетов (по 3-5 счетов на пользователя)
DO $$
DECLARE
    user_rec RECORD;
    acc_types account_type[] := ARRAY['cash', 'debit_card', 'credit_card', 'deposit']::account_type[];
    acc_names TEXT[] := ARRAY['Наличные', 'Основная карта', 'Кредитная карта', 'Депозит'];
    i INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        FOR i IN 1..array_length(acc_types, 1) LOOP
            INSERT INTO accounts (user_id, name, type, balance, bank_name, account_number) VALUES
            (user_rec.id, 
             acc_names[i] || ' ' || user_rec.id::TEXT,
             acc_types[i],
             (RANDOM() * 500000 + 10000)::DECIMAL(15, 2),
             CASE WHEN acc_types[i] != 'cash' THEN 'Банк ' || user_rec.id::TEXT ELSE NULL END,
             CASE WHEN acc_types[i] != 'cash' THEN LPAD((user_rec.id * 1000 + i)::TEXT, 16, '0') ELSE NULL END);
        END LOOP;
    END LOOP;
END $$;

-- Вставка тегов
DO $$
DECLARE
    user_rec RECORD;
    tag_names TEXT[] := ARRAY['важное', 'работа', 'личное', 'семья', 'отпуск', 'срочное'];
    tag_colors TEXT[] := ARRAY['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF'];
    i INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        FOR i IN 1..array_length(tag_names, 1) LOOP
            INSERT INTO tags (user_id, name, color) VALUES
            (user_rec.id, tag_names[i], tag_colors[i]);
        END LOOP;
    END LOOP;
END $$;

-- Вставка транзакций (5000+ записей)
-- Генерируем транзакции за последние 2 года
DO $$
DECLARE
    user_rec RECORD;
    acc_rec RECORD;
    cat_rec RECORD;
    trans_date DATE;
    trans_amount DECIMAL(15, 2);
    trans_type transaction_type;
    i INTEGER;
    days_back INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        -- Генерируем по 500 транзакций на пользователя
        FOR i IN 1..500 LOOP
            -- Случайная дата за последние 2 года
            days_back := (RANDOM() * 730)::INTEGER;
            trans_date := CURRENT_DATE - (days_back || ' days')::INTERVAL;
            
            -- Случайный счет
            SELECT * INTO acc_rec FROM accounts 
            WHERE user_id = user_rec.id AND is_active = TRUE 
            ORDER BY RANDOM() LIMIT 1;
            
            -- Случайная категория
            SELECT * INTO cat_rec FROM categories 
            WHERE user_id = user_rec.id 
            ORDER BY RANDOM() LIMIT 1;
            
            -- Определяем тип транзакции
            IF cat_rec.type = 'income' THEN
                trans_type := 'income';
                trans_amount := (RANDOM() * 100000 + 5000)::DECIMAL(15, 2);
            ELSE
                trans_type := 'expense';
                trans_amount := (RANDOM() * 50000 + 100)::DECIMAL(15, 2);
            END IF;
            
            INSERT INTO transactions (
                account_id, category_id, amount, type, date, description, payee
            ) VALUES (
                acc_rec.id,
                cat_rec.id,
                trans_amount,
                trans_type,
                trans_date,
                'Тестовая транзакция ' || i,
                CASE WHEN RANDOM() > 0.5 THEN 'Плательщик ' || i ELSE NULL END
            );
        END LOOP;
    END LOOP;
END $$;

-- Вставка связей транзакций и тегов
INSERT INTO transaction_tags (transaction_id, tag_id)
SELECT 
    t.id,
    tg.id
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN tags tg ON a.user_id = tg.user_id
WHERE RANDOM() > 0.7  -- 30% транзакций получат теги
LIMIT 1500;

-- Вставка бюджетов
DO $$
DECLARE
    user_rec RECORD;
    cat_rec RECORD;
    budget_amount DECIMAL(15, 2);
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        FOR cat_rec IN SELECT * FROM categories 
            WHERE user_id = user_rec.id AND type = 'expense' 
            LIMIT 5 LOOP
            
            budget_amount := (RANDOM() * 50000 + 5000)::DECIMAL(15, 2);
            
            INSERT INTO budgets (user_id, category_id, amount, period, start_date) VALUES
            (user_rec.id, cat_rec.id, budget_amount, 'month', 
             DATE_TRUNC('month', CURRENT_DATE)::DATE);
        END LOOP;
    END LOOP;
END $$;

-- Вставка финансовых целей
DO $$
DECLARE
    user_rec RECORD;
    goal_names TEXT[] := ARRAY['Новый автомобиль', 'Отпуск', 'Ремонт квартиры', 'Образование', 'Накопления'];
    i INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        FOR i IN 1..array_length(goal_names, 1) LOOP
            INSERT INTO goals (
                user_id, name, target_amount, current_amount, deadline, priority
            ) VALUES (
                user_rec.id,
                goal_names[i],
                (RANDOM() * 1000000 + 50000)::DECIMAL(15, 2),
                (RANDOM() * 200000)::DECIMAL(15, 2),
                CURRENT_DATE + (RANDOM() * 365 + 30)::INTEGER,
                (RANDOM() * 9 + 1)::INTEGER
            );
        END LOOP;
    END LOOP;
END $$;

-- Вставка регулярных транзакций
DO $$
DECLARE
    user_rec RECORD;
    acc_rec RECORD;
    cat_rec RECORD;
    intervals recurring_interval[] := ARRAY['daily', 'weekly', 'monthly', 'yearly']::recurring_interval;
    i INTEGER;
BEGIN
    FOR user_rec IN SELECT id FROM users LOOP
        FOR i IN 1..10 LOOP
            SELECT * INTO acc_rec FROM accounts 
            WHERE user_id = user_rec.id AND is_active = TRUE 
            ORDER BY RANDOM() LIMIT 1;
            
            SELECT * INTO cat_rec FROM categories 
            WHERE user_id = user_rec.id 
            ORDER BY RANDOM() LIMIT 1;
            
            INSERT INTO recurring_transactions (
                user_id, account_id, category_id, description, amount, 
                type, interval, next_date
            ) VALUES (
                user_rec.id,
                acc_rec.id,
                cat_rec.id,
                'Регулярная транзакция ' || i,
                (RANDOM() * 20000 + 1000)::DECIMAL(15, 2),
                cat_rec.type::transaction_type,
                intervals[(RANDOM() * 4 + 1)::INTEGER],
                CURRENT_DATE + (RANDOM() * 30)::INTEGER
            );
        END LOOP;
    END LOOP;
END $$;

-- Обновление балансов счетов на основе транзакций
UPDATE accounts a
SET balance = COALESCE((
    SELECT 
        SUM(CASE 
            WHEN t.type = 'income' THEN t.amount
            WHEN t.type = 'expense' THEN -t.amount
            ELSE 0
        END)
    FROM transactions t
    WHERE t.account_id = a.id
), 0.00);

COMMENT ON TABLE users IS 'Тестовые данные загружены';





