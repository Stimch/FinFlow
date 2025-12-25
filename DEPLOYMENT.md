# Инструкция по развёртыванию FinFlow

## Требования

- Docker версии 20.10 или выше
- Docker Compose версии 1.29 или выше
- Минимум 2 GB свободной оперативной памяти
- Минимум 5 GB свободного места на диске

## Быстрое развёртывание

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd cp
```

### 2. Запуск с помощью Docker Compose

```bash
docker-compose up -d
```

Эта команда:
- Создаст и запустит контейнер PostgreSQL
- Создаст и запустит контейнер backend-приложения
- Автоматически инициализирует базу данных (выполнит скрипты из `database/`)

### 3. Загрузка тестовых данных (опционально)

```bash
docker-compose exec db psql -U finflow_user -d finflow_db -f /docker-entrypoint-initdb.d/05_seed_data.sql
```

### 4. Проверка работы

Откройте в браузере:
- API документация: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Ручное развёртывание (без Docker)

### 1. Установка PostgreSQL

Установите PostgreSQL 15 или выше на вашу систему.

### 2. Создание базы данных

```bash
createdb -U postgres finflow_db
createuser -U postgres finflow_user
psql -U postgres -c "ALTER USER finflow_user WITH PASSWORD 'finflow_pass';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE finflow_db TO finflow_user;"
```

### 3. Инициализация схемы базы данных

```bash
cd database
psql -U finflow_user -d finflow_db -f 01_schema.sql
psql -U finflow_user -d finflow_db -f 02_functions.sql
psql -U finflow_user -d finflow_db -f 03_triggers.sql
psql -U finflow_user -d finflow_db -f 04_views.sql
psql -U finflow_user -d finflow_db -f 06_indexes_analysis.sql
```

### 4. Загрузка тестовых данных (опционально)

```bash
psql -U finflow_user -d finflow_db -f 05_seed_data.sql
```

### 5. Установка зависимостей Python

```bash
cd backend
python -m venv venv
source venv/bin/activate  # На Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 6. Настройка переменных окружения

Создайте файл `backend/.env`:

```env
DATABASE_URL=postgresql://finflow_user:finflow_pass@localhost:5432/finflow_db
SECRET_KEY=your-secret-key-change-in-production
DEBUG=false
```

### 7. Запуск приложения

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Проверка работоспособности

### 1. Проверка базы данных

```bash
docker-compose exec db psql -U finflow_user -d finflow_db -c "SELECT COUNT(*) FROM users;"
```

Должно вернуть количество пользователей (10 при использовании тестовых данных).

### 2. Проверка API

```bash
curl http://localhost:8000/health
```

Должен вернуть: `{"status":"healthy"}`

### 3. Регистрация пользователя

```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "full_name": "Test User",
    "currency": "RUB"
  }'
```

### 4. Вход в систему

```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=testpassword123"
```

Сохраните полученный `access_token` для последующих запросов.

### 5. Получение списка счетов

```bash
curl -X GET "http://localhost:8000/api/accounts" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Остановка и очистка

### Остановка контейнеров

```bash
docker-compose down
```

### Остановка с удалением данных

```bash
docker-compose down -v
```

**Внимание**: Это удалит все данные из базы данных!

## Устранение неполадок

### Проблема: Контейнер базы данных не запускается

**Решение**: Проверьте, не занят ли порт 5432:
```bash
# Linux/Mac
lsof -i :5432

# Windows
netstat -ano | findstr :5432
```

### Проблема: Backend не может подключиться к базе данных

**Решение**: 
1. Убедитесь, что контейнер базы данных запущен: `docker-compose ps`
2. Проверьте логи: `docker-compose logs db`
3. Проверьте переменные окружения в `docker-compose.yml`

### Проблема: Ошибки при выполнении SQL-скриптов

**Решение**: 
1. Проверьте логи базы данных: `docker-compose logs db`
2. Убедитесь, что скрипты выполняются в правильном порядке
3. Проверьте права доступа пользователя базы данных

### Проблема: Медленная работа запросов

**Решение**:
1. Проверьте наличие индексов: `docker-compose exec db psql -U finflow_user -d finflow_db -c "\di"`
2. Выполните `ANALYZE` для обновления статистики: `docker-compose exec db psql -U finflow_user -d finflow_db -c "ANALYZE;"`

## Резервное копирование и восстановление

### Создание резервной копии

```bash
docker-compose exec db pg_dump -U finflow_user finflow_db > backup.sql
```

### Восстановление из резервной копии

```bash
docker-compose exec -T db psql -U finflow_user finflow_db < backup.sql
```

## Производственное развёртывание

Для производственного развёртывания рекомендуется:

1. **Изменить пароли и секретные ключи**:
   - Создайте файл `.env` с безопасными значениями
   - Используйте сильные пароли для базы данных
   - Сгенерируйте безопасный SECRET_KEY

2. **Настроить HTTPS**:
   - Используйте reverse proxy (nginx, traefik)
   - Настройте SSL-сертификаты

3. **Настроить мониторинг**:
   - Логирование
   - Мониторинг производительности
   - Алерты

4. **Регулярные резервные копии**:
   - Настройте автоматическое резервное копирование
   - Храните копии в безопасном месте

5. **Ограничить доступ**:
   - Настройте firewall
   - Используйте VPN для доступа к базе данных
   - Ограничьте CORS origins

## Дополнительная информация

Для получения дополнительной информации см. основной файл `README.md`.





