import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_management/core/widgets/app_button.dart';
import 'package:college_management/core/theme/app_theme.dart';

// Запуск: flutter test test/widget/app_button_test.dart

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  group('AppButton', () {
    testWidgets('отображает label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Нажми меня', onPressed: () {}),
      ));
      expect(find.text('Нажми меня'), findsOneWidget);
    });

    testWidgets('вызывает onPressed при нажатии', (tester) async {
      var pressed = false;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'OK', onPressed: () => pressed = true),
      ));
      await tester.tap(find.text('OK'));
      expect(pressed, isTrue);
    });

    testWidgets('disabled-состояние не вызывает callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Кнопка', onPressed: null),
      ));
      await tester.tap(find.text('Кнопка'), warnIfMissed: false);
      expect(pressed, isFalse);
    });

    testWidgets('показывает индикатор загрузки', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Save', onPressed: () {}, loading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('secondary вариант рендерится без исключений', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Отмена', onPressed: () {}, variant: AppButtonVariant.secondary),
      ));
      expect(find.text('Отмена'), findsOneWidget);
    });
  });
}
