import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/constants/hive_constants.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box _settingsBox;
  String _locale = 'ru';
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(HiveConstants.settingsBox);
    _locale = _settingsBox.get(HiveConstants.localeKey, defaultValue: 'ru') as String;
    _notifications = _settingsBox.get(HiveConstants.notificationsKey, defaultValue: true) as bool;
  }

  Future<void> _setLocale(String locale) async {
    await _settingsBox.put(HiveConstants.localeKey, locale);
    setState(() => _locale = locale);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Язык изменён. Перезапустите приложение для применения.')),
      );
    }
  }

  Future<void> _setNotifications(bool value) async {
    await _settingsBox.put(HiveConstants.notificationsKey, value);
    setState(() => _notifications = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Настройки', style: AppTextStyles.h3)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Язык
          _section('Язык интерфейса', [
            _radioTile('Русский', 'ru', Icons.language),
            _radioTile('Қазақша', 'kk', Icons.language),
            _radioTile('English', 'en', Icons.language),
          ]),
          const SizedBox(height: 16),

          // Внешний вид
          _section('Внешний вид', [
            _switchTile(
              'Тёмная тема',
              'Переключить на тёмный режим',
              Icons.dark_mode_outlined,
              ThemeNotifier.instance.isDark,
              (v) => ThemeNotifier.instance.setDark(v),
            ),
          ]),
          const SizedBox(height: 16),

          // Уведомления
          _section('Уведомления', [
            _switchTile(
              'Push-уведомления',
              'Получать уведомления об оценках и расписании',
              Icons.notifications_outlined,
              _notifications,
              _setNotifications,
            ),
          ]),
          const SizedBox(height: 16),

          // О приложении
          _section('О приложении', [
            _infoTile('Версия', '1.0.0', Icons.info_outline),
            _infoTile('Разработчик', 'Дипломный проект', Icons.school_outlined),
            _infoTile('Технологии', 'Flutter + Node.js', Icons.code_outlined),
          ]),
          const SizedBox(height: 24),

          // Выход
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_outlined, size: 18, color: AppColors.error),
              ),
              title: Text('Выйти из системы', style: AppTextStyles.body.copyWith(color: AppColors.error)),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray500)),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _radioTile(String label, String value, IconData icon) {
    final selected = _locale == value;
    return ListTile(
      leading: Icon(icon, size: 20, color: selected ? AppColors.primaryBlue : AppColors.gray500),
      title: Text(label, style: AppTextStyles.body.copyWith(
        color: selected ? AppColors.primaryBlue : AppColors.gray900,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      )),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
          : const Icon(Icons.radio_button_unchecked, color: AppColors.gray200, size: 20),
      onTap: () => _setLocale(value),
      dense: true,
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.gray500),
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
      dense: true,
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.gray500),
      title: Text(label, style: AppTextStyles.body),
      trailing: Text(value, style: AppTextStyles.caption),
      dense: true,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выйти из системы?'),
        content: const Text('Вы будете перенаправлены на экран входа.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text('Выйти', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
