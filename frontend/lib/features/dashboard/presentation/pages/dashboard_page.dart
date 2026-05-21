import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await dioClient.dio.get(ApiConstants.dashboard);
      setState(() { _data = response.data['data'] as Map<String, dynamic>; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить данные'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Главная', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadDashboard,
            tooltip: 'Обновить',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadDashboard)
              : _buildContent(user),
    );
  }

  Widget _buildContent(UserEntity? user) {
    if (_data == null) return const EmptyState(icon: Icons.dashboard_outlined, title: 'Нет данных');

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Приветствие
          if (user != null) ...[
            Text(
              'Добрый день, ${user.firstName}!',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 4),
            Text(
              _getRoleLabel(user.role),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 24),
          ],

          // Статистические карточки
          if (_data!['stats'] != null) ...[
            Text('Статистика', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _buildStatsGrid(_data!['stats'] as Map<String, dynamic>),
            const SizedBox(height: 24),
          ],

          // Посещаемость (график)
          if (_data!['attendanceStats'] != null) ...[
            Text('Посещаемость за неделю', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _buildAttendanceChart(_data!['attendanceStats'] as Map<String, dynamic>),
            const SizedBox(height: 24),
          ],

          // Объявления
          if (_data!['recentAnnouncements'] != null) ...[
            Text('Последние объявления', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ..._buildAnnouncements(_data!['recentAnnouncements'] as List),
          ],

          // Последние оценки (для студента)
          if (_data!['recentGrades'] != null) ...[
            Text('Последние оценки', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ..._buildRecentGrades(_data!['recentGrades'] as List),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final items = <(String, String, IconData, Color)>[];

    if (stats['totalStudents'] != null) {
      items.add(('Студентов', '${stats['totalStudents']}', Icons.people_outline, AppColors.primaryBlue));
    }
    if (stats['totalTeachers'] != null) {
      items.add(('Преподавателей', '${stats['totalTeachers']}', Icons.person_outline, AppColors.success));
    }
    if (stats['totalGroups'] != null) {
      items.add(('Групп', '${stats['totalGroups']}', Icons.group_outlined, AppColors.warning));
    }
    if (stats['groupsCount'] != null) {
      items.add(('Групп', '${stats['groupsCount']}', Icons.group_outlined, AppColors.primaryBlue));
    }
    if (stats['subjectsCount'] != null) {
      items.add(('Дисциплин', '${stats['subjectsCount']}', Icons.book_outlined, AppColors.success));
    }
    if (stats['todayClasses'] != null) {
      items.add(('Сегодня занятий', '${stats['todayClasses']}', Icons.schedule_outlined, AppColors.warning));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: items.map((item) => StatCard(
        title: item.$1,
        value: item.$2,
        icon: Icon(item.$3),
        iconColor: item.$4,
        iconBg: item.$4.withOpacity(0.1),
      )).toList(),
    );
  }

  Widget _buildAttendanceChart(Map<String, dynamic> stats) {
    final present = (stats['PRESENT'] ?? 0) as int;
    final absent = (stats['ABSENT'] ?? 0) as int;
    final late = (stats['LATE'] ?? 0) as int;
    final total = present + absent + late;

    if (total == 0) {
      return AppCard(
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text('Нет данных за эту неделю', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ),
        ),
      );
    }

    return AppCard(
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: present.toDouble(),
                      color: AppColors.success,
                      title: '$present',
                      titleStyle: AppTextStyles.captionMedium.copyWith(color: Colors.white),
                      radius: 55,
                    ),
                    if (absent > 0)
                      PieChartSectionData(
                        value: absent.toDouble(),
                        color: AppColors.error,
                        title: '$absent',
                        titleStyle: AppTextStyles.captionMedium.copyWith(color: Colors.white),
                        radius: 55,
                      ),
                    if (late > 0)
                      PieChartSectionData(
                        value: late.toDouble(),
                        color: AppColors.warning,
                        title: '$late',
                        titleStyle: AppTextStyles.captionMedium.copyWith(color: Colors.white),
                        radius: 55,
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Присутствовали', present, AppColors.success),
                  const SizedBox(height: 8),
                  _buildLegendItem('Отсутствовали', absent, AppColors.error),
                  const SizedBox(height: 8),
                  _buildLegendItem('Опоздали', late, AppColors.warning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text('$count', style: AppTextStyles.captionMedium),
      ],
    );
  }

  List<Widget> _buildAnnouncements(List announcements) {
    return announcements.take(3).map((a) {
      final ann = a as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ann['isPinned'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Закреплено', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
                ),
              Text(ann['title'] as String, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(
                ann['content'] as String,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecentGrades(List grades) {
    return grades.take(5).map((g) {
      final grade = g as Map<String, dynamic>;
      final value = grade['value'] as int;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _gradeColor(value).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: AppTextStyles.h4.copyWith(color: _gradeColor(value)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (grade['subject'] as Map)['name'] as String,
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(grade['type'] as String, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _gradeColor(int value) => switch (value) {
        5 => AppColors.success,
        4 => AppColors.primaryBlue,
        3 => AppColors.warning,
        _ => AppColors.error,
      };

  String _getRoleLabel(UserRole role) => switch (role) {
        UserRole.admin => 'Администратор',
        UserRole.teacher => 'Преподаватель',
        UserRole.student => 'Студент',
        UserRole.curator => 'Куратор',
      };
}
