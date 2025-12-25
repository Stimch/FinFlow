# FinFlow - Система учета личных финансов и бюджетирования

Курсовая работа по дисциплине "Базы данных"

## Описание проекта

FinFlow - это полноценная информационная система для учета личных финансов, создания бюджетов, отслеживания целей и анализа финансовых привычек.

## Технологический стек

- **База данных**: PostgreSQL 15
- **Backend**: Python 3.11, FastAPI
- **Контейнеризация**: Docker, Docker Compose

## Структура проекта

```
.
├── database/              # SQL скрипты
│   ├── 01_schema.sql     # Схема базы данных
│   ├── 02_functions.sql  # Функции (скалярные и табличные)
│   ├── 03_triggers.sql   # Триггеры
│   ├── 04_views.sql      # Представления (VIEW)
│   ├── 05_seed_data.sql  # Тестовые данные
│   ├── 06_indexes_analysis.sql  # Индексы и анализ
│   └── init.sql          # Скрипт инициализации
├── backend/              # Backend приложение
│   ├── app/
│   │   ├── main.py       # Главный файл приложения
│   │   ├── config.py     # Конфигурация
│   │   ├── database.py   # Подключение к БД
│   │   ├── models.py     # SQLAlchemy модели
│   │   ├── schemas.py    # Pydantic схемы
│   │   ├── crud.py       # CRUD операции
│   │   ├── auth.py       # Аутентификация
│   │   └── routers/      # API роутеры
│   └── requirements.txt  # Зависимости Python
├── docker-compose.yml    # Конфигурация Docker Compose
└── README.md            # Документация

```

## Структура базы данных

### Таблицы (10 таблиц):

1. **users** - Пользователи системы
2. **accounts** - Финансовые счета (наличные, карты, депозиты)
3. **categories** - Категории доходов и расходов (с иерархией)
4. **transactions** - Транзакции (доходы, расходы, переводы)
5. **tags** - Теги для классификации транзакций
6. **transaction_tags** - Связь транзакций и тегов (N:M)
7. **budgets** - Бюджеты по категориям
8. **goals** - Финансовые цели
9. **recurring_transactions** - Регулярные платежи
10. **audit_log** - Журнал аудита изменений

### Связи:
- 1:1 - нет
- 1:N - users → accounts, categories, budgets, goals, etc.
- N:M - transactions ↔ tags

## Быстрый старт

### Требования

- Docker и Docker Compose
- Git

### Установка и запуск

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd cp
```

2. Запустите приложение с помощью Docker Compose:
```bash
docker-compose up -d
```

3. Инициализация базы данных выполнится автоматически при первом запуске.

4. Для загрузки тестовых данных выполните:
```bash
docker-compose exec db psql -U finflow_user -d finflow_db -f /docker-entrypoint-initdb.d/05_seed_data.sql
```

### Доступ к приложению

- **API**: http://localhost:8000
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **База данных**: localhost:5432
  - User: finflow_user
  - Password: finflow_pass
  - Database: finflow_db

## API Endpoints

### Аутентификация
- `POST /api/auth/register` - Регистрация пользователя
- `POST /api/auth/login` - Вход в систему
- `GET /api/auth/me` - Информация о текущем пользователе

### Счета (Accounts)
- `GET /api/accounts` - Список счетов
- `GET /api/accounts/{id}` - Получить счет
- `POST /api/accounts` - Создать счет
- `PUT /api/accounts/{id}` - Обновить счет
- `DELETE /api/accounts/{id}` - Удалить счет
- `GET /api/accounts/summary/total-balance` - Общий баланс

### Категории (Categories)
- `GET /api/categories` - Список категорий
- `GET /api/categories/{id}` - Получить категорию
- `POST /api/categories` - Создать категорию
- `PUT /api/categories/{id}` - Обновить категорию
- `DELETE /api/categories/{id}` - Удалить категорию

### Транзакции (Transactions)
- `GET /api/transactions` - Список транзакций
- `GET /api/transactions/{id}` - Получить транзакцию
- `POST /api/transactions` - Создать транзакцию
- `PUT /api/transactions/{id}` - Обновить транзакцию
- `DELETE /api/transactions/{id}` - Удалить транзакцию
- `POST /api/transactions/batch-import` - Массовая загрузка транзакций
- `GET /api/transactions/reports/financial` - Финансовый отчет
- `GET /api/transactions/reports/top-expenses` - Топ расходов

### Бюджеты (Budgets)
- `GET /api/budgets` - Список бюджетов
- `GET /api/budgets/{id}` - Получить бюджет
- `POST /api/budgets` - Создать бюджет
- `PUT /api/budgets/{id}` - Обновить бюджет
- `DELETE /api/budgets/{id}` - Удалить бюджет
- `GET /api/budgets/reports/status` - Статус бюджетов

### Цели (Goals)
- `GET /api/goals` - Список целей
- `GET /api/goals/{id}` - Получить цель
- `POST /api/goals` - Создать цель
- `PUT /api/goals/{id}` - Обновить цель
- `DELETE /api/goals/{id}` - Удалить цель
- `GET /api/goals/{id}/progress` - Прогресс цели

### Теги (Tags)
- `GET /api/tags` - Список тегов
- `GET /api/tags/{id}` - Получить тег
- `POST /api/tags` - Создать тег
- `PUT /api/tags/{id}` - Обновить тег
- `DELETE /api/tags/{id}` - Удалить тег

## Особенности реализации

### Ограничения целостности
- PRIMARY KEY на всех таблицах
- FOREIGN KEY с каскадным удалением/обновлением
- UNIQUE ограничения (email, уникальные пары)
- CHECK ограничения (положительные суммы, диапазоны)
- NOT NULL для обязательных полей

### Триггеры
- **Аудит**: Автоматическая запись всех изменений в `audit_log`
- **Баланс счетов**: Автоматическое обновление баланса при транзакциях
- **Статус целей**: Автоматическое обновление статуса выполнения
- **updated_at**: Автоматическое обновление времени изменения

### Функции
- **Скалярные**: 
  - `get_user_total_balance()` - общий баланс пользователя
  - `get_transactions_sum()` - сумма транзакций за период
  - `get_goal_progress()` - процент выполнения цели
  - `get_budget_exceeded()` - превышение бюджета
  - `get_category_avg_expense()` - средний расход по категории

- **Табличные**:
  - `get_user_financial_report()` - финансовый отчет
  - `get_top_expense_categories()` - топ категорий расходов
  - `get_budget_status_report()` - отчет по бюджетам
  - `get_transactions_with_tags()` - транзакции с тегами

### Представления (VIEW)
1. `v_user_accounts_summary` - Сводка по счетам
2. `v_monthly_financial_summary` - Месячные доходы и расходы
3. `v_current_month_expenses_by_category` - Расходы по категориям
4. `v_goals_status` - Статус целей
5. `v_top_transactions` - Топ транзакций
6. `v_recurring_transactions_analysis` - Анализ регулярных платежей
7. `v_tags_summary` - Сводка по тегам
8. `v_budgets_with_status` - Бюджеты со статусом

### Индексы
- Индексы на внешние ключи
- Составные индексы для частых запросов
- Частичные индексы для активных записей
- GIN индекс для полнотекстового поиска

## Тестовые данные

База данных содержит:
- 10 пользователей
- ~40 счетов (по 3-5 на пользователя)
- ~100 категорий (по 10 на пользователя)
- 5000+ транзакций (по 500 на пользователя)
- Бюджеты, цели, теги и регулярные транзакции

## Анализ производительности

Для анализа производительности запросов используйте:

```sql
EXPLAIN ANALYZE
SELECT * FROM transactions 
WHERE account_id IN (
    SELECT id FROM accounts WHERE user_id = 1
) 
AND date BETWEEN '2023-01-01' AND '2023-12-31';
```

Функции для получения статистики:
- `get_table_statistics()` - статистика по таблицам
- `get_index_statistics()` - статистика по индексам

## Безопасность

- Пароли хешируются с помощью bcrypt
- JWT токены для аутентификации
- Параметризованные SQL-запросы (защита от SQL-инъекций)
- Проверка прав доступа (пользователь может работать только со своими данными)

## Разработка

### Локальная разработка без Docker

1. Установите PostgreSQL и создайте базу данных
2. Установите зависимости:
```bash
cd backend
pip install -r requirements.txt
```

3. Настройте переменные окружения (создайте `.env`):
```
DATABASE_URL=postgresql://user:password@localhost:5432/finflow_db
SECRET_KEY=your-secret-key
```

4. Инициализируйте базу данных:
```bash
psql -U user -d finflow_db -f database/01_schema.sql
psql -U user -d finflow_db -f database/02_functions.sql
psql -U user -d finflow_db -f database/03_triggers.sql
psql -U user -d finflow_db -f database/04_views.sql
psql -U user -d finflow_db -f database/06_indexes_analysis.sql
```

5. Запустите приложение:
```bash
uvicorn app.main:app --reload
```

## Лицензия

Этот проект создан в образовательных целях для курсовой работы.

## Автор

Студент группы [номер группы]





