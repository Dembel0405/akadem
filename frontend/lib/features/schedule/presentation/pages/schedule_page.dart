import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<dynamic> _entries = [];
  bool _loading = true;
  String? _error;

  static const _dayNames = {
    'MONDAY': 'Понедельник',
    'TUESDAY': 'Вторник',
    'WEDNESDAY': 'Среда',
    'THURSDAY': 'Четверг',
    'FRIDAY': 'Пятница',
    'SATURDAY': 'Суббота',
  };

  static const _dayOrder = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await dioClient.dio.get('${ApiConstants.schedule}/my');
      setState(() {
        _entries = response.data['data'] as List;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить расписание'; _loading = false; });
    }
  }

  Map<String, List<dynamic>> _groupByDay() {
    final map = <String, List<dynamic>>{};
    for (final e in _entries) {
      final day = e['dayOfWeek'] as String;
      map.putIfAbsent(day, () => []).add(e);
    }
    for (final day in map.values) {
      day.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Расписание', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'Расписание пустое',
                      subtitle: 'Занятия ещё не добавлены',
                    )
                  : _buildSchedule(),
    );
  }

  Widget _buildSchedule() {
    final grouped = _groupByDay();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _dayOrder.where((d) => grouped.containsKey(d)).map((day) {
        final entries = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_dayNames[day]!, style: AppTextStyles.h4),
            ),
            ...entries.map((entry) => _buildEntry(entry as Map<String, dynamic>)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEntry(Map<String, dynamic> entry) {
    final subject = entry['subject'] as Map<String, dynamic>;
    final teacher = entry['teacher'] as Map<String, dynamic>?;
    final group = entry['group'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(entry['startTime'] as String, style: AppTextStyles.bodyMedium),
                Container(width: 1, height: 20, color: AppColors.gray200, margin: const EdgeInsets.symmetric(vertical: 4)),
                Text(entry['endTime'] as String, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(width: 12),
            Container(width: 3, height: 56, color: AppColors.primaryBlue, margin: const EdgeInsets.only(right: 12)),
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject['name'] as String, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (teacher != null) ...[
                        const Icon(Icons.person_outline, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(
                          '${teacher['lastName']} ${(teacher['firstName'] as String)[0]}.',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (group != null) ...[
                        const Icon(Icons.group_outlined, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(group['name'] as String, style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                      ],
                      if (entry['room'] != null) ...[
                        const Icon(Icons.room_outlined, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text('ауд. ${entry['room']}', style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
