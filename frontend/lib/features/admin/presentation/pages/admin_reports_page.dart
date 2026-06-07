import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

enum _ReportType { attendance, grades }

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<dynamic> _groups = [];
  String? _selectedGroupId;
  _ReportType _reportType = _ReportType.attendance;
  bool _loadingGroups = true;
  bool _loadingReport = false;
  Map<String, dynamic>? _attendanceData;
  List<dynamic>? _gradesData;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final resp = await dioClient.dio.get(ApiConstants.groups);
      setState(() {
        _groups = resp.data['data'] as List;
        _loadingGroups = false;
      });
    } catch (_) {
      setState(() => _loadingGroups = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedGroupId == null) return;
    setState(() { _loadingReport = true; _attendanceData = null; _gradesData = null; });
    try {
      if (_reportType == _ReportType.attendance) {
        final resp = await dioClient.dio.get('${ApiConstants.reports}/attendance/group/$_selectedGroupId');
        setState(() => _attendanceData = resp.data['data'] as Map<String, dynamic>);
      } else {
        final resp = await dioClient.dio.get('${ApiConstants.reports}/grades/group/$_selectedGroupId');
        setState(() => _gradesData = (resp.data['data']['studentStats'] as List));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сформировать отчёт. Проверьте данные.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _loadingReport = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Отчёты', style: AppTextStyles.h3)),
      body: _loadingGroups
          ? const LoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Параметры отчёта
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Параметры отчёта', style: AppTextStyles.h4),
                      const SizedBox(height: 16),
                      Text('Группа', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(isDense: true),
                        hint: const Text('Выберите группу'),
                        items: _groups.cast<Map<String, dynamic>>().map((g) => DropdownMenuItem(
                          value: g['id'] as String,
                          child: Text(g['name'] as String),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedGroupId = v),
                      ),
                      const SizedBox(height: 16),
                      Text('Тип отчёта', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _typeButton(
                              icon: Icons.how_to_reg_outlined,
                              label: 'Посещаемость',
                              selected: _reportType == _ReportType.attendance,
                              onTap: () => setState(() => _reportType = _ReportType.attendance),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _typeButton(
                              icon: Icons.grade_outlined,
                              label: 'Успеваемость',
                              selected: _reportType == _ReportType.grades,
                              onTap: () => setState(() => _reportType = _ReportType.grades),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedGroupId != null ? _generate : null,
                          icon: const Icon(Icons.bar_chart_outlined, size: 18),
                          label: const Text('Сформировать отчёт'),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_loadingReport) ...[
                  const SizedBox(height: 24),
                  const LoadingIndicator(),
                ],

                if (_attendanceData != null) ...[
                  const SizedBox(height: 20),
                  _buildAttendanceReport(_attendanceData!),
                ],

                if (_gradesData != null) ...[
                  const SizedBox(height: 20),
                  _buildGradesReport(_gradesData!),
                ],
              ],
            ),
    );
  }

  Widget _typeButton({required IconData icon, required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.gray50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.gray200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.white : AppColors.gray500),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.captionMedium.copyWith(color: selected ? AppColors.white : AppColors.gray700)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceReport(Map<String, dynamic> data) {
    final present = (data['PRESENT'] ?? 0) as int;
    final absent = (data['ABSENT'] ?? 0) as int;
    final late = (data['LATE'] ?? 0) as int;
    final excused = (data['EXCUSED'] ?? 0) as int;
    final total = present + absent + late + excused;
    if (total == 0) return const AppCard(child: Center(child: Text('Нет данных по посещаемости')));

    final rate = (present / total * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Отчёт по посещаемости', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sections: [
                        PieChartSectionData(value: present.toDouble(), color: AppColors.success, title: '', radius: 42),
                        PieChartSectionData(value: absent.toDouble(), color: AppColors.error, title: '', radius: 42),
                        PieChartSectionData(value: late.toDouble(), color: AppColors.warning, title: '', radius: 42),
                        PieChartSectionData(value: excused.toDouble(), color: AppColors.info, title: '', radius: 42),
                      ],
                      centerSpaceRadius: 26,
                      sectionsSpace: 2,
                    )),
                    Text('$rate%', style: AppTextStyles.h3),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow('Присутствовали', present, total, AppColors.success),
                    _statRow('Отсутствовали', absent, total, AppColors.error),
                    _statRow('Опоздали', late, total, AppColors.warning),
                    _statRow('Уваж. причина', excused, total, AppColors.info),
                    const Divider(height: 12),
                    Text('Всего записей: $total', style: AppTextStyles.captionMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, int total, Color color) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text('$value ($pct%)', style: AppTextStyles.captionMedium),
        ],
      ),
    );
  }

  Widget _buildGradesReport(List<dynamic> rows) {
    if (rows.isEmpty) return const AppCard(child: Center(child: Text('Нет данных по успеваемости')));

    final sorted = List<Map<String, dynamic>>.from(rows.cast());
    sorted.sort((a, b) {
      final av = (a['average'] as num?)?.toDouble() ?? 0;
      final bv = (b['average'] as num?)?.toDouble() ?? 0;
      return bv.compareTo(av);
    });

    final avgAll = sorted.fold<double>(0, (sum, r) => sum + ((r['average'] as num?)?.toDouble() ?? 0)) / sorted.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Отчёт по успеваемости', style: AppTextStyles.h4)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gradeColor(avgAll.round()).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ср: ${avgAll.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(color: _gradeColor(avgAll.round())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((e) {
            final row = e.value;
            final student = row['student'] as Map;
            final avg = row['average'] as num?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                      width: 90,
                      child: LinearProgressIndicator(
                        value: avg / 5,
                        backgroundColor: AppColors.gray100,
                        color: _gradeColor(avg.round()),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(avg.toStringAsFixed(1), style: AppTextStyles.captionMedium.copyWith(color: _gradeColor(avg.round()))),
                  ] else
                    Text('—', style: AppTextStyles.caption),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _gradeColor(int v) => switch (v) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };
}
