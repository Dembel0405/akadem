import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/theme_notifier.dart';
import 'core/cache/cache_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await tokenStorage.init();
  await ThemeNotifier.instance.init();
  await cacheService.init();

  runApp(const App());
}
