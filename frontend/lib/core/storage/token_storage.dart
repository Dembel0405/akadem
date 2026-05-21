import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_constants.dart';

/// Хранилище токенов авторизации в зашифрованном Hive-боксе.
class TokenStorage {
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(HiveConstants.authBox);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(HiveConstants.accessTokenKey, accessToken);
    await _box.put(HiveConstants.refreshTokenKey, refreshToken);
  }

  String? getAccessToken() => _box.get(HiveConstants.accessTokenKey) as String?;
  String? getRefreshToken() => _box.get(HiveConstants.refreshTokenKey) as String?;

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _box.put(HiveConstants.userKey, user);
  }

  Map<dynamic, dynamic>? getUser() => _box.get(HiveConstants.userKey) as Map<dynamic, dynamic>?;

  Future<void> clear() async {
    await _box.clear();
  }

  bool get hasTokens => getAccessToken() != null && getRefreshToken() != null;
}

// Синглтон-инстанс
final tokenStorage = TokenStorage();
