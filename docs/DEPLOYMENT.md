# Руководство по развёртыванию

## Системные требования

- Docker 24+ и Docker Compose 2.x
- Node.js 20 LTS (для локальной разработки)
- Flutter SDK 3.x (для сборки приложения)
- PostgreSQL 16 (или Docker)

---

## Быстрый старт (Docker)

### 1. Клонирование репозитория

```bash
git clone <repo-url>
cd Akadem
```

### 2. Переменные окружения

```bash
cp backend/.env.example backend/.env
```

Отредактируйте `backend/.env`:

```env
DATABASE_URL="postgresql://akadem:secret@localhost:5432/akadem_db"
JWT_SECRET="your-super-secret-jwt-key-min-32-chars"
JWT_REFRESH_SECRET="your-refresh-secret-key-min-32-chars"
PORT=3000
UPLOAD_DIR=uploads
```

### 3. Запуск базы данных

```bash
cd backend
docker-compose up -d
```

### 4. Миграции и seed-данные

```bash
npm install
npx prisma migrate deploy
npx prisma db seed
```

### 5. Запуск бэкенда

```bash
npm run dev        # режим разработки
npm run build && npm start  # production
```

---

## Развёртывание с Docker (production)

### Полный стек в Docker

Создайте `docker-compose.prod.yml` в корне:

```yaml
version: '3.9'

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: akadem
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: akadem_db
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://akadem:secret@db:5432/akadem_db
      JWT_SECRET: ${JWT_SECRET}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
      PORT: 3000
    depends_on:
      - db
    restart: unless-stopped

volumes:
  pgdata:
```

Запуск:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

---

## Сборка Flutter-приложения

### Android APK

```bash
cd frontend
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### Web

```bash
flutter build web --release
# Результат: build/web/
# Разверните на Nginx или Firebase Hosting
```

### iOS (требует macOS + Xcode)

```bash
flutter build ios --release
```

---

## Nginx-конфиг для web-версии

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/akadem/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Тестовые аккаунты

После `npx prisma db seed`:

| Роль | Email | Пароль |
|------|-------|--------|
| Администратор | admin@college.ru | Admin123! |
| Преподаватель | teacher1@college.ru | Teacher123! |
| Куратор | curator@college.ru | Curator123! |
| Студент | student1@college.ru | Student123! |

---

## Swagger API

После запуска сервера: [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

---

## Переменные окружения (полный список)

| Переменная | Описание | Пример |
|-----------|----------|--------|
| `DATABASE_URL` | Строка подключения Prisma | `postgresql://...` |
| `JWT_SECRET` | Секрет access-токена (мин. 32 символа) | `abc123...` |
| `JWT_REFRESH_SECRET` | Секрет refresh-токена | `xyz789...` |
| `PORT` | Порт HTTP-сервера | `3000` |
| `UPLOAD_DIR` | Директория загрузок аватаров | `uploads` |
| `NODE_ENV` | Окружение | `development` / `production` |
