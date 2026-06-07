import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Простой кэш-сервис на базе Hive для офлайн-режима.
/// Кэширует расписание и оценки, используемые при отсутствии сети.
class CacheService {
  static final CacheService instance = CacheService._();
  CacheService._();

  static const _boxName = 'cache';
  static const _ttlMs = 3600000; // 1 час

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> set(String key, dynamic data) async {
    await _box.put(key, jsonEncode({
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  T? get<T>(String key, {int maxAgeMs = _ttlMs}) {
    final raw = _box.get(key) as String?;
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map;
      final ts = map['ts'] as int;
      if (DateTime.now().millisecondsSinceEpoch - ts > maxAgeMs) {
        _box.delete(key);
        return null;
      }
      return map['data'] as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}

final cacheService = CacheService.instance;
