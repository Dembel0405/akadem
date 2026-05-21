import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  Map<String, dynamic>? _data;
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
      final response = await dioClient.dio.get('${ApiConstants.grades}/my');
      setState(() {
        _data = response.data['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить оценки'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Мои оценки', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _data == null
                  ? const EmptyState(icon: Icons.grade_outlined, title: 'Нет оценок')
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final totalAverage = _data!['totalAverage'] as num;
    final bySubject = _data!['bySubject'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Общий средний балл
        AppCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _gradeColor(totalAverage.round()).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    totalAverage.toStringAsFixed(1),
                    style: AppTextStyles.h2.copyWith(color: _gradeColor(totalAverage.round())),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Средний балл', style: AppTextStyles.bodyMedium),
                  Text('По всем дисциплинам', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('Оценки по дисциплинам', style: AppTextStyles.h4),
        const SizedBox(height: 12),

        ...bySubject.map((s) => _buildSubjectSection(s as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildSubjectSection(Map<String, dynamic> subjectData) {
    final subject = subjectData['subject'] as Map<String, dynamic>;
    final grades = subjectData['grades'] as List;
    final average = subjectData['average'] as num;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(subject['name'] as String, style: AppTextStyles.bodyMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gradeColor(average.round()).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    average.toStringAsFixed(1),
                    style: AppTextStyles.bodyMedium.copyWith(color: _gradeColor(average.round())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: grades.map((g) => _buildGradeChip(g as Map<String, dynamic>)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeChip(Map<String, dynamic> grade) {
    final value = grade['value'] as int;
    final type = _typeLabel(grade['type'] as String);
    final color = _gradeColor(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$value', style: AppTextStyles.h4.copyWith(color: color)),
          Text(type, style: AppTextStyles.label.copyWith(color: AppColors.gray500)),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'CURRENT' => 'Тек.',
        'CONTROL' => 'КР',
        'EXAM' => 'Экз.',
        'COURSEWORK' => 'КР',
        'PRACTICE' => 'Пр.',
        _ => type,
      };

  Color _gradeColor(int value) => switch (value) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };
}
