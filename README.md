# Информационная система управления учебным процессом колледжа

Дипломный проект — полнофункциональное веб/мобильное приложение для автоматизации учебного процесса колледжа. Система охватывает управление расписанием, посещаемостью, успеваемостью, пользователями и аналитику.

## Технологический стек

### Backend
| Технология | Версия | Назначение |
|---|---|---|
| Node.js | 20.x LTS | Runtime |
| TypeScript | 5.x | Типизация |
| Express | 4.x | HTTP-фреймворк |
| PostgreSQL | 16.x | База данных |
| Prisma | 5.x | ORM |
| JWT | — | Авторизация (access + refresh) |
| bcrypt | — | Хеширование паролей |
| Zod | 3.x | Валидация данных |
| Swagger / OpenAPI | 3.0 | Документация API |
| Multer | — | Загрузка файлов |
| Jest | — | Unit-тесты |

### Frontend
| Технология | Версия | Назначение |
|---|---|---|
| Flutter | 3.x | UI-фреймворк |
| Dart | 3.x | Язык программирования |
| flutter_bloc | — | Управление состоянием |
| go_router | — | Навигация |
| dio + retrofit | — | HTTP-клиент |
| hive | — | Локальное хранилище |
| fl_chart | — | Графики |
| reactive_forms | — | Формы |
| google_fonts | — | Шрифт Inter |

## Роли пользователей

- **Администратор** — полный доступ: управление пользователями, расписанием, отчётами
- **Преподаватель** — управление занятиями, выставление оценок, отметка посещаемости
- **Студент** — просмотр расписания, оценок, посещаемости, объявлений
- **Куратор** — управление закреплённой группой, статистика успеваемости

## Модули системы

1. Авторизация и управление сессиями
2. Управление пользователями
3. Группы и специальности
4. Дисциплины и учебные планы
5. Расписание занятий
6. Учёт посещаемости
7. Электронный журнал оценок
8. Объявления и новости
9. Дашборд с аналитикой
10. Push-уведомления
11. Генерация отчётов (PDF/Excel)

## Структура репозитория

```
/
├── backend/          # Node.js + Express API
│   ├── src/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── routes/
│   │   ├── middleware/
│   │   ├── utils/
│   │   └── types/
│   ├── prisma/
│   │   ├── schema.prisma
│   │   ├── migrations/
│   │   └── seed.ts
│   └── ...
├── frontend/         # Flutter приложение
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── schedule/
│   │   │   ├── attendance/
│   │   │   ├── grades/
│   │   │   └── ...
│   │   └── main.dart
│   └── ...
├── docs/             # Документация
│   ├── api/
│   └── diagrams/
├── README.md
├── ARCHITECTURE.md
└── TODO.md
```

## Быстрый старт

### Требования

- Node.js 20+ LTS
- PostgreSQL 16+
- Flutter 3.x + Dart 3.x
- Docker & Docker Compose (опционально)

### 1. Запуск PostgreSQL через Docker

```bash
cd backend
docker-compose up -d
```

### 2. Настройка и запуск Backend

```bash
cd backend
cp .env.example .env
# Отредактируйте .env: DATABASE_URL, JWT_SECRET и т.д.

npm install
npx prisma migrate dev
npx prisma db seed

npm run dev
# API доступен на http://localhost:3000
# Swagger UI: http://localhost:3000/api/docs
```

### 3. Запуск Flutter приложения

```bash
cd frontend
flutter pub get
# Отредактируйте lib/core/constants/api_constants.dart (BASE_URL)

flutter run
# или для web: flutter run -d chrome
```

## Тестовые аккаунты (после seed)

| Роль | Email | Пароль |
|---|---|---|
| Администратор | admin@college.kz | Admin123! |
| Преподаватель | teacher@college.kz | Teacher123! |
| Студент | student@college.kz | Student123! |
| Куратор | curator@college.kz | Curator123! |

## Переменные окружения (backend/.env.example)

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/college_db"
JWT_SECRET="your-super-secret-jwt-key"
JWT_REFRESH_SECRET="your-super-secret-refresh-key"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
PORT=3000
NODE_ENV=development
UPLOAD_DIR="./uploads"
```

## Дизайн-система

Приложение использует минималистичный дизайн, вдохновлённый Notion и Linear:
- Основной цвет: `#2563EB` (синий)
- Фон: `#FFFFFF` / `#F8FAFC`
- Шрифт: Inter
- Скругления: 8–16px
- Без градиентов и декоративных элементов

Подробнее — в [ARCHITECTURE.md](./ARCHITECTURE.md).
