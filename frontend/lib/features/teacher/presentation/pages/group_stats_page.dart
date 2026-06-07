import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

/// Статистика по группе: посещаемость + успеваемость
class GroupStatsPage extends StatefulWidget {
  final String groupId;

  const GroupStatsPage({super.key, required this.groupId});

  @override
  State<GroupStatsPage> createState() => _GroupStatsPageState();
}

class _GroupStatsPageState extends State<GroupStatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _attendanceStats;
  List<dynamic>? _gradesReport;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [attResp, gradesResp] = await Future.wait([
        dioClient.dio.get('${ApiConstants.attendance}/group/${widget.groupId}/stats'),
        dioClient.dio.get('${ApiConstants.reports}/grades/group/${widget.groupId}'),
      ]);
      setState(() {
        _attendanceStats = attResp.data['data'] as Map<String, dynamic>;
        _gradesReport = (gradesResp.data['data']['studentStats'] as List);
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
        title: Text('Статистика группы', style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primaryBlue,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.buttonSmall,
          tabs: const [
            Tab(text: 'Посещаемость'),
            Tab(text: 'Успеваемость'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabs,
              children: [
                _buildAttendanceTab(),
                _buildGradesTab(),
              ],
            ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceStats == null) return const Center(child: Text('Нет данных'));

    final stats = _attendanceStats!;
    final present = (stats['PRESENT'] ?? 0) as int;
    final absent = (stats['ABSENT'] ?? 0) as int;
    final late = (stats['LATE'] ?? 0) as int;
    final excused = (stats['EXCUSED'] ?? 0) as int;
    final total = present + absent + late + excused;

    if (total == 0) {
      return const Center(child: Text('Нет записей посещаемости'));
    }

    final rate = (present / total * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Сводная карточка
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Общая посещаемость', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          sections: [
                            PieChartSectionData(value: present.toDouble(), color: AppColors.success, title: '', radius: 45),
                            PieChartSectionData(value: absent.toDouble(), color: AppColors.error, title: '', radius: 45),
                            PieChartSectionData(value: late.toDouble(), color: AppColors.warning, title: '', radius: 45),
                            PieChartSectionData(value: excused.toDouble(), color: AppColors.info, title: '', radius: 45),
                          ],
                          centerSpaceRadius: 28,
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
                        _legendRow('Присутствовали', present, AppColors.success),
                        _legendRow('Отсутствовали', absent, AppColors.error),
                        _legendRow('Опоздали', late, AppColors.warning),
                        _legendRow('Уваж. причина', excused, AppColors.info),
                        const Divider(height: 16),
                        _legendRow('Всего записей', total, AppColors.gray500),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTab() {
    if (_gradesReport == null) return const Center(child: Text('Нет данных'));

    final rows = _gradesReport!;
    if (rows.isEmpty) return const Center(child: Text('Нет студентов'));

    // Сортируем по среднему баллу убывающий
    final sorted = List<Map<String, dynamic>>.from(rows.cast());
    sorted.sort((a, b) {
      final av = (a['average'] as num?)?.toDouble() ?? 0;
      final bv = (b['average'] as num?)?.toDouble() ?? 0;
      return bv.compareTo(av);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Топ-3
        if (sorted.length >= 3) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Лидеры по успеваемости', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ...sorted.take(3).toList().asMap().entries.map((e) {
                  final row = e.value;
                  final student = row['student'] as Map;
                  final avg = row['average'] as num?;
                  final medals = ['🥇', '🥈', '🥉'];
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

        // Все студенты
        Text('Все студенты', style: AppTextStyles.h4),
        const SizedBox(height: 10),
        ...sorted.map((row) {
          final student = row['student'] as Map;
          final avg = row['average'] as num?;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${student['lastName']} ${student['firstName']}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  if (avg != null) ...[
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        value: avg / 5,
                        backgroundColor: AppColors.gray100,
                        color: _gradeColor(avg.round()),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      avg.toStringAsFixed(1),
                      style: AppTextStyles.bodyMedium.copyWith(color: _gradeColor(avg.round())),
                    ),
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

  Widget _legendRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text('$count', style: AppTextStyles.captionMedium),
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
