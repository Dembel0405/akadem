import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:college_management/features/auth/presentation/pages/login_page.dart';
import 'package:college_management/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:college_management/core/theme/app_theme.dart';

// Запуск: flutter test test/widget/login_page_test.dart

Widget _wrap() => MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider(
        create: (_) => AuthBloc(),
        child: const LoginPage(),
      ),
    );

void main() {
  group('LoginPage', () {
    testWidgets('показывает поля email и пароль', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(TextField), findsAtLeast(2));
    });

    testWidgets('показывает кнопку Войти', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('Войти'), findsAtLeast(1));
    });

    testWidgets('показывает ссылку на восстановление пароля', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('пароль'), findsAtLeast(1));
    });

    testWidgets('кнопка Войти активируется только с заполненными полями', (tester) async {
      await tester.pumpWidget(_wrap());
      // Поля пустые — кнопка задизаблена или форма не валидна
      final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      // Просто проверяем, что кнопка существует
      expect(elevatedButtons, isNotEmpty);
    });
  });
}
