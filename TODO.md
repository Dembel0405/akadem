# TODO — Информационная система управления учебным процессом колледжа

## ФАЗА 1: ПОДГОТОВКА И АРХИТЕКТУРА ✅
- [x] 1.1 Создать структуру монорепозитория: /backend, /frontend, /docs
- [x] 1.2 Создать README.md с описанием проекта, стека, инструкциями запуска
- [x] 1.3 Создать ARCHITECTURE.md с описанием архитектуры и диаграммами
- [x] 1.4 Настроить .gitignore, .editorconfig, prettier, eslint

## ФАЗА 2: BACKEND — ОСНОВА ✅
- [x] 2.1 Инициализировать Node.js + TypeScript проект (npm init, tsconfig.json)
- [x] 2.2 Установить зависимости (express, prisma, jwt, bcrypt, zod, cors, helmet)
- [x] 2.3 Настроить Prisma + создать schema.prisma со всеми моделями БД
- [x] 2.4 Создать миграции БД и seed-данные (тестовые пользователи всех ролей)
- [x] 2.5 Настроить структуру: /src/controllers, /services, /routes, /middleware, /utils
- [x] 2.6 Реализовать middleware: auth (JWT), errorHandler, validation, logger
- [x] 2.7 Настроить Swagger для документации API
- [x] 2.8 Создать docker-compose.yml для PostgreSQL

## ФАЗА 3: BACKEND — МОДУЛИ API ✅
- [x] 3.1 Модуль Auth: register, login, refresh, logout, forgot-password
- [x] 3.2 Модуль Users: CRUD, смена пароля, загрузка аватара
- [x] 3.3 Модуль Groups: CRUD групп, привязка студентов
- [x] 3.4 Модуль Specialties: CRUD специальностей
- [x] 3.5 Модуль Subjects: CRUD дисциплин, учебные планы
- [x] 3.6 Модуль Schedule: CRUD расписания, генерация по шаблону
- [x] 3.7 Модуль Attendance: отметка, статистика по студенту/группе
- [x] 3.8 Модуль Grades: выставление, журнал, средний балл
- [x] 3.9 Модуль Announcements: CRUD, фильтрация по ролям
- [x] 3.10 Модуль Dashboard: агрегированная статистика
- [x] 3.11 Модуль Reports: генерация PDF/Excel отчётов
- [x] 3.12 Написать unit-тесты для критичных сервисов (Jest)

## ФАЗА 4: FLUTTER — ОСНОВА ✅
- [x] 4.1 Создать Flutter-проект `flutter create`, настроить pubspec.yaml
- [x] 4.2 Создать структуру папок (Clean Architecture)
- [x] 4.3 Настроить тему приложения (lib/core/theme/) с цветовой палитрой
- [x] 4.4 Создать общие виджеты: AppButton, AppTextField, AppCard, EmptyState, LoadingIndicator, ErrorView
- [x] 4.5 Настроить go_router с защищёнными маршрутами по ролям
- [x] 4.6 Настроить Dio с интерсепторами (JWT, обработка ошибок, refresh token)
- [x] 4.7 Настроить локальное хранилище (Hive для токенов и кэша)
- [x] 4.8 Реализовать локализацию (ru, kk, en)

## ФАЗА 5: FLUTTER — ЭКРАНЫ АВТОРИЗАЦИИ ✅
- [x] 5.1 Splash screen с проверкой токена
- [x] 5.2 Экран входа (минималистичный, центрированная карточка)
- [x] 5.3 Экран восстановления пароля
- [x] 5.4 AuthBloc с состояниями (initial, loading, authenticated, error)

## ФАЗА 6: FLUTTER — ОБЩИЕ ЭКРАНЫ ✅
- [x] 6.1 Главный Layout с адаптивным sidebar (desktop) / bottom nav (mobile)
- [x] 6.2 Дашборд (разный для каждой роли) с виджетами статистики и графиками
- [x] 6.3 Профиль пользователя (просмотр и редактирование)
- [x] 6.4 Экран настроек (тема, язык, уведомления)
- [x] 6.5 Экран объявлений (список + детальный просмотр)
- [ ] 6.6 Экран уведомлений (push, опционально — Firebase FCM)

## ФАЗА 7: FLUTTER — РОЛЬ "СТУДЕНТ" ✅
- [x] 7.1 Расписание (недельный вид с переключением недель)
- [x] 7.2 Моя посещаемость (с графиками и фильтрами)
- [x] 7.3 Мои оценки (журнал по дисциплинам, средний балл)
- [x] 7.4 Информация о группе и кураторе

## ФАЗА 8: FLUTTER — РОЛЬ "ПРЕПОДАВАТЕЛЬ" ✅
- [x] 8.1 Моё расписание (общий SchedulePage, role-aware)
- [x] 8.2 Мои группы и дисциплины (TeacherGroupsPage)
- [x] 8.3 Отметка посещаемости (MarkAttendancePage)
- [x] 8.4 Выставление оценок (GradeJournalPage)
- [x] 8.5 Статистика по группам (GroupStatsPage)

## ФАЗА 9: FLUTTER — РОЛЬ "АДМИНИСТРАТОР" ✅
- [x] 9.1 Управление пользователями (UsersPage)
- [x] 9.2 Управление группами и специальностями (AdminGroupsPage)
- [x] 9.3 Управление дисциплинами (AdminSubjectsPage)
- [x] 9.4 Конструктор расписания (AdminSchedulePage)
- [x] 9.5 Управление объявлениями (AdminAnnouncementsPage)
- [x] 9.6 Генерация отчётов (AdminReportsPage)
- [x] 9.7 Системная аналитика (AdminAnalyticsPage)

## ФАЗА 10: FLUTTER — РОЛЬ "КУРАТОР" ✅
- [x] 10.1 Дашборд группы (CuratorDashboardPage)
- [x] 10.2 Посещаемость группы (CuratorAttendancePage)
- [x] 10.3 Успеваемость группы (CuratorGradesPage)
- [x] 10.4 Список студентов с детализацией (CuratorStudentsPage)

## ФАЗА 11: ИНТЕГРАЦИИ И ДОПОЛНИТЕЛЬНО ✅
- [ ] 11.1 Push-уведомления (Firebase Cloud Messaging) — опционально
- [x] 11.2 Офлайн-режим (кэширование расписания — CacheService + Hive)
- [x] 11.3 Тёмная тема (AppTheme.dark + ThemeNotifier + переключатель в настройках)
- [x] 11.4 Адаптивность (MainShell: sidebar ≥768px / bottom nav mobile, max 5 items)

## ФАЗА 12: ТЕСТИРОВАНИЕ ✅
- [x] 12.1 Unit-тесты AuthBloc (auth_bloc_test.dart — 6 тестов)
- [x] 12.2 Widget-тесты AppButton (app_button_test.dart — 5 тестов, все проходят)
- [x] 12.3 Widget-тесты LoginPage (login_page_test.dart)
- [x] 12.4 Backend unit-тесты AuthService (tests/unit/auth.service.test.ts)
- [ ] 12.5 Integration-тесты (опционально)

## ФАЗА 13: ДОКУМЕНТАЦИЯ И ДЕПЛОЙ ✅
- [x] 13.1 Swagger API (настроен, доступен на /api/docs)
- [x] 13.2 USER_GUIDE.md для всех ролей (docs/USER_GUIDE.md)
- [x] 13.3 DEPLOYMENT.md с Docker-инструкциями (docs/DEPLOYMENT.md)
- [x] 13.4 Dockerfile для backend (backend/Dockerfile)
- [x] 13.5 Сборка Flutter: flutter build apk/web (инструкции в DEPLOYMENT.md)
- [ ] 13.6 Скриншоты экранов (требует запуска на устройстве/эмуляторе)
