import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _roleFilter;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'perPage': '50'};
      if (_search.isNotEmpty) params['search'] = _search;
      if (_roleFilter != null) params['role'] = _roleFilter;

      final response = await dioClient.dio.get(ApiConstants.users, queryParameters: params);
      setState(() {
        _users = response.data['data'] as List;
        _total = (response.data['meta'] as Map)['total'] as int? ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить пользователей'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Пользователи', style: AppTextStyles.h3),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: () {}, tooltip: 'Добавить'),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Поиск и фильтры
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      _search = v;
                      _load();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени или email',
                      prefixIcon: Icon(Icons.search_outlined, size: 20, color: AppColors.gray500),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.white,
                    ),
                    child: Icon(Icons.filter_list_outlined, size: 20, color: _roleFilter != null ? AppColors.primaryBlue : AppColors.gray500),
                  ),
                  onSelected: (v) { _roleFilter = v; _load(); },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Все роли')),
                    const PopupMenuItem(value: 'ADMIN', child: Text('Администратор')),
                    const PopupMenuItem(value: 'TEACHER', child: Text('Преподаватель')),
                    const PopupMenuItem(value: 'STUDENT', child: Text('Студент')),
                    const PopupMenuItem(value: 'CURATOR', child: Text('Куратор')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Найдено: $_total', style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _users.isEmpty
                        ? const EmptyState(icon: Icons.people_outline, title: 'Пользователей нет')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) => _buildUserTile(_users[i] as Map<String, dynamic>),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final role = user['role'] as String;
    final isActive = user['isActive'] as bool? ?? true;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.lightBlue,
            child: Text(
              (user['firstName'] as String)[0],
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['lastName']} ${user['firstName']}',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(user['email'] as String, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _roleBadge(role),
              if (!isActive) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Неактивен', style: AppTextStyles.label.copyWith(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final (label, color) = switch (role) {
      'ADMIN' => ('Администратор', AppColors.error),
      'TEACHER' => ('Преподаватель', AppColors.primaryBlue),
      'STUDENT' => ('Студент', AppColors.success),
      'CURATOR' => ('Куратор', AppColors.warning),
      _ => (role, AppColors.gray500),
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
