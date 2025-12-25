# Решение проблемы с Docker на Windows

## Проблема
```
unable to get image 'cp-backend': error during connect: 
in the default daemon configuration on Windows, the docker client must be run with elevated privileges to connect: 
Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.51/images/cp-backend/json": 
open //./pipe/docker_engine: The system cannot find the file specified.
```

## Решение по шагам

### Шаг 1: Проверьте, запущен ли Docker Desktop

1. **Проверьте системный трей** (справа внизу, рядом с часами):
   - Найдите иконку Docker (кит)
   - Если иконки НЕТ - Docker Desktop не запущен
   - Если иконка СЕРАЯ или с красным крестом - Docker не работает

2. **Если Docker Desktop не запущен:**
   - Откройте меню Пуск
   - Найдите "Docker Desktop"
   - Запустите приложение
   - Дождитесь полного запуска (1-2 минуты)
   - Иконка в трее должна стать зеленой/синей

### Шаг 2: Запустите PowerShell от имени администратора

Ошибка указывает на необходимость прав администратора:

1. **Закройте текущее окно PowerShell**

2. **Откройте PowerShell от имени администратора:**
   - Нажмите Win + X
   - Выберите "Windows PowerShell (Администратор)" или "Терминал (Администратор)"
   - Или найдите PowerShell в меню Пуск → Правый клик → "Запуск от имени администратора"

3. **Перейдите в директорию проекта:**
   ```powershell
   cd c:\Projects\DB_Labs\cp
   ```

4. **Попробуйте снова:**
   ```powershell
   docker-compose up -d
   ```

### Шаг 3: Если Docker Desktop не установлен

Если вы не можете найти Docker Desktop в меню Пуск:

1. **Скачайте Docker Desktop:**
   - Перейдите на: https://www.docker.com/products/docker-desktop/
   - Нажмите "Download for Windows"
   - Сохраните файл `Docker Desktop Installer.exe`

2. **Установите Docker Desktop:**
   - Запустите установщик от имени администратора
   - Следуйте инструкциям мастера установки
   - Убедитесь, что отмечена опция "Use WSL 2 instead of Hyper-V" (если доступна)
   - Перезапустите компьютер, если требуется

3. **После установки:**
   - Запустите Docker Desktop
   - Дождитесь полного запуска
   - Попробуйте команду снова (в PowerShell от имени администратора)

### Шаг 4: Проверка работы Docker

После запуска Docker Desktop выполните в PowerShell (от администратора):

```powershell
# Проверка версии Docker
docker --version

# Проверка информации о Docker
docker info

# Проверка запущенных контейнеров
docker ps

# Проверка версии Docker Compose
docker-compose --version
```

Все команды должны выполниться БЕЗ ошибок.

### Шаг 5: Запуск проекта

Если все проверки пройдены успешно:

```powershell
cd c:\Projects\DB_Labs\cp
docker-compose up -d
```

Команда должна выполниться без ошибок и начать скачивать/собирать образы.

## Альтернативное решение: Использование WSL 2

Если проблемы продолжаются, можно использовать WSL 2 напрямую:

1. **Установите WSL 2:**
   ```powershell
   wsl --install
   ```
   
   Перезагрузите компьютер после установки.

2. **Запустите Docker Desktop и в настройках:**
   - Settings → General
   - Включите "Use the WSL 2 based engine"

3. **Используйте WSL терминал:**
   - Откройте Ubuntu (или другую установленную Linux-систему) из меню Пуск
   - Установите Docker в WSL (если нужно)
   - Или используйте PowerShell, но убедитесь, что Docker Desktop запущен

## Быстрая диагностика

Выполните эти команды в PowerShell от имени администратора и пришлите результаты:

```powershell
# 1. Проверка Docker
docker --version

# 2. Проверка Docker Compose
docker-compose --version

# 3. Проверка статуса Docker daemon
docker info

# 4. Проверка запущенных контейнеров
docker ps
```

Если какая-то команда не работает - это укажет на проблему.

## Частые причины проблем

1. **Docker Desktop не запущен** - самая частая причина
2. **Нет прав администратора** - нужно запускать PowerShell от администратора
3. **Docker Desktop не установлен** - нужно установить
4. **WSL 2 не настроен** - требуется для Windows

## Если ничего не помогает

1. Перезагрузите компьютер
2. Запустите Docker Desktop от имени администратора
3. Откройте PowerShell от имени администратора
4. Попробуйте команду снова



