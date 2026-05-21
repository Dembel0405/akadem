import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(title: Text('Профиль', style: AppTextStyles.h3)),
          body: user == null
              ? const Center(child: Text('Нет данных'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Аватар и имя
                    AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.lightBlue,
                            child: Text(
                              user.firstName[0],
                              style: AppTextStyles.h2.copyWith(color: AppColors.primaryBlue),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName, style: AppTextStyles.h4),
                                const SizedBox(height: 4),
                                Text(user.email, style: AppTextStyles.caption),
                                const SizedBox(height: 4),
                                _roleBadge(user.role),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.gray500),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Информация
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Контактная информация', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          _infoRow(Icons.email_outlined, 'Email', user.email),
                          if (user.phone != null)
                            _infoRow(Icons.phone_outlined, 'Телефон', user.phone!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Настройки
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Настройки аккаунта', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_outline, color: AppColors.gray500, size: 20),
                            title: Text('Сменить пароль', style: AppTextStyles.body),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.gray500),
                            onTap: () {},
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.language_outlined, color: AppColors.gray500, size: 20),
                            title: Text('Язык интерфейса', style: AppTextStyles.body),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.gray500),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      label: 'Выйти из системы',
                      variant: AppButtonVariant.danger,
                      fullWidth: true,
                      icon: const Icon(Icons.logout_outlined, size: 18),
                      onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray500),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    final (label, color) = switch (role) {
      UserRole.admin => ('Администратор', AppColors.error),
      UserRole.teacher => ('Преподаватель', AppColors.primaryBlue),
      UserRole.student => ('Студент', AppColors.success),
      UserRole.curator => ('Куратор', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}
