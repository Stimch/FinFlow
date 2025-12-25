# Инструкция по загрузке проекта на GitHub

## Шаг 1: Подготовка проекта

### 1.1. Убедитесь, что .gitignore настроен правильно

Файл `.gitignore` уже создан и включает:
- Файлы с секретами (.env)
- Кэш Python (__pycache__)
- Временные файлы
- Данные Docker

### 1.2. Создайте файл .env.example (если нужен)

Для документации переменных окружения можно создать `backend/.env.example`:

```env
DATABASE_URL=postgresql://finflow_user:finflow_pass@db:5432/finflow_db
SECRET_KEY=change-this-secret-key-in-production
DEBUG=false
```

## Шаг 2: Инициализация Git репозитория

### 2.1. Проверьте, инициализирован ли Git

```powershell
cd c:\Projects\DB_Labs\cp
git status
```

Если видите ошибку "not a git repository", переходите к следующему шагу.

### 2.2. Инициализируйте Git репозиторий

```powershell
git init
```

### 2.3. Добавьте все файлы

```powershell
git add .
```

### 2.4. Создайте первый коммит

```powershell
git commit -m "Initial commit: FinFlow - Система учета личных финансов"
```

## Шаг 3: Создание репозитория на GitHub

### 3.1. Войдите в GitHub

1. Откройте https://github.com в браузере
2. Войдите в свой аккаунт (или создайте новый)

### 3.2. Создайте новый репозиторий

1. Нажмите кнопку "+" в правом верхнем углу
2. Выберите "New repository"
3. Заполните форму:
   - **Repository name**: `finflow` или `db-labs-finflow` (на ваше усмотрение)
   - **Description**: `Система учета личных финансов и бюджетирования - Курсовая работа по БД`
   - **Visibility**: 
     - **Public** - если хотите, чтобы репозиторий был публичным
     - **Private** - если хотите, чтобы репозиторий был приватным
   - **НЕ отмечайте**:
     - ❌ "Add a README file" (у нас уже есть README.md)
     - ❌ "Add .gitignore" (у нас уже есть .gitignore)
     - ❌ "Choose a license" (можно добавить позже)

4. Нажмите "Create repository"

### 3.3. Скопируйте URL репозитория

После создания репозитория GitHub покажет инструкции. Скопируйте URL, он будет выглядеть примерно так:
- `https://github.com/ваш-username/finflow.git` (HTTPS)
- `git@github.com:ваш-username/finflow.git` (SSH)

## Шаг 4: Подключение локального репозитория к GitHub

### 4.1. Добавьте remote репозиторий

```powershell
# Замените YOUR_USERNAME и REPO_NAME на свои значения
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git
```

Например:
```powershell
git remote add origin https://github.com/egora/finflow.git
```

### 4.2. Проверьте remote

```powershell
git remote -v
```

Должен показать ваш GitHub репозиторий.

### 4.3. Переименуйте ветку в main (если нужно)

```powershell
git branch -M main
```

### 4.4. Загрузите код на GitHub

```powershell
git push -u origin main
```

Вас попросят ввести логин и пароль GitHub (или токен доступа).

## Шаг 5: Аутентификация в GitHub

### Если используется HTTPS:

GitHub требует Personal Access Token вместо пароля:

1. **Создайте Personal Access Token:**
   - Откройте https://github.com/settings/tokens
   - Нажмите "Generate new token" → "Generate new token (classic)"
   - Название: `finflow-project`
   - Срок действия: выберите подходящий (например, 90 дней)
   - Права доступа: отметьте `repo` (полный доступ к репозиториям)
   - Нажмите "Generate token"
   - **СКОПИРУЙТЕ ТОКЕН** (он показывается только один раз!)

2. **При push используйте токен как пароль:**
   ```powershell
   git push -u origin main
   ```
   - Username: ваш GitHub username
   - Password: вставьте Personal Access Token

### Альтернатива: Использование GitHub Desktop

Если хотите избежать работы с токенами:

1. Скачайте GitHub Desktop: https://desktop.github.com/
2. Установите и войдите в аккаунт
3. File → Add Local Repository
4. Выберите папку `c:\Projects\DB_Labs\cp`
5. Publish repository
6. GitHub Desktop автоматически загрузит код

## Шаг 6: Проверка

1. Откройте ваш репозиторий на GitHub в браузере
2. Убедитесь, что все файлы загружены
3. Проверьте, что `.env` файлы НЕ загружены (они должны быть в .gitignore)

## Дополнительно: Улучшение репозитория

### Добавьте описание проекта

Файл `README.md` уже создан и содержит документацию.

### Добавьте теги/топики

В настройках репозитория на GitHub добавьте теги:
- `database`
- `postgresql`
- `fastapi`
- `python`
- `docker`
- `coursework`

### Добавьте лицензию (опционально)

1. Создайте файл `LICENSE` или используйте GitHub интерфейс
2. Выберите подходящую лицензию (например, MIT)

### Настройте GitHub Pages (опционально)

Если хотите опубликовать документацию:
1. Settings → Pages
2. Source: выберите ветку `main` и папку `/docs` (если создадите)

## Полезные команды Git

```powershell
# Проверка статуса
git status

# Добавление изменений
git add .

# Создание коммита
git commit -m "Описание изменений"

# Загрузка на GitHub
git push

# Получение обновлений с GitHub
git pull

# Просмотр истории коммитов
git log --oneline

# Создание новой ветки
git checkout -b feature/new-feature
```

## Структура репозитория

После загрузки на GitHub структура должна выглядеть так:

```
finflow/
├── .gitignore
├── README.md
├── DEPLOYMENT.md
├── QUICKSTART.md
├── START.md
├── WINDOWS_SETUP.md
├── FIX_DOCKER.md
├── TROUBLESHOOTING.md
├── DOCKER_ERROR_500.md
├── GITHUB_SETUP.md (этот файл)
├── docker-compose.yml
├── database/
│   ├── 01_schema.sql
│   ├── 02_functions.sql
│   ├── 03_triggers.sql
│   ├── 04_views.sql
│   ├── 05_seed_data.sql
│   ├── 06_indexes_analysis.sql
│   ├── 07_performance_queries.sql
│   └── init.sql
└── backend/
    ├── Dockerfile
    ├── requirements.txt
    ├── .env.example
    └── app/
        ├── __init__.py
        ├── main.py
        ├── config.py
        ├── database.py
        ├── models.py
        ├── schemas.py
        ├── crud.py
        ├── auth.py
        └── routers/
            └── ...
```

**Важно:** Файлы `.env` НЕ должны быть в репозитории!

## Проверка перед загрузкой

Перед `git push` убедитесь:

```powershell
# Проверьте, что .env файлы не добавлены
git status

# Если видите .env файлы в списке - не коммитьте их!
# Удалите их из staging:
git reset HEAD .env
git reset HEAD backend/.env

# Убедитесь, что .gitignore работает:
git check-ignore -v .env
```

## Готово!

После выполнения всех шагов ваш проект будет на GitHub и доступен для:
- Резервного копирования
- Совместной работы
- Показыва на защите курсовой
- Демонстрации работодателям

