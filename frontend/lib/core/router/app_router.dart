import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/main_shell.dart';

/// Все именованные маршруты приложения
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String schedule = '/schedule';
  static const String attendance = '/attendance';
  static const String grades = '/grades';
  static const String announcements = '/announcements';
  static const String users = '/users';
  static const String profile = '/profile';
}

GoRouter createRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthStateNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (authState is AuthLoading && isOnSplash) return null;
      if (authState is AuthUnauthenticated && !isOnAuth) return AppRoutes.login;
      if (authState is AuthAuthenticated && (isOnAuth || isOnSplash)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),

      // Защищённые маршруты внутри Shell (с боковым меню / нижней навигацией)
      ShellRoute(
        builder: (_, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardPage()),
          GoRoute(path: AppRoutes.schedule, builder: (_, __) => const SchedulePage()),
          GoRoute(path: AppRoutes.attendance, builder: (_, __) => const AttendancePage()),
          GoRoute(path: AppRoutes.grades, builder: (_, __) => const GradesPage()),
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const AnnouncementsPage()),
          GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersPage()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfilePage()),
        ],
      ),
    ],
  );
}

/// Уведомляет GoRouter об изменениях состояния авторизации
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
