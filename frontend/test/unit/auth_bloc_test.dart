import 'package:flutter_test/flutter_test.dart';
import 'package:college_management/features/auth/presentation/bloc/auth_bloc.dart';

// Запуск: flutter test test/unit/auth_bloc_test.dart
// Примечание: тесты, требующие Hive или сети, вынесены в integration-тесты.

void main() {
  group('AuthState equality (Equatable)', () {
    test('AuthInitial equals AuthInitial', () {
      expect(AuthInitial(), equals(AuthInitial()));
    });

    test('AuthLoading equals AuthLoading', () {
      expect(AuthLoading(), equals(AuthLoading()));
    });

    test('AuthUnauthenticated equals AuthUnauthenticated', () {
      expect(AuthUnauthenticated(), equals(AuthUnauthenticated()));
    });

    test('AuthError equals AuthError с одинаковым сообщением', () {
      final s1 = AuthError('Неверный логин или пароль');
      final s2 = AuthError('Неверный логин или пароль');
      expect(s1, equals(s2));
    });

    test('AuthError не равен AuthError с разным сообщением', () {
      final s1 = AuthError('Ошибка 1');
      final s2 = AuthError('Ошибка 2');
      expect(s1, isNot(equals(s2)));
    });

    test('AuthLoading не равен AuthUnauthenticated', () {
      expect(AuthLoading(), isNot(equals(AuthUnauthenticated())));
    });
  });

  group('AuthEvent equality', () {
    test('AuthCheckRequested equals AuthCheckRequested', () {
      expect(AuthCheckRequested(), equals(AuthCheckRequested()));
    });

    test('AuthLoginRequested equality', () {
      final e1 = AuthLoginRequested(email: 'a@b.com', password: '123');
      final e2 = AuthLoginRequested(email: 'a@b.com', password: '123');
      final e3 = AuthLoginRequested(email: 'x@y.com', password: '456');
      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
    });

    test('AuthLogoutRequested equals AuthLogoutRequested', () {
      expect(AuthLogoutRequested(), equals(AuthLogoutRequested()));
    });
  });

  group('AuthBloc', () {
    test('начальное состояние — AuthInitial', () {
      final bloc = AuthBloc();
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });
  });
}
