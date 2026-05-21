import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/token_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive для хранения токенов и кэша
  await Hive.initFlutter();
  await tokenStorage.init();

  runApp(const App());
}
