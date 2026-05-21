# Архитектура системы управления учебным процессом

## Общая архитектура

Система построена на принципах **Clean Architecture** и **Domain-Driven Design (DDD)**. Клиент-серверная модель с разделённым Flutter-клиентом и REST API на Node.js.

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client                           │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Presentation │  │    Domain    │  │       Data        │  │
│  │   (BLoC/UI) │  │ (UseCases/  │  │  (Repositories/   │  │
│  │             │◄─┤  Entities/  ├─►│   DataSources/    │  │
│  │  Screens    │  │  Interfaces)│  │   Models/API)     │  │
│  └─────────────┘  └──────────────┘  └─────────┬─────────┘  │
└──────────────────────────────────────────────────┼──────────┘
                                                   │ HTTP/REST
                                                   │ (JWT)
┌──────────────────────────────────────────────────┼──────────┐
│                    Node.js API                    │          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┴───────┐  │
│  │  Routes  │  │ Middleware│  │       Controllers        │  │
│  │ /api/v1/ ├─►│ auth/val.├─►│  (request → response)   │  │
│  └──────────┘  └──────────┘  └──────────────┬───────────┘  │
│                                              │               │
│  ┌───────────────────────────────────────────▼───────────┐  │
│  │                     Services                          │  │
│  │           (бизнес-логика, транзакции)                 │  │
│  └───────────────────────────────────────────┬───────────┘  │
│                                              │               │
│  ┌───────────────────────────────────────────▼───────────┐  │
│  │                  Prisma ORM                           │  │
│  └───────────────────────────────────────────┬───────────┘  │
└──────────────────────────────────────────────┼──────────────┘
                                               │
                                    ┌──────────▼──────────┐
                                    │    PostgreSQL 16     │
                                    └─────────────────────┘
```

---

## Архитектура Flutter (Clean Architecture)

```
lib/
├── main.dart                    # Точка входа, инициализация
├── app.dart                     # MaterialApp, Router, Theme
│
├── core/                        # Общие модули (не зависят от фич)
│   ├── constants/               # Константы приложения
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   └── hive_constants.dart
│   ├── errors/                  # Классы ошибок
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/                 # HTTP-клиент
│   │   ├── dio_client.dart
│   │   ├── api_interceptor.dart
│   │   └── network_info.dart
│   ├── router/                  # go_router конфигурация
│   │   ├── app_router.dart
│   │   └── route_guards.dart
│   ├── storage/                 # Hive, SharedPreferences
│   │   ├── hive_storage.dart
│   │   └── token_storage.dart
│   ├── theme/                   # Тема приложения
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_decorations.dart
│   ├── localization/            # Локализация
│   │   ├── app_localizations.dart
│   │   └── l10n/
│   │       ├── app_ru.arb
│   │       ├── app_kk.arb
│   │       └── app_en.arb
│   └── widgets/                 # Переиспользуемые виджеты
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── app_dialog.dart
│       ├── empty_state.dart
│       ├── loading_indicator.dart
│       └── error_view.dart
│
└── features/                    # Функциональные модули
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── auth_remote_data_source.dart
    │   │   ├── models/
    │   │   │   ├── user_model.dart
    │   │   │   └── token_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_entity.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart
    │   │   └── usecases/
    │   │       ├── login_usecase.dart
    │   │       ├── logout_usecase.dart
    │   │       └── refresh_token_usecase.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── auth_bloc.dart
    │       │   ├── auth_event.dart
    │       │   └── auth_state.dart
    │       ├── pages/
    │       │   ├── login_page.dart
    │       │   └── forgot_password_page.dart
    │       └── widgets/
    │           └── login_form.dart
    ├── dashboard/
    ├── schedule/
    ├── attendance/
    ├── grades/
    ├── users/
    ├── groups/
    ├── announcements/
    └── reports/
```

---

## Архитектура Backend

```
backend/
├── src/
│   ├── app.ts                   # Express app, middleware подключение
│   ├── server.ts                # HTTP server, порт
│   │
│   ├── config/                  # Конфигурация
│   │   ├── database.ts          # Prisma client
│   │   ├── jwt.ts               # JWT настройки
│   │   └── swagger.ts           # Swagger конфигурация
│   │
│   ├── middleware/              # Express middleware
│   │   ├── auth.middleware.ts   # JWT верификация
│   │   ├── error.middleware.ts  # Глобальный обработчик ошибок
│   │   ├── validate.middleware.ts # Zod-валидация
│   │   ├── upload.middleware.ts # Multer конфигурация
│   │   └── logger.middleware.ts # Request logging
│   │
│   ├── modules/                 # Функциональные модули
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.routes.ts
│   │   │   └── auth.schema.ts   # Zod-схемы
│   │   ├── users/
│   │   ├── groups/
│   │   ├── specialties/
│   │   ├── subjects/
│   │   ├── schedule/
│   │   ├── attendance/
│   │   ├── grades/
│   │   ├── announcements/
│   │   ├── dashboard/
│   │   └── reports/
│   │
│   ├── utils/                   # Утилиты
│   │   ├── ApiError.ts          # Кастомный класс ошибок
│   │   ├── ApiResponse.ts       # Стандартный формат ответов
│   │   ├── pagination.ts        # Логика пагинации
│   │   └── email.ts             # Email-сервис
│   │
│   └── types/                   # TypeScript типы
│       └── express.d.ts         # Расширение Request (user)
│
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
│
├── uploads/                     # Загруженные файлы
├── tests/                       # Jest тесты
├── .env.example
├── docker-compose.yml
├── package.json
└── tsconfig.json
```

---

## Схема базы данных

```
┌──────────┐     ┌──────────────┐     ┌──────────┐
│   User   │     │    Group     │     │Specialty │
├──────────┤     ├──────────────┤     ├──────────┤
│ id       │     │ id           │     │ id       │
│ email    │     │ name         ├────►│ id       │
│ password │     │ specialtyId  │     │ name     │
│ firstName│     │ curatorId    │◄────│ code     │
│ lastName │     │ year         │     └──────────┘
│ role     │◄────│ students[]   │
│ phone    │     └──────┬───────┘
│ avatar   │            │
│ isActive │     ┌──────▼────────────┐
└────┬─────┘     │  ScheduleEntry    │
     │           ├───────────────────┤
     │           │ id                │
     │           │ groupId           │
     │           │ subjectId         │
     │           │ teacherId         │
     │           │ dayOfWeek         │
     │           │ startTime         │
     │           │ endTime           │
     │           │ room              │
     │           │ weekType (all/odd/even)│
     │           └──────┬────────────┘
     │                  │
┌────▼─────┐    ┌───────▼──────┐    ┌──────────────┐
│ Subject  │    │  Attendance   │    │    Grade     │
├──────────┤    ├──────────────┤    ├──────────────┤
│ id       │    │ id           │    │ id           │
│ name     │    │ studentId    │    │ studentId    │
│ code     │    │ scheduleId   │    │ subjectId    │
│ hours    │    │ date         │    │ teacherId    │
│ credits  │    │ status       │    │ value        │
└──────────┘    │ note         │    │ type (control│
                └──────────────┘    │ /exam/current)│
                                    │ date         │
                                    │ comment      │
                                    └──────────────┘

┌──────────────────┐    ┌──────────────────┐
│  Announcement    │    │ RefreshToken     │
├──────────────────┤    ├──────────────────┤
│ id               │    │ id               │
│ title            │    │ userId           │
│ content          │    │ token            │
│ authorId         │    │ expiresAt        │
│ targetRoles[]    │    └──────────────────┘
│ isPinned         │
│ createdAt        │
└──────────────────┘
```

---

## Диаграмма потоков авторизации

```
Client                          API
  │                              │
  │──── POST /auth/login ───────►│
  │     { email, password }      │
  │                              │── verify password (bcrypt)
  │                              │── generate accessToken (15m)
  │                              │── generate refreshToken (7d)
  │                              │── save refreshToken to DB
  │◄─── { accessToken,           │
  │       refreshToken, user } ──│
  │                              │
  │ (сохранить в Hive)           │
  │                              │
  │──── GET /users ─────────────►│
  │     Authorization: Bearer    │── verify JWT signature
  │     <accessToken>            │── check expiry
  │                              │── attach user to req
  │◄─── { data: [...] } ────────│
  │                              │
  │ (accessToken истёк)          │
  │                              │
  │──── POST /auth/refresh ─────►│
  │     { refreshToken }         │── find token in DB
  │                              │── verify not expired
  │                              │── generate new accessToken
  │◄─── { accessToken } ────────│
```

---

## Принципы дизайн-системы

### Цветовая палитра

| Переменная | HEX | Назначение |
|---|---|---|
| `primaryBlue` | `#2563EB` | Кнопки, акценты, ссылки |
| `primaryDark` | `#1E40AF` | Hover, активные состояния |
| `accentBlue` | `#3B82F6` | Вторичные элементы |
| `lightBlue` | `#DBEAFE` | Фоны выделений, badges |
| `white` | `#FFFFFF` | Основной фон |
| `offWhite` | `#F8FAFC` | Фон карточек |
| `gray50` | `#F1F5F9` | Разделители |
| `gray200` | `#E2E8F0` | Borders |
| `gray500` | `#64748B` | Вторичный текст |
| `gray900` | `#0F172A` | Основной текст |
| `success` | `#10B981` | Успех, присутствие |
| `error` | `#EF4444` | Ошибки, отсутствие |
| `warning` | `#F59E0B` | Предупреждения |

### Пространство и компоненты

- **Padding**: минимум 16px внутри компонентов, 24–32px между секциями
- **Border-radius**: 8px — кнопки, 12px — карточки, 16px — модалки
- **Тени**: `box-shadow: 0 1px 3px rgba(0,0,0,0.05)` — минимальные
- **Анимации**: 200–300ms, `Curves.easeInOut`
- **Шрифт**: Inter (google_fonts)
- **Иконки**: phosphor_flutter (тонкие, outline-стиль)

---

## API Соглашения

### Формат ответов

```json
// Успех
{
  "success": true,
  "data": { ... },
  "message": "Операция выполнена успешно"
}

// Список с пагинацией
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "total": 100,
    "page": 1,
    "perPage": 20,
    "totalPages": 5
  }
}

// Ошибка
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Неверный формат email",
    "details": [ ... ]
  }
}
```

### HTTP-статусы

| Статус | Случай |
|---|---|
| 200 | Успешный GET/PUT |
| 201 | Успешный POST (создание) |
| 204 | Успешный DELETE |
| 400 | Ошибка валидации |
| 401 | Не авторизован |
| 403 | Нет прав доступа |
| 404 | Ресурс не найден |
| 409 | Конфликт (дублирование) |
| 500 | Внутренняя ошибка сервера |

### Версионирование API

Все эндпоинты доступны по пути `/api/v1/...`

---

## Технические решения и обоснования

| Решение | Обоснование |
|---|---|
| Flutter вместо React Native | Единая кодовая база, лучшая производительность, поддержка web |
| BLoC вместо Provider | Предсказуемое управление состоянием, легко тестировать |
| Prisma вместо TypeORM | Лучший DX, type-safety, migrations из коробки |
| Zod вместо Joi | TypeScript-first, вывод типов из схем |
| go_router вместо Navigator 2.0 | Декларативная маршрутизация, deep links, guards |
| PostgreSQL вместо MongoDB | Реляционные данные с множеством связей, ACID |
| Refresh token в БД | Возможность инвалидации токенов при logout |
