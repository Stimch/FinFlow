# Быстрый старт FinFlow

## Запуск за 3 шага

### 0. Установите Docker Desktop (если еще не установлен)

Скачайте и установите Docker Desktop для Windows:
https://www.docker.com/products/docker-desktop/

После установки перезапустите компьютер и убедитесь, что Docker Desktop запущен.

### 1. Перейдите в директорию проекта

```powershell
cd c:\Projects\DB_Labs\cp
```

### 2. Запустите Docker Compose

**Для новых версий Docker (рекомендуется):**
```powershell
docker compose up -d
```

**Для старых версий (если команда выше не работает):**
```powershell
docker-compose up -d
```

Подождите 10-20 секунд, пока база данных инициализируется.

### 3. Откройте документацию API

Откройте в браузере: **http://localhost:8000/docs**

## Первые шаги

### 1. Зарегистрируйте пользователя

В Swagger UI (`/docs`):
1. Найдите endpoint `POST /api/auth/register`
2. Нажмите "Try it out"
3. Введите данные:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "Test User",
  "currency": "RUB"
}
```
4. Нажмите "Execute"

### 2. Войдите в систему

1. Найдите endpoint `POST /api/auth/login`
2. Нажмите "Try it out"
3. Введите:
   - username: `user@example.com`
   - password: `password123`
4. Нажмите "Execute"
5. Скопируйте `access_token` из ответа

### 3. Авторизуйтесь в Swagger

1. Нажмите кнопку "Authorize" в правом верхнем углу
2. Введите: `Bearer YOUR_ACCESS_TOKEN`
3. Нажмите "Authorize"

### 4. Создайте счет

1. Найдите endpoint `POST /api/accounts`
2. Нажмите "Try it out"
3. Введите:
```json
{
  "name": "Основной счет",
  "type": "debit_card",
  "balance": 10000.00,
  "currency": "RUB"
}
```
4. Нажмите "Execute"

### 5. Создайте категорию

1. Найдите endpoint `POST /api/categories`
2. Нажмите "Try it out"
3. Введите:
```json
{
  "name": "Продукты",
  "type": "expense",
  "icon": "🛒",
  "color": "#F44336"
}
```
4. Нажмите "Execute"

### 6. Создайте транзакцию

1. Найдите endpoint `POST /api/transactions`
2. Нажмите "Try it out"
3. Введите (используйте ID счета и категории из предыдущих шагов):
```json
{
  "account_id": 1,
  "category_id": 1,
  "amount": 500.00,
  "type": "expense",
  "date": "2024-01-15",
  "description": "Покупка продуктов"
}
```
4. Нажмите "Execute"

## Загрузка тестовых данных

Если хотите загрузить тестовые данные (10 пользователей, 5000+ транзакций):

```powershell
# Для новых версий Docker:
docker compose exec db psql -U finflow_user -d finflow_db -f /docker-entrypoint-initdb.d/05_seed_data.sql

# Для старых версий:
docker-compose exec db psql -U finflow_user -d finflow_db -f /docker-entrypoint-initdb.d/05_seed_data.sql
```

## Полезные команды

### Просмотр логов

```powershell
# Все сервисы (для новых версий Docker)
docker compose logs -f

# Только база данных
docker compose logs -f db

# Только backend
docker compose logs -f backend
```

### Остановка

```powershell
# Для новых версий:
docker compose down

# Для старых версий:
docker-compose down
```

### Перезапуск

```powershell
docker compose restart
```

### Подключение к базе данных

```powershell
docker compose exec db psql -U finflow_user -d finflow_db
```

## Дополнительная информация

- Полная документация: `README.md`
- Инструкция по развёртыванию: `DEPLOYMENT.md`
- API документация: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc


