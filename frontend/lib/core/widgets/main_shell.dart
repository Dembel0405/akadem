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
  final List<UserRole> roles; // пустой = всем доступен

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.roles = const [],
  });
}

const _navItems = [
  _NavItem(
    label: 'Главная',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: AppRoutes.dashboard,
  ),
  _NavItem(
    label: 'Расписание',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    route: AppRoutes.schedule,
  ),
  _NavItem(
    label: 'Посещаемость',
    icon: Icons.how_to_reg_outlined,
    activeIcon: Icons.how_to_reg,
    route: AppRoutes.attendance,
  ),
  _NavItem(
    label: 'Оценки',
    icon: Icons.grade_outlined,
    activeIcon: Icons.grade,
    route: AppRoutes.grades,
  ),
  _NavItem(
    label: 'Объявления',
    icon: Icons.campaign_outlined,
    activeIcon: Icons.campaign,
    route: AppRoutes.announcements,
  ),
  _NavItem(
    label: 'Пользователи',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    route: AppRoutes.users,
    roles: [UserRole.admin],
  ),
];

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final visibleItems = _navItems
        .where((item) => item.roles.isEmpty || (user != null && item.roles.contains(user.role)))
        .toList();

    final isWide = MediaQuery.sizeOf(context).width >= 768;

    if (isWide) {
      return _DesktopShell(child: child, items: visibleItems, user: user);
    }

    return _MobileShell(child: child, items: visibleItems);
  }
}

/// Десктопный вариант — боковая навигация
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;
  final UserEntity? user;

  const _DesktopShell({required this.child, required this.items, this.user});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(right: BorderSide(color: AppColors.gray200)),
            ),
            child: Column(
              children: [
                // Логотип
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_outlined, size: 18, color: AppColors.white),
                      ),
                      const SizedBox(width: 10),
                      Text('Колледж', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),

                // Пункты меню
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: items.map((item) {
                      final isActive = location.startsWith(item.route);
                      return _SidebarItem(item: item, isActive: isActive);
                    }).toList(),
                  ),
                ),

                // Пользователь и выход
                if (user != null)
                  _SidebarUserTile(user: user!),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? AppColors.lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            isActive ? item.activeIcon : item.icon,
            size: 20,
            color: isActive ? AppColors.primaryBlue : AppColors.gray500,
          ),
          title: Text(
            item.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? AppColors.primaryBlue : AppColors.gray700,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          onTap: () => context.go(item.route),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightBlue,
              child: Text(
                user.firstName[0],
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
              ),
            ),
            title: Text(user.shortName, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.logout_outlined, size: 18, color: AppColors.gray500),
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              tooltip: 'Выйти',
            ),
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

/// Мобильный вариант — нижняя навигация
class _MobileShell extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;

  const _MobileShell({required this.child, required this.items});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = items.indexWhere((item) => location.startsWith(item.route));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, items.length - 1),
        onDestinationSelected: (i) => context.go(items[i].route),
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
