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
import '../../features/grades/presentation/pages/group_info_page.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/teacher/presentation/pages/teacher_groups_page.dart';
import '../../features/teacher/presentation/pages/mark_attendance_page.dart';
import '../../features/teacher/presentation/pages/grade_journal_page.dart';
import '../../features/teacher/presentation/pages/group_stats_page.dart';
import '../../features/admin/presentation/pages/admin_groups_page.dart';
import '../../features/admin/presentation/pages/admin_subjects_page.dart';
import '../../features/admin/presentation/pages/admin_schedule_page.dart';
import '../../features/admin/presentation/pages/admin_announcements_page.dart';
import '../../features/admin/presentation/pages/admin_reports_page.dart';
import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/curator/presentation/pages/curator_dashboard_page.dart';
import '../../features/curator/presentation/pages/curator_attendance_page.dart';
import '../../features/curator/presentation/pages/curator_grades_page.dart';
import '../../features/curator/presentation/pages/curator_students_page.dart';
import '../widgets/main_shell.dart';

/// Все именованные маршруты приложения
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Общие
  static const String dashboard = '/dashboard';
  static const String schedule = '/schedule';
  static const String attendance = '/attendance';
  static const String grades = '/grades';
  static const String announcements = '/announcements';
  static const String users = '/users';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String groupInfo = '/group-info';

  // Преподаватель
  static const String teacherGroups = '/teacher/groups';
  static const String teacherAttendance = '/teacher/attendance/:groupId';
  static const String teacherGrades = '/teacher/grades/:groupId/:subjectId';
  static const String teacherStats = '/teacher/stats/:groupId';

  // Администратор
  static const String adminGroups = '/admin/groups';
  static const String adminSubjects = '/admin/subjects';
  static const String adminSchedule = '/admin/schedule';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminReports = '/admin/reports';
  static const String adminAnalytics = '/admin/analytics';

  // Куратор
  static const String curatorDashboard = '/curator';
  static const String curatorAttendance = '/curator/attendance/:groupId';
  static const String curatorGrades = '/curator/grades/:groupId';
  static const String curatorStudents = '/curator/students/:groupId';
}

GoRouter createRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthStateNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final loc = state.matchedLocation;
      final isOnSplash = loc == AppRoutes.splash;
      final isOnAuth = loc == AppRoutes.login || loc == AppRoutes.forgotPassword;

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

      // Защищённые маршруты внутри Shell
      ShellRoute(
        builder: (_, state, child) => MainShell(child: child),
        routes: [
          // Общие
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardPage()),
          GoRoute(path: AppRoutes.schedule, builder: (_, __) => const SchedulePage()),
          GoRoute(path: AppRoutes.attendance, builder: (_, __) => const AttendancePage()),
          GoRoute(path: AppRoutes.grades, builder: (_, __) => const GradesPage()),
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const AnnouncementsPage()),
          GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersPage()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfilePage()),
          GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsPage()),
          GoRoute(path: AppRoutes.groupInfo, builder: (_, __) => const GroupInfoPage()),

          // Преподаватель
          GoRoute(path: AppRoutes.teacherGroups, builder: (_, __) => const TeacherGroupsPage()),
          GoRoute(
            path: AppRoutes.teacherAttendance,
            builder: (_, state) => MarkAttendancePage(groupId: state.pathParameters['groupId']!),
          ),
          GoRoute(
            path: AppRoutes.teacherGrades,
            builder: (_, state) => GradeJournalPage(
              groupId: state.pathParameters['groupId']!,
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherStats,
            builder: (_, state) => GroupStatsPage(groupId: state.pathParameters['groupId']!),
          ),

          // Администратор
          GoRoute(path: AppRoutes.adminGroups, builder: (_, __) => const AdminGroupsPage()),
          GoRoute(path: AppRoutes.adminSubjects, builder: (_, __) => const AdminSubjectsPage()),
          GoRoute(path: AppRoutes.adminSchedule, builder: (_, __) => const AdminSchedulePage()),
          GoRoute(path: AppRoutes.adminAnnouncements, builder: (_, __) => const AdminAnnouncementsPage()),
          GoRoute(path: AppRoutes.adminReports, builder: (_, __) => const AdminReportsPage()),
          GoRoute(path: AppRoutes.adminAnalytics, builder: (_, __) => const AdminAnalyticsPage()),

          // Куратор
          GoRoute(path: AppRoutes.curatorDashboard, builder: (_, __) => const CuratorDashboardPage()),
          GoRoute(
            path: AppRoutes.curatorAttendance,
            builder: (_, state) => CuratorAttendancePage(groupId: state.pathParameters['groupId']!),
          ),
          GoRoute(
            path: AppRoutes.curatorGrades,
            builder: (_, state) => CuratorGradesPage(groupId: state.pathParameters['groupId']!),
          ),
          GoRoute(
            path: AppRoutes.curatorStudents,
            builder: (_, state) => CuratorStudentsPage(groupId: state.pathParameters['groupId']!),
          ),
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
