import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../router/app_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final List<UserRole> roles;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.roles = const [],
  });
}

const _navItems = [
  // Общие — все роли
  _NavItem(
    label: 'Главная',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    route: AppRoutes.dashboard,
  ),

  // Студент
  _NavItem(label: 'Расписание', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, route: AppRoutes.schedule, roles: [UserRole.student]),
  _NavItem(label: 'Посещаемость', icon: Icons.how_to_reg_outlined, activeIcon: Icons.how_to_reg_rounded, route: AppRoutes.attendance, roles: [UserRole.student]),
  _NavItem(label: 'Оценки', icon: Icons.grade_outlined, activeIcon: Icons.grade_rounded, route: AppRoutes.grades, roles: [UserRole.student]),
  _NavItem(label: 'Объявления', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, route: AppRoutes.announcements, roles: [UserRole.student]),
  _NavItem(label: 'Группа', icon: Icons.info_outlined, activeIcon: Icons.info_rounded, route: AppRoutes.groupInfo, roles: [UserRole.student]),

  // Преподаватель
  _NavItem(label: 'Расписание', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, route: AppRoutes.schedule, roles: [UserRole.teacher]),
  _NavItem(label: 'Мои группы', icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, route: AppRoutes.teacherGroups, roles: [UserRole.teacher]),
  _NavItem(label: 'Объявления', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, route: AppRoutes.announcements, roles: [UserRole.teacher]),

  // Администратор
  _NavItem(label: 'Пользователи', icon: Icons.people_outline, activeIcon: Icons.people_rounded, route: AppRoutes.users, roles: [UserRole.admin]),
  _NavItem(label: 'Группы', icon: Icons.group_outlined, activeIcon: Icons.group_rounded, route: AppRoutes.adminGroups, roles: [UserRole.admin]),
  _NavItem(label: 'Дисциплины', icon: Icons.book_outlined, activeIcon: Icons.book_rounded, route: AppRoutes.adminSubjects, roles: [UserRole.admin]),
  _NavItem(label: 'Расписание', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, route: AppRoutes.adminSchedule, roles: [UserRole.admin]),
  _NavItem(label: 'Объявления', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, route: AppRoutes.adminAnnouncements, roles: [UserRole.admin]),
  _NavItem(label: 'Отчёты', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, route: AppRoutes.adminReports, roles: [UserRole.admin]),
  _NavItem(label: 'Аналитика', icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, route: AppRoutes.adminAnalytics, roles: [UserRole.admin]),

  // Куратор
  _NavItem(label: 'Расписание', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, route: AppRoutes.schedule, roles: [UserRole.curator]),
  _NavItem(label: 'Моя группа', icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, route: AppRoutes.curatorDashboard, roles: [UserRole.curator]),
  _NavItem(label: 'Объявления', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, route: AppRoutes.announcements, roles: [UserRole.curator]),

  // Профиль — все роли
  _NavItem(
    label: 'Профиль',
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
    route: AppRoutes.profile,
  ),
];

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) {
        final prevUser = prev is AuthAuthenticated ? prev.user : null;
        final currUser = curr is AuthAuthenticated ? curr.user : null;
        return prevUser?.role != currUser?.role ||
            (prevUser == null) != (currUser == null);
      },
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        final visibleItems = _navItems
            .where(
              (item) =>
                  item.roles.isEmpty ||
                  (user != null && item.roles.contains(user.role)),
            )
            .toList();

        final isWide = MediaQuery.sizeOf(context).width >= 768;

        if (isWide) {
          return _DesktopShell(items: visibleItems, user: user, child: child);
        }
        return _MobileShell(items: visibleItems, child: child);
      },
    );
  }
}

/// Десктопный вариант — боковая навигация
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;
  final UserEntity? user;

  const _DesktopShell({
    required this.child,
    required this.items,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 232,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppColors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF334155) : AppColors.gray100,
                ),
              ),
            ),
            child: Column(
              children: [
                // Логотип
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Image.asset(
                          'assets/img/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryBlue,
                            child: const Icon(
                              Icons.school_outlined,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Колледж', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),

                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 4),

                // Пункты меню
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    children: items.map((item) {
                      final isActive = location == item.route ||
                          location.startsWith('${item.route}/');
                      return _SidebarItem(item: item, isActive: isActive);
                    }).toList(),
                  ),
                ),

                // Пользователь и выход
                if (user != null) _SidebarUserTile(user: user!),
              ],
            ),
          ),

          // Основной контент
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;

  const _SidebarItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.lightBlue, Color(0xFFEFF6FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isActive
              ? Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                )
              : null,
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              key: ValueKey(isActive),
              size: 20,
              color: isActive ? AppColors.primaryBlue : AppColors.gray500,
            ),
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? AppColors.primaryBlue : AppColors.gray700,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(item.label),
          ),
          onTap: () => context.go(item.route),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserTile extends StatelessWidget {
  final UserEntity user;

  const _SidebarUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 4),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go(AppRoutes.profile),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          user.firstName[0],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.shortName,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.gray500,
                      ),
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthLogoutRequested()),
                      tooltip: 'Выйти',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Мобильный вариант — нижняя навигация с поддержкой overflow через «Ещё»
class _MobileShell extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;

  const _MobileShell({required this.child, required this.items});

  static const _maxInBar = 4;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final needsMore = items.length > 5;
    final barItems = needsMore ? items.sublist(0, _maxInBar) : items;
    final overflowItems =
        needsMore ? items.sublist(_maxInBar) : const <_NavItem>[];

    final inOverflow = overflowItems.any(
      (item) =>
          location == item.route || location.startsWith('${item.route}/'),
    );

    int currentIndex = barItems.indexWhere(
      (item) =>
          location == item.route || location.startsWith('${item.route}/'),
    );
    if (currentIndex < 0) {
      currentIndex = (needsMore && inOverflow) ? _maxInBar : 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
            if (needsMore && i == _maxInBar) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => _OverflowSheet(
                  items: overflowItems,
                  location: location,
                ),
              );
            } else {
              context.go(barItems[i].route);
            }
          },
          destinations: [
            ...barItems.map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
                tooltip: item.label,
              ),
            ),
            if (needsMore)
              const NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                selectedIcon: Icon(Icons.more_horiz_rounded),
                label: 'Ещё',
              ),
          ],
        ),
      ),
    );
  }
}

class _OverflowSheet extends StatelessWidget {
  final List<_NavItem> items;
  final String location;

  const _OverflowSheet({required this.items, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: items.map((item) {
                  final isActive = location == item.route ||
                      location.startsWith('${item.route}/');
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.lightBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? AppColors.primaryBlue
                            : AppColors.gray500,
                      ),
                      title: Text(
                        item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isActive
                              ? AppColors.primaryBlue
                              : AppColors.gray700,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      horizontalTitleGap: 12,
                      onTap: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.go(item.route);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
