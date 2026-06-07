import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

/// Электронный журнал оценок для преподавателя.
/// groupId и subjectId передаются через параметры роутера.
class GradeJournalPage extends StatefulWidget {
  final String groupId;
  final String subjectId;

  const GradeJournalPage({super.key, required this.groupId, required this.subjectId});

  @override
  State<GradeJournalPage> createState() => _GradeJournalPageState();
}

class _GradeJournalPageState extends State<GradeJournalPage> {
  List<dynamic> _journalRows = [];
  bool _loading = true;
  String? _error;

  // Диалог выставления оценки
  String? _selectedStudentId;
  String? _selectedStudentName;
  int _gradeValue = 5;
  String _gradeType = 'CURRENT';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await dioClient.dio.get(
        '${ApiConstants.grades}/group/${widget.groupId}/subject/${widget.subjectId}',
      );
      setState(() {
        _journalRows = resp.data['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Не удалось загрузить журнал'; _loading = false; });
    }
  }

  Future<void> _addGrade() async {
    if (_selectedStudentId == null) return;
    try {
      await dioClient.dio.post(ApiConstants.grades, data: {
        'studentId': _selectedStudentId,
        'subjectId': widget.subjectId,
        'value': _gradeValue,
        'type': _gradeType,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оценка выставлена'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showGradeDialog(String studentId, String studentName) {
    _selectedStudentId = studentId;
    _selectedStudentName = studentName;
    _gradeValue = 5;
    _gradeType = 'CURRENT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Выставить оценку', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(studentName, style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
              const SizedBox(height: 20),

              // Выбор оценки (2–5)
              Text('Оценка', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [2, 3, 4, 5].map((v) {
                  final selected = _gradeValue == v;
                  return GestureDetector(
                    onTap: () => setModalState(() => _gradeValue = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected ? _gradeColor(v) : AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _gradeColor(v) : AppColors.gray200,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$v',
                          style: AppTextStyles.h2.copyWith(
                            color: selected ? AppColors.white : AppColors.gray500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Тип оценки
              Text('Тип работы', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  ('CURRENT', 'Текущая'),
                  ('CONTROL', 'Контрольная'),
                  ('EXAM', 'Экзамен'),
                  ('COURSEWORK', 'Курсовая'),
                  ('PRACTICE', 'Практика'),
                ].map((t) {
                  final selected = _gradeType == t.$1;
                  return GestureDetector(
                    onTap: () => setModalState(() => _gradeType = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.lightBlue : AppColors.gray50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected ? AppColors.primaryBlue : AppColors.gray200,
                        ),
                      ),
                      child: Text(
                        t.$2,
                        style: AppTextStyles.captionMedium.copyWith(
                          color: selected ? AppColors.primaryBlue : AppColors.gray700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addGrade,
                  child: const Text('Сохранить оценку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Журнал оценок', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _journalRows.isEmpty
                  ? const EmptyState(icon: Icons.grade_outlined, title: 'Нет студентов в группе')
                  : _buildJournal(),
    );
  }

  Widget _buildJournal() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _journalRows.length,
      itemBuilder: (_, i) {
        final row = _journalRows[i] as Map<String, dynamic>;
        final student = row['student'] as Map<String, dynamic>;
        final grades = row['grades'] as List? ?? [];
        final average = row['average'] as num?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка строки студента
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.gray50,
                      child: Text(
                        (student['firstName'] as String)[0],
                        style: AppTextStyles.captionMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${student['lastName']} ${student['firstName']} ${student['middleName'] ?? ''}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    // Средний балл
                    if (average != null)
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
                    const SizedBox(width: 8),
                    // Кнопка добавить оценку
                    GestureDetector(
                      onTap: () => _showGradeDialog(
                        student['id'] as String,
                        '${student['lastName']} ${student['firstName']}',
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),

                // Оценки
                if (grades.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Оценок нет', style: AppTextStyles.caption),
                  )
                else ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: grades.map((g) {
                      final grade = g as Map<String, dynamic>;
                      final v = grade['value'] as int;
                      final type = grade['type'] as String;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gradeColor(v).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _gradeColor(v).withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$v', style: AppTextStyles.bodyMedium.copyWith(color: _gradeColor(v))),
                            Text(_shortType(type), style: AppTextStyles.label.copyWith(color: AppColors.gray500)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _gradeColor(int v) => switch (v) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };

  String _shortType(String t) => switch (t) {
        'CURRENT' => 'тек.',
        'CONTROL' => 'КР',
        'EXAM' => 'экз.',
        'COURSEWORK' => 'кур.',
        'PRACTICE' => 'пр.',
        _ => t,
      };
}
