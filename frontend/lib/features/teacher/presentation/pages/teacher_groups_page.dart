import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

/// Экран "Мои группы и дисциплины" для преподавателя
class TeacherGroupsPage extends StatefulWidget {
  const TeacherGroupsPage({super.key});

  @override
  State<TeacherGroupsPage> createState() => _TeacherGroupsPageState();
}

class _TeacherGroupsPageState extends State<TeacherGroupsPage> {
  List<dynamic> _entries = [];
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
      final resp = await dioClient.dio.get('${ApiConstants.schedule}/my');
      final all = resp.data['data'] as List;

      // Уникальные пары группа+дисциплина
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final e in all) {
        final entry = e as Map<String, dynamic>;
        final key = '${entry['groupId']}_${entry['subjectId']}';
        if (seen.add(key)) unique.add(entry);
      }

      setState(() { _entries = unique; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Не удалось загрузить данные'; _loading = false; });
    }
  }

  // Группируем по group.name
  Map<String, List<Map<String, dynamic>>> _groupByGroup() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final entry = e as Map<String, dynamic>;
      final groupName = (entry['group'] as Map)['name'] as String;
      map.putIfAbsent(groupName, () => []).add(entry);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Мои группы', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _entries.isEmpty
                  ? const EmptyState(icon: Icons.group_outlined, title: 'Нет привязанных групп')
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final grouped = _groupByGroup();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((group) {
        final groupData = (group.value.first['group'] as Map<String, dynamic>);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок группы
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(group.key, style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white)),
                  ),
                  const SizedBox(width: 10),
                  Text('${group.value.length} дисц.', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 8),
              // Дисциплины группы
              ...group.value.map((entry) {
                final subject = entry['subject'] as Map<String, dynamic>;
                final groupId = (entry['group'] as Map)['id'] as String;
                final subjectId = (entry['subject'] as Map)['id'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: AppCard(
                    onTap: () => context.push('/teacher/grades/$groupId/$subjectId'),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.book_outlined, color: AppColors.primaryBlue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject['name'] as String, style: AppTextStyles.bodyMedium),
                              Text(subject['code'] as String, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _actionBtn(
                              icon: Icons.how_to_reg_outlined,
                              label: 'Посещ.',
                              color: AppColors.success,
                              onTap: () => context.push('/teacher/attendance/$groupId'),
                            ),
                            const SizedBox(width: 6),
                            _actionBtn(
                              icon: Icons.grade_outlined,
                              label: 'Журнал',
                              color: AppColors.primaryBlue,
                              onTap: () => context.push('/teacher/grades/$groupId/$subjectId'),
                            ),
                            const SizedBox(width: 6),
                            _actionBtn(
                              icon: Icons.bar_chart_outlined,
                              label: 'Стат.',
                              color: AppColors.info,
                              onTap: () => context.push('/teacher/stats/$groupId'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
