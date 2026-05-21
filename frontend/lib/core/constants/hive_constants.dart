abstract final class HiveConstants {
  static const String authBox = 'auth_box';
  static const String cacheBox = 'cache_box';
  static const String settingsBox = 'settings_box';

  // Ключи в auth_box
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';

  // Ключи в settings_box
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String notificationsKey = 'notifications_enabled';
}
