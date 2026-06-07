import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await dioClient.dio.get(ApiConstants.dashboard);
      setState(() {
        _dashboard = resp.data['data'] as Map<String, dynamic>;
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
        title: Text('Аналитика', style: AppTextStyles.h3),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load)],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _dashboard == null
              ? const Center(child: Text('Нет данных'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildUsersChart(),
                      const SizedBox(height: 16),
                      _buildAttendanceSection(),
                      const SizedBox(height: 16),
                      _buildGradesSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _dashboard!;
    final users = stats['userStats'] as Map?;
    final counts = <_StatItem>[
      _StatItem('Студентов', '${users?['students'] ?? 0}', Icons.school_outlined, AppColors.primaryBlue),
      _StatItem('Преподавателей', '${users?['teachers'] ?? 0}', Icons.person_outlined, AppColors.success),
      _StatItem('Групп', '${stats['groupCount'] ?? 0}', Icons.group_outlined, AppColors.warning),
      _StatItem('Дисциплин', '${stats['subjectCount'] ?? 0}', Icons.book_outlined, AppColors.info),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = min(counts.length, constraints.maxWidth > 700 ? 4 : 2);
        final ratio = cols >= 4 ? 2.2 : 1.7;
        return GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: counts.map((s) => AppCard(
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.icon, size: 20, color: s.color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.value, style: AppTextStyles.h3.copyWith(color: s.color)),
                Text(s.label, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      )).toList(),
        );
      },
    );
  }

  Widget _buildUsersChart() {
    final users = _dashboard!['userStats'] as Map?;
    if (users == null) return const SizedBox.shrink();

    final students = (users['students'] ?? 0) as int;
    final teachers = (users['teachers'] ?? 0) as int;
    final curators = (users['curators'] ?? 0) as int;
    final admins = (users['admins'] ?? 1) as int;
    final total = students + teachers + curators + admins;
    if (total == 0) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Распределение пользователей', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(PieChartData(
                  sections: [
                    PieChartSectionData(value: students.toDouble(), color: AppColors.primaryBlue, title: '', radius: 45),
                    PieChartSectionData(value: teachers.toDouble(), color: AppColors.success, title: '', radius: 45),
                    PieChartSectionData(value: curators.toDouble(), color: AppColors.warning, title: '', radius: 45),
                    PieChartSectionData(value: admins.toDouble(), color: AppColors.info, title: '', radius: 45),
                  ],
                  centerSpaceRadius: 28,
                  sectionsSpace: 2,
                )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Студенты', students, total, AppColors.primaryBlue),
                    _legendItem('Преподаватели', teachers, total, AppColors.success),
                    _legendItem('Кураторы', curators, total, AppColors.warning),
                    _legendItem('Администраторы', admins, total, AppColors.info),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    final att = _dashboard!['recentAttendance'] as Map?;
    if (att == null) return const SizedBox.shrink();

    final present = (att['PRESENT'] ?? 0) as int;
    final absent = (att['ABSENT'] ?? 0) as int;
    final late = (att['LATE'] ?? 0) as int;
    final excused = (att['EXCUSED'] ?? 0) as int;
    final total = present + absent + late + excused;
    if (total == 0) return const SizedBox.shrink();

    final rate = (present / total * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Посещаемость (сводно)', style: AppTextStyles.h4)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _attColor(rate).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$rate%', style: AppTextStyles.bodyMedium.copyWith(color: _attColor(rate))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _attBar('Присутствовали', present, total, AppColors.success),
          _attBar('Отсутствовали', absent, total, AppColors.error),
          _attBar('Опоздали', late, total, AppColors.warning),
          _attBar('Уваж. причина', excused, total, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildGradesSection() {
    final avg = _dashboard!['averageGrade'] as num?;
    if (avg == null) return const SizedBox.shrink();

    final gradeColor = _gradeColor(avg.round());

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                avg.toStringAsFixed(1),
                style: AppTextStyles.h2.copyWith(color: gradeColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Средний балл по колледжу', style: AppTextStyles.bodyMedium),
              Text('По всем дисциплинам и группам', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int value, int total, Color color) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text('$value ($pct%)', style: AppTextStyles.captionMedium),
        ],
      ),
    );
  }

  Widget _attBar(String label, int value, int total, Color color) {
    final ratio = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.gray100,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('$value', style: AppTextStyles.captionMedium, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Color _attColor(int rate) {
    if (rate >= 85) return AppColors.success;
    if (rate >= 70) return AppColors.warning;
    return AppColors.error;
  }

  Color _gradeColor(int v) => switch (v) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}
