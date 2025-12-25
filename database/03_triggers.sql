-- FinFlow Database Triggers
-- Триггеры для аудита и автоматического обновления данных

-- ============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ТРИГГЕРОВ
-- ============================================

-- Функция для записи в журнал аудита
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id INTEGER;
    v_old_data JSONB;
    v_new_data JSONB;
BEGIN
    -- Получаем ID пользователя из сессии (если установлен)
    v_user_id := current_setting('app.user_id', TRUE)::INTEGER;
    
    -- Формируем JSONB данные
    IF TG_OP = 'DELETE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF TG_OP = 'INSERT' THEN
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
    END IF;
    
    -- Записываем в журнал аудита
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        old_data,
        new_data,
        changed_by
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE((NEW.id)::INTEGER, (OLD.id)::INTEGER),
        TG_OP::audit_action,
        v_old_data,
        v_new_data,
        v_user_id
    );
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ТРИГГЕРЫ АУДИТА
-- ============================================

-- Триггеры аудита для таблицы users
CREATE TRIGGER audit_users_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы accounts
CREATE TRIGGER audit_accounts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы categories
CREATE TRIGGER audit_categories_trigger
    AFTER INSERT OR UPDATE OR DELETE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы transactions
CREATE TRIGGER audit_transactions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы budgets
CREATE TRIGGER audit_budgets_trigger
    AFTER INSERT OR UPDATE OR DELETE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы goals
CREATE TRIGGER audit_goals_trigger
    AFTER INSERT OR UPDATE OR DELETE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы recurring_transactions
CREATE TRIGGER audit_recurring_transactions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Триггеры аудита для таблицы tags
CREATE TRIGGER audit_tags_trigger
    AFTER INSERT OR UPDATE OR DELETE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- ============================================
-- ТРИГГЕРЫ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ
-- ============================================

-- Функция автоматического обновления баланса счета при транзакции
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_old_amount DECIMAL(15, 2);
    v_new_amount DECIMAL(15, 2);
    v_account_id INTEGER;
BEGIN
    -- Определяем account_id и суммы
    IF TG_OP = 'DELETE' THEN
        v_account_id := OLD.account_id;
        v_old_amount := OLD.amount;
        v_new_amount := 0;
    ELSIF TG_OP = 'UPDATE' THEN
        v_account_id := NEW.account_id;
        v_old_amount := OLD.amount;
        v_new_amount := NEW.amount;
    ELSE -- INSERT
        v_account_id := NEW.account_id;
        v_old_amount := 0;
        v_new_amount := NEW.amount;
    END IF;
    
    -- Обновляем баланс счета
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.account_id = NEW.account_id) THEN
        -- Обратная операция для старой транзакции
        IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.type = 'income') THEN
            UPDATE accounts 
            SET balance = balance - v_old_amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = v_account_id;
        ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.type = 'expense') THEN
            UPDATE accounts 
            SET balance = balance + v_old_amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = v_account_id;
        END IF;
    END IF;
    
    -- Применяем новую транзакцию
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (OLD.account_id != NEW.account_id OR OLD.type != NEW.type OR OLD.amount != NEW.amount)) THEN
        IF NEW.type = 'income' THEN
            UPDATE accounts 
            SET balance = balance + v_new_amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.account_id;
        ELSIF NEW.type = 'expense' THEN
            UPDATE accounts 
            SET balance = balance - v_new_amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.account_id;
        END IF;
    END IF;
    
    -- Обработка переводов между счетами
    IF TG_OP = 'INSERT' AND NEW.type = 'transfer' THEN
        -- Для переводов нужно обработать оба счета
        -- В данной реализации transfer обрабатывается как expense на одном счете
        -- и income на другом (требует дополнительной логики в приложении)
        NULL;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического обновления баланса
CREATE TRIGGER update_account_balance_trigger
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

-- Функция автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для автоматического обновления updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recurring_transactions_updated_at
    BEFORE UPDATE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Функция автоматического обновления статуса цели
CREATE OR REPLACE FUNCTION update_goal_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Автоматически помечаем цель как выполненную
    IF NEW.current_amount >= NEW.target_amount AND NOT NEW.is_completed THEN
        NEW.is_completed := TRUE;
        NEW.completed_at := CURRENT_TIMESTAMP;
    ELSIF NEW.current_amount < NEW.target_amount AND NEW.is_completed THEN
        NEW.is_completed := FALSE;
        NEW.completed_at := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического обновления статуса цели
CREATE TRIGGER update_goal_status_trigger
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_goal_status();

-- Функция для обработки регулярных транзакций
CREATE OR REPLACE FUNCTION process_recurring_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_next_date DATE;
BEGIN
    -- Вычисляем следующую дату выполнения
    CASE NEW.interval
        WHEN 'daily' THEN
            v_next_date := NEW.next_date + INTERVAL '1 day';
        WHEN 'weekly' THEN
            v_next_date := NEW.next_date + INTERVAL '1 week';
        WHEN 'monthly' THEN
            v_next_date := NEW.next_date + INTERVAL '1 month';
        WHEN 'yearly' THEN
            v_next_date := NEW.next_date + INTERVAL '1 year';
    END CASE;
    
    -- Обновляем next_date
    NEW.next_date := v_next_date;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для обработки регулярных транзакций (вызывается при создании транзакции из регулярной)
-- Этот триггер будет вызываться из приложения, но можно создать функцию для автоматической обработки

COMMENT ON FUNCTION audit_trigger_function() IS 'Функция для записи изменений в журнал аудита';
COMMENT ON FUNCTION update_account_balance() IS 'Автоматически обновляет баланс счета при изменении транзакций';
COMMENT ON FUNCTION update_updated_at_column() IS 'Автоматически обновляет поле updated_at';
COMMENT ON FUNCTION update_goal_status() IS 'Автоматически обновляет статус выполнения цели';





