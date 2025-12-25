# Решение ошибки 500 Internal Server Error в Docker

## Проблема
```
request returned 500 Internal Server Error for API route and version 
http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/...
```

## Причина
Docker Desktop запущен, но daemon не полностью инициализирован или имеет проблемы.

## Решения (по порядку)

### Решение 1: Перезапуск Docker Desktop

1. **Закройте Docker Desktop полностью:**
   - Правый клик на иконке Docker в трее
   - Выберите "Quit Docker Desktop"
   - Дождитесь полного закрытия

2. **Запустите Docker Desktop заново:**
   - Откройте Docker Desktop из меню Пуск
   - Дождитесь ПОЛНОГО запуска (1-2 минуты)
   - Иконка в трее должна стать зеленой/синей

3. **Проверьте, что Docker работает:**
   ```powershell
   docker ps
   ```
   
   Если команда выполняется без ошибок - Docker работает.

4. **Попробуйте снова:**
   ```powershell
   cd c:\Projects\DB_Labs\cp
   docker-compose up -d
   ```

### Решение 2: Перезапуск компьютера

Если перезапуск Docker Desktop не помог:

1. Сохраните все открытые файлы
2. Перезагрузите компьютер
3. После загрузки запустите Docker Desktop
4. Дождитесь полного запуска
5. Попробуйте команду снова

### Решение 3: Проверка WSL 2

Docker Desktop для Windows требует WSL 2:

1. **Проверьте версию WSL:**
   ```powershell
   wsl --status
   ```

2. **Если WSL 2 не установлен или не используется:**
   ```powershell
   wsl --install
   ```
   
   После установки перезагрузите компьютер.

3. **В Docker Desktop настройках:**
   - Откройте Docker Desktop
   - Settings → General
   - Убедитесь, что "Use the WSL 2 based engine" ВКЛЮЧЕНО
   - Нажмите "Apply & Restart"

### Решение 4: Очистка Docker

Если проблемы продолжаются:

1. **Остановите Docker Desktop**

2. **Очистите данные Docker:**
   - Откройте Docker Desktop
   - Settings → Troubleshoot
   - Нажмите "Clean / Purge data"
   - Подтвердите очистку

3. **Перезапустите Docker Desktop**

### Решение 5: Проверка ресурсов

Убедитесь, что Docker Desktop имеет достаточно ресурсов:

1. Откройте Docker Desktop
2. Settings → Resources
3. Убедитесь, что выделено:
   - Минимум 4 GB памяти (Memory)
   - Минимум 2 CPU
4. Нажмите "Apply & Restart"

### Решение 6: Использование Docker без WSL 2 (временное)

Если WSL 2 создает проблемы:

1. Откройте Docker Desktop
2. Settings → General
3. ВРЕМЕННО отключите "Use the WSL 2 based engine"
4. Нажмите "Apply & Restart"
5. Попробуйте команду снова

**Важно:** Этот режим менее производительный, используйте только для тестирования.

## Диагностика

Выполните эти команды для диагностики:

```powershell
# 1. Проверка версии Docker
docker --version

# 2. Проверка статуса Docker daemon
docker info

# 3. Проверка запущенных контейнеров
docker ps

# 4. Проверка версии Docker Compose
docker-compose --version

# 5. Проверка WSL
wsl --status
```

Если какая-то команда не работает - это укажет на проблему.

## Альтернативное решение: Запуск без Docker

Если Docker продолжает создавать проблемы, можно запустить проект без Docker:

### 1. Установите PostgreSQL локально

Скачайте и установите PostgreSQL 15 с официального сайта:
https://www.postgresql.org/download/windows/

### 2. Создайте базу данных

```powershell
# Подключитесь к PostgreSQL
psql -U postgres

# В psql выполните:
CREATE DATABASE finflow_db;
CREATE USER finflow_user WITH PASSWORD 'finflow_pass';
GRANT ALL PRIVILEGES ON DATABASE finflow_db TO finflow_user;
\q
```

### 3. Установите Python зависимости

```powershell
cd c:\Projects\DB_Labs\cp\backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 4. Настройте переменные окружения

Создайте файл `backend/.env`:
```
DATABASE_URL=postgresql://finflow_user:finflow_pass@localhost:5432/finflow_db
SECRET_KEY=your-secret-key
DEBUG=true
```

### 5. Инициализируйте базу данных

```powershell
# Выполните SQL скрипты вручную через psql
psql -U finflow_user -d finflow_db -f ..\database\01_schema.sql
psql -U finflow_user -d finflow_db -f ..\database\02_functions.sql
psql -U finflow_user -d finflow_db -f ..\database\03_triggers.sql
psql -U finflow_user -d finflow_db -f ..\database\04_views.sql
psql -U finflow_user -d finflow_db -f ..\database\06_indexes_analysis.sql
```

### 6. Запустите приложение

```powershell
cd c:\Projects\DB_Labs\cp\backend
venv\Scripts\activate
uvicorn app.main:app --reload
```

Теперь API будет доступно на http://localhost:8000

## Рекомендация

Начните с **Решение 1** (перезапуск Docker Desktop). Это решает большинство проблем с ошибкой 500.

Если это не поможет, попробуйте **Решение 2** (перезагрузка компьютера).

Если проблемы продолжаются - используйте альтернативный способ запуска без Docker.


