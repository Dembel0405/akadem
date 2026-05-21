abstract final class ApiConstants {
  // Базовый URL — меняется в зависимости от среды
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  // Таймауты
  static const int connectTimeout = 10000; // мс
  static const int receiveTimeout = 30000; // мс

  // Эндпоинты Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String me = '/auth/me';

  // Эндпоинты ресурсов
  static const String users = '/users';
  static const String groups = '/groups';
  static const String specialties = '/specialties';
  static const String subjects = '/subjects';
  static const String schedule = '/schedule';
  static const String attendance = '/attendance';
  static const String grades = '/grades';
  static const String announcements = '/announcements';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
}
