import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  Map<String, dynamic>? _group;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Получаем данные текущего пользователя — там есть studentGroup
      final meResp = await dioClient.dio.get(ApiConstants.me);
      final user = meResp.data['data'] as Map<String, dynamic>;
      final groupId = user['studentGroupId'] as String?;
      if (groupId == null) {
        setState(() { _loading = false; });
        return;
      }
      final groupResp = await dioClient.dio.get('${ApiConstants.groups}/$groupId');
      setState(() { _group = groupResp.data['data'] as Map<String, dynamic>; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить данные группы'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Моя группа', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.error)))
              : _group == null
                  ? Center(child: Text('Вы не привязаны к группе', style: AppTextStyles.body.copyWith(color: AppColors.gray500)))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final g = _group!;
    final specialty = g['specialty'] as Map<String, dynamic>?;
    final curator = g['curator'] as Map<String, dynamic>?;
    final students = g['students'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Карточка группы
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_outlined, color: AppColors.primaryBlue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['name'] as String, style: AppTextStyles.h3),
                        if (specialty != null)
                          Text(specialty['name'] as String, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _infoRow(Icons.calendar_today_outlined, 'Год поступления', '${g['year']}'),
              _infoRow(Icons.people_outline, 'Студентов', '${students.length}'),
              if (specialty != null)
                _infoRow(Icons.bookmark_outline, 'Код специальности', specialty['code'] as String),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Куратор
        if (curator != null) ...[
          Text('Куратор', style: AppTextStyles.h4),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.lightBlue,
                  child: Text(
                    (curator['firstName'] as String)[0],
                    style: AppTextStyles.h4.copyWith(color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${curator['lastName']} ${curator['firstName']} ${curator['middleName'] ?? ''}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (curator['email'] != null)
                        Text(curator['email'] as String, style: AppTextStyles.caption),
                      if (curator['phone'] != null)
                        Text(curator['phone'] as String, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Список студентов
        Text('Студенты группы (${students.length})', style: AppTextStyles.h4),
        const SizedBox(height: 10),
        ...students.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value as Map<String, dynamic>;
          final isMe = (context.read<AuthBloc>().state is AuthAuthenticated)
              ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id == s['id']
              : false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: isMe ? AppColors.lightBlue : null,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryBlue : AppColors.gray50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: isMe ? AppColors.white : AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${s['lastName']} ${s['firstName']} ${s['middleName'] ?? ''}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                        color: isMe ? AppColors.primaryBlue : AppColors.gray900,
                      ),
                    ),
                  ),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Вы', style: AppTextStyles.label.copyWith(color: AppColors.white)),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray500),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray900)),
        ],
      ),
    );
  }
}
