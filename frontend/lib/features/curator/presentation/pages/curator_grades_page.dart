import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class CuratorGradesPage extends StatefulWidget {
  final String groupId;

  const CuratorGradesPage({super.key, required this.groupId});

  @override
  State<CuratorGradesPage> createState() => _CuratorGradesPageState();
}

class _CuratorGradesPageState extends State<CuratorGradesPage> {
  List<dynamic>? _studentStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await dioClient.dio.get('${ApiConstants.reports}/grades/group/${widget.groupId}');
      setState(() {
        _studentStats = resp.data['data']['studentStats'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Успеваемость группы', style: AppTextStyles.h3),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load)],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _studentStats == null || _studentStats!.isEmpty
              ? const Center(child: Text('Нет данных'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final rows = List<Map<String, dynamic>>.from(_studentStats!.cast());
    rows.sort((a, b) {
      final av = (a['average'] as num?)?.toDouble() ?? 0;
      final bv = (b['average'] as num?)?.toDouble() ?? 0;
      return bv.compareTo(av);
    });

    final withGrades = rows.where((r) => r['average'] != null).toList();
    final groupAvg = withGrades.isEmpty
        ? null
        : withGrades.fold<double>(0, (s, r) => s + (r['average'] as num).toDouble()) / withGrades.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (groupAvg != null) ...[
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _gradeColor(groupAvg.round()).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(groupAvg.toStringAsFixed(1), style: AppTextStyles.h2.copyWith(color: _gradeColor(groupAvg.round()))),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Средний балл группы', style: AppTextStyles.bodyMedium),
                    Text('По всем дисциплинам', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (rows.length >= 3) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Лидеры по успеваемости', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ...rows.take(3).toList().asMap().entries.map((e) {
                  final row = e.value;
                  final student = row['student'] as Map;
                  final avg = row['average'] as num?;
                  const medals = ['🥇', '🥈', '🥉'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(medals[e.key], style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${student['lastName']} ${student['firstName']}', style: AppTextStyles.body),
                        ),
                        if (avg != null)
                          Text(avg.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(color: _gradeColor(avg.round()))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text('Все студенты', style: AppTextStyles.h4),
        const SizedBox(height: 10),
        ...rows.asMap().entries.map((e) {
          final row = e.value;
          final student = row['student'] as Map;
          final avg = row['average'] as num?;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${e.key + 1}', style: AppTextStyles.caption, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${student['lastName']} ${student['firstName']}', style: AppTextStyles.body),
                  ),
                  if (avg != null) ...[
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: avg / 5,
                        backgroundColor: AppColors.gray100,
                        color: _gradeColor(avg.round()),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(avg.toStringAsFixed(1), style: AppTextStyles.captionMedium.copyWith(color: _gradeColor(avg.round()))),
                  ] else
                    Text('—', style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _gradeColor(int v) => switch (v) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };
}
