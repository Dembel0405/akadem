import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_constants.dart';

/// Глобальный нотифайер темы. Создаётся в main.dart до runApp().
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static final ThemeNotifier instance = ThemeNotifier._();

  ThemeNotifier._() : super(ThemeMode.light);

  Future<void> init() async {
    final box = await Hive.openBox(HiveConstants.settingsBox);
    final isDark = box.get('darkMode', defaultValue: false) as bool;
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final box = Hive.box(HiveConstants.settingsBox);
    await box.put('darkMode', dark);
  }

  bool get isDark => value == ThemeMode.dark;
}
