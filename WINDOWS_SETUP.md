# Установка и запуск FinFlow на Windows

## Шаг 1: Установка Docker Desktop

### Проверка установки Docker

Откройте PowerShell и выполните:

```powershell
docker --version
```

Если команда не работает, нужно установить Docker Desktop.

### Установка Docker Desktop для Windows

1. **Скачайте Docker Desktop:**
   - Перейдите на https://www.docker.com/products/docker-desktop/
   - Нажмите "Download for Windows"
   - Скачайте установщик `Docker Desktop Installer.exe`

2. **Установите Docker Desktop:**
   - Запустите установщик
   - Следуйте инструкциям мастера установки
   - Убедитесь, что включена опция "Use WSL 2 instead of Hyper-V" (если доступна)
   - Перезапустите компьютер, если требуется

3. **Запустите Docker Desktop:**
   - Найдите Docker Desktop в меню "Пуск"
   - Запустите приложение
   - Дождитесь, пока Docker Desktop полностью запустится (иконка в трее должна быть зеленой)

4. **Проверьте установку:**
   ```powershell
   docker --version
   docker compose version
   ```

   Ожидаемый результат:
   ```
   Docker version 24.x.x
   Docker Compose version v2.x.x
   ```

## Шаг 2: Настройка проекта

### Перейдите в директорию проекта

```powershell
cd c:\Projects\DB_Labs\cp
```

### Проверьте наличие файлов

```powershell
dir
```

Должны быть видны:
- `docker-compose.yml`
- `database/` (папка)
- `backend/` (папка)

## Шаг 3: Запуск проекта

### Важно: Команды для разных версий Docker

**В новых версиях Docker (Docker Desktop 4.x+) используется команда `docker compose` (с пробелом)**

**В старых версиях используется `docker-compose` (с дефисом)**

### Попробуйте сначала новую команду:

```powershell
docker compose up -d
```

Если появится ошибка "docker compose is not recognized", попробуйте старую команду:

```powershell
docker-compose up -d
```

### Что происходит при запуске

Команда `docker compose up -d`:
1. Скачивает образы PostgreSQL и Python (если их нет)
2. Создает и запускает контейнер с базой данных
3. Создает и запускает контейнер с backend-приложением
4. Инициализирует базу данных (выполняет SQL-скрипты)

**Это может занять 2-5 минут при первом запуске** (скачивание образов).

### Проверка статуса

После запуска выполните:

```powershell
# Для новых версий:
docker compose ps

# Для старых версий:
docker-compose ps
```

Должны быть запущены:
- `finflow_db` - статус `Up`
- `finflow_backend` - статус `Up`

### Просмотр логов (если что-то не работает)

```powershell
# Для новых версий:
docker compose logs

# Для старых версий:
docker-compose logs
```

## Шаг 4: Проверка работы

### Откройте в браузере:

1. **Health check:**
   - http://localhost:8000/health
   - Должен вернуть: `{"status":"healthy"}`

2. **Swagger документация:**
   - http://localhost:8000/docs
   - Должна открыться интерактивная документация API

### Если порт 8000 занят

Измените порт в файле `docker-compose.yml`:

```yaml
backend:
  ports:
    - "8001:8000"  # Измените 8000 на другой порт
```

После изменения перезапустите:
```powershell
docker compose down
docker compose up -d
```

## Шаг 5: Тестирование API

Следуйте инструкциям в файле `QUICKSTART.md` или `START.md`

## Решение проблем

### Проблема: "docker compose is not recognized"

**Решение:**
1. Убедитесь, что Docker Desktop запущен
2. Попробуйте старую команду: `docker-compose up -d`
3. Если не помогло, обновите Docker Desktop до последней версии

### Проблема: "Cannot connect to the Docker daemon"

**Решение:**
1. Запустите Docker Desktop
2. Дождитесь полного запуска (иконка в трее зеленая)
3. Попробуйте снова

### Проблема: "Port 5432 is already allocated"

**Решение:**
PostgreSQL уже запущен на вашем компьютере. Варианты:
1. Остановите локальный PostgreSQL
2. Измените порт в `docker-compose.yml`:
   ```yaml
   db:
     ports:
       - "5433:5432"  # Измените внешний порт
   ```

### Проблема: "Port 8000 is already allocated"

**Решение:**
Измените порт в `docker-compose.yml` (см. выше)

### Проблема: Контейнеры запускаются, но API не работает

**Решение:**
1. Проверьте логи backend:
   ```powershell
   docker compose logs backend
   ```
2. Проверьте, что база данных готова:
   ```powershell
   docker compose logs db
   ```
3. Подождите 30-60 секунд для полной инициализации

### Проблема: Ошибки при инициализации БД

**Решение:**
1. Удалите том с данными и пересоздайте:
   ```powershell
   docker compose down -v
   docker compose up -d
   ```

### Проблема: Медленная работа Docker

**Решение:**
1. Убедитесь, что WSL 2 включен (если используется)
2. Увеличьте выделенную память в настройках Docker Desktop:
   - Откройте Docker Desktop
   - Settings → Resources → Advanced
   - Увеличьте Memory (рекомендуется минимум 4GB)

## Полезные команды

### Остановка всех контейнеров

```powershell
docker compose down
```

### Остановка с удалением данных

```powershell
docker compose down -v
```

### Перезапуск контейнеров

```powershell
docker compose restart
```

### Просмотр логов в реальном времени

```powershell
docker compose logs -f
```

### Подключение к базе данных

```powershell
docker compose exec db psql -U finflow_user -d finflow_db
```

### Выполнение команды в контейнере backend

```powershell
docker compose exec backend bash
```

## Дополнительная информация

- Полная документация: `README.md`
- Быстрый старт: `QUICKSTART.md`
- Детальная инструкция: `START.md`




