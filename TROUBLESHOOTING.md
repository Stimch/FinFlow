# Решение проблем при запуске FinFlow

## Ошибка: "unable to get image" или "The system cannot find the file specified"

### Причина
Docker Desktop не запущен или Docker daemon недоступен.

### Решение

1. **Проверьте, запущен ли Docker Desktop:**
   - Найдите иконку Docker в системном трее (рядом с часами)
   - Если иконки нет или она серая/желтая - Docker не запущен

2. **Запустите Docker Desktop:**
   - Найдите "Docker Desktop" в меню Пуск
   - Запустите приложение
   - Дождитесь полного запуска (иконка в трее должна стать зеленой/синей)
   - Обычно это занимает 30-60 секунд

3. **Проверьте статус Docker:**
   ```powershell
   docker info
   ```
   
   Если команда работает - Docker запущен.
   Если ошибка - Docker не запущен или не установлен.

4. **После запуска Docker Desktop попробуйте снова:**
   ```powershell
   docker-compose up -d
   ```

### Альтернативное решение (если Docker Desktop не запускается)

1. **Перезапустите Docker Desktop:**
   - Закройте Docker Desktop полностью
   - Запустите заново от имени администратора (правый клик → "Запуск от имени администратора")

2. **Проверьте, что WSL 2 установлен и включен:**
   - Docker Desktop для Windows требует WSL 2
   - Установите WSL 2, если его нет:
     ```powershell
     wsl --install
     ```
   - Перезагрузите компьютер после установки

3. **Проверьте настройки Docker Desktop:**
   - Откройте Docker Desktop
   - Settings → General
   - Убедитесь, что "Use the WSL 2 based engine" включено

## Ошибка: "the attribute `version` is obsolete"

### Причина
В новых версиях Docker Compose атрибут `version` больше не требуется.

### Решение
Файл `docker-compose.yml` уже исправлен - строка `version: '3.8'` удалена.

Если вы видите это предупреждение - просто проигнорируйте его, оно не критично.

## Ошибка: "Port 5432 is already allocated"

### Причина
Порт 5432 уже используется другим приложением (возможно, локальный PostgreSQL).

### Решение

1. **Найдите, что использует порт:**
   ```powershell
   netstat -ano | findstr :5432
   ```

2. **Остановите локальный PostgreSQL** (если он запущен):
   ```powershell
   # Через службы Windows
   services.msc
   # Найдите PostgreSQL и остановите службу
   ```

3. **Или измените порт в docker-compose.yml:**
   ```yaml
   db:
     ports:
       - "5433:5432"  # Измените внешний порт на 5433
   ```
   
   Тогда для подключения используйте порт 5433.

## Ошибка: "Port 8000 is already allocated"

### Решение
Измените порт в `docker-compose.yml`:

```yaml
backend:
  ports:
    - "8001:8000"  # Измените внешний порт на 8001
```

После изменения перезапустите:
```powershell
docker-compose down
docker-compose up -d
```

Теперь API будет доступно на http://localhost:8001

## Ошибка: "Cannot connect to the Docker daemon"

### Решение

1. Запустите Docker Desktop
2. Дождитесь полного запуска
3. Попробуйте снова

## Ошибка при сборке образа backend

### Решение

1. **Проверьте, что файл Dockerfile существует:**
   ```powershell
   dir backend\Dockerfile
   ```

2. **Проверьте, что файл requirements.txt существует:**
   ```powershell
   dir backend\requirements.txt
   ```

3. **Пересоберите образы:**
   ```powershell
   docker-compose build --no-cache
   docker-compose up -d
   ```

## Ошибка: Контейнеры запускаются, но API не отвечает

### Решение

1. **Проверьте логи backend:**
   ```powershell
   docker-compose logs backend
   ```

2. **Проверьте логи базы данных:**
   ```powershell
   docker-compose logs db
   ```

3. **Проверьте статус контейнеров:**
   ```powershell
   docker-compose ps
   ```

4. **Подождите 30-60 секунд** - база данных может инициализироваться

5. **Проверьте health endpoint:**
   ```powershell
   curl http://localhost:8000/health
   ```
   
   Или откройте в браузере: http://localhost:8000/health

## Проблемы с правами доступа

### Решение

Если возникают проблемы с правами доступа:

1. **Запустите PowerShell от имени администратора:**
   - Правый клик на PowerShell → "Запуск от имени администратора"

2. **Или добавьте пользователя в группу docker-users:**
   - Панель управления → Администрирование → Управление компьютером
   - Локальные пользователи и группы → Группы → docker-users
   - Добавьте вашу учетную запись

## Полная переустановка (если ничего не помогает)

```powershell
# Остановите все контейнеры
docker-compose down -v

# Удалите все образы проекта
docker rmi cp-backend finflow_backend

# Пересоберите и запустите заново
docker-compose build --no-cache
docker-compose up -d
```

## Получение помощи

Если проблема не решена:

1. Соберите информацию о проблеме:
   ```powershell
   docker --version
   docker-compose --version
   docker info
   docker-compose ps
   docker-compose logs
   ```

2. Проверьте документацию:
   - `README.md` - общая информация
   - `WINDOWS_SETUP.md` - установка на Windows
   - `START.md` - детальная инструкция




