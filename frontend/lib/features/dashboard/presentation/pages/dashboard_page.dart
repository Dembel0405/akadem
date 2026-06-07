import 'dart:math' show min;

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

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  late final AnimationController _contentCtrl;
  late final Animation<double> _statsFade;
  late final Animation<Offset> _statsSlide;
  late final Animation<double> _chartFade;
  late final Animation<Offset> _chartSlide;
  late final Animation<double> _annFade;
  late final Animation<Offset> _annSlide;
  late final Animation<double> _gradesFade;
  late final Animation<Offset> _gradesSlide;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _setupAnimations();
    _loadDashboard();
  }

  void _setupAnimations() {
    Animation<T> interval<T>(
      Tween<T> tween,
      double start,
      double end, {
      Curve curve = Curves.easeOutCubic,
    }) =>
        tween.animate(
          CurvedAnimation(
            parent: _contentCtrl,
            curve: Interval(start, end, curve: curve),
          ),
        );

    _statsFade = interval(Tween(begin: 0.0, end: 1.0), 0.0, 0.45,
        curve: Curves.easeIn);
    _statsSlide = interval(
        Tween(begin: const Offset(0, 0.2), end: Offset.zero), 0.0, 0.45);

    _chartFade = interval(Tween(begin: 0.0, end: 1.0), 0.15, 0.55,
        curve: Curves.easeIn);
    _chartSlide = interval(
        Tween(begin: const Offset(0, 0.2), end: Offset.zero), 0.15, 0.55);

    _annFade = interval(Tween(begin: 0.0, end: 1.0), 0.3, 0.7,
        curve: Curves.easeIn);
    _annSlide = interval(
        Tween(begin: const Offset(0, 0.2), end: Offset.zero), 0.3, 0.7);

    _gradesFade = interval(Tween(begin: 0.0, end: 1.0), 0.45, 0.85,
        curve: Curves.easeIn);
    _gradesSlide = interval(
        Tween(begin: const Offset(0, 0.2), end: Offset.zero), 0.45, 0.85);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await dioClient.dio.get(ApiConstants.dashboard);
      setState(() {
        _data = response.data['data'] as Map<String, dynamic>;
        _loading = false;
      });
      _contentCtrl
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _loading
            ? const LoadingIndicator()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _loadDashboard)
                : _buildContent(user),
      ),
    );
  }

  Widget _buildContent(UserEntity? user) {
    if (_data == null) {
      return const EmptyState(icon: Icons.dashboard_outlined, title: 'Нет данных');
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primaryBlue,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                onPressed: _loadDashboard,
                tooltip: 'Обновить',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ColoredBox(
                color: AppColors.primaryBlue,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 72, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (user != null)
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    user.firstName[0],
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Добрый день, ${user.firstName}!',
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _getRoleLabel(user.role),
                                      style: AppTextStyles.label.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Главная',
              style: AppTextStyles.h3.copyWith(color: AppColors.white),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Статистика
                if (_data!['stats'] != null) ...[
                  FadeTransition(
                    opacity: _statsFade,
                    child: SlideTransition(
                      position: _statsSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Статистика', Icons.bar_chart_rounded),
                          const SizedBox(height: 12),
                          _buildStatsGrid(
                              _data!['stats'] as Map<String, dynamic>),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Посещаемость
                if (_data!['attendanceStats'] != null) ...[
                  FadeTransition(
                    opacity: _chartFade,
                    child: SlideTransition(
                      position: _chartSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            'Посещаемость за неделю',
                            Icons.how_to_reg_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildAttendanceChart(
                            _data!['attendanceStats'] as Map<String, dynamic>,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Объявления (admin → 'recentAnnouncements', student → 'announcements')
                Builder(builder: (_) {
                  final ann = (_data!['recentAnnouncements'] as List?)
                      ?? (_data!['announcements'] as List?);
                  if (ann == null || ann.isEmpty) return const SizedBox.shrink();
                  return FadeTransition(
                    opacity: _annFade,
                    child: SlideTransition(
                      position: _annSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            'Последние объявления',
                            Icons.campaign_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._buildAnnouncements(ann),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  );
                }),

                // Группы и предметы (преподаватель)
                if (_data!['groupsAndSubjects'] != null &&
                    (_data!['groupsAndSubjects'] as List).isNotEmpty) ...[
                  FadeTransition(
                    opacity: _gradesFade,
                    child: SlideTransition(
                      position: _gradesSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Мои группы', Icons.groups_rounded),
                          const SizedBox(height: 12),
                          ..._buildGroupsAndSubjects(
                              _data!['groupsAndSubjects'] as List),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Последние оценки (студент)
                if (_data!['recentGrades'] != null &&
                    (_data!['recentGrades'] as List).isNotEmpty) ...[
                  FadeTransition(
                    opacity: _gradesFade,
                    child: SlideTransition(
                      position: _gradesSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            'Последние оценки',
                            Icons.grade_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._buildRecentGrades(
                              _data!['recentGrades'] as List),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.h4),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final items = <(String, String, IconData, Color)>[];

    if (stats['totalStudents'] != null) {
      items.add(('Студентов', '${stats['totalStudents']}',
          Icons.people_rounded, AppColors.primaryBlue));
    }
    if (stats['totalTeachers'] != null) {
      items.add(('Преподавателей', '${stats['totalTeachers']}',
          Icons.person_rounded, AppColors.success));
    }
    if (stats['totalGroups'] != null) {
      items.add(('Групп', '${stats['totalGroups']}',
          Icons.group_rounded, AppColors.warning));
    }
    if (stats['groupsCount'] != null) {
      items.add(('Групп', '${stats['groupsCount']}',
          Icons.group_rounded, AppColors.primaryBlue));
    }
    if (stats['subjectsCount'] != null) {
      items.add(('Дисциплин', '${stats['subjectsCount']}',
          Icons.book_rounded, AppColors.success));
    }
    if (stats['todayClasses'] != null) {
      items.add(('Сегодня занятий', '${stats['todayClasses']}',
          Icons.schedule_rounded, AppColors.warning));
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final cols = min(items.length, w > 700 ? 4 : w > 460 ? 3 : 2);
        // Ratios keep card height >= 70px (42px icon + 28px padding) across all breakpoints
        final ratio = cols >= 4 ? 2.0 : 1.8;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: items
              .map(
                (item) => _GradientStatCard(
                  title: item.$1,
                  value: item.$2,
                  icon: item.$3,
                  color: item.$4,
                ),
              )
              .toList(),
        );
      },
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
          height: 110,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.gray500.withValues(alpha: 0.5),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Нет данных за эту неделю',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rate = (present / total * 100).round();

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: present.toDouble(),
                        color: AppColors.success,
                        title: '',
                        radius: 48,
                      ),
                      if (absent > 0)
                        PieChartSectionData(
                          value: absent.toDouble(),
                          color: AppColors.error,
                          title: '',
                          radius: 48,
                        ),
                      if (late > 0)
                        PieChartSectionData(
                          value: late.toDouble(),
                          color: AppColors.warning,
                          title: '',
                          radius: 48,
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rate%',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.primaryBlue),
                    ),
                    Text('явка', style: AppTextStyles.label),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('Присутствовали', present, AppColors.success),
                const SizedBox(height: 10),
                _legendItem('Отсутствовали', absent, AppColors.error),
                const SizedBox(height: 10),
                _legendItem('Опоздали', late, AppColors.warning),
                const Divider(height: 18),
                Text('Всего: $total записей', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(
          '$count',
          style: AppTextStyles.captionMedium.copyWith(color: color),
        ),
      ],
    );
  }

  List<Widget> _buildAnnouncements(List announcements) {
    return announcements.take(3).map((a) {
      final ann = a as Map<String, dynamic>;
      final isPinned = ann['isPinned'] == true;
      final accent = isPinned ? AppColors.warning : AppColors.primaryBlue;
      final accentLight = isPinned ? AppColors.warningLight : AppColors.lightBlue;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ann['title'] as String, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 3),
                    Text(
                      ann['content'] as String,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildGroupsAndSubjects(List entries) {
    final Map<String, Map<String, dynamic>> byGroup = {};
    for (final e in entries) {
      final entry = e as Map<String, dynamic>;
      final group = entry['group'] as Map<String, dynamic>?;
      final subject = entry['subject'] as Map<String, dynamic>?;
      if (group == null) continue;
      final gId = group['id'] as String;
      byGroup.putIfAbsent(gId, () => {'name': group['name'], 'subjects': <String>[]});
      if (subject != null) {
        final subjects = byGroup[gId]!['subjects'] as List<String>;
        final sName = subject['name'] as String? ?? '';
        if (!subjects.contains(sName)) subjects.add(sName);
      }
    }

    return byGroup.values.map((g) {
      final subjects = (g['subjects'] as List<String>).join(' · ');
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['name'] as String, style: AppTextStyles.bodyMedium),
                    if (subjects.isNotEmpty)
                      Text(
                        subjects,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
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
      final color = _gradeColor(value);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: AppTextStyles.h3.copyWith(color: color),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _gradeLabel(value),
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
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

  String _gradeLabel(int value) => switch (value) {
        5 => 'Отлично',
        4 => 'Хорошо',
        3 => 'Удовл.',
        _ => 'Неудовл.',
      };

  String _getRoleLabel(UserRole role) => switch (role) {
        UserRole.admin => 'Администратор',
        UserRole.teacher => 'Преподаватель',
        UserRole.student => 'Студент',
        UserRole.curator => 'Куратор',
      };
}

class _GradientStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _GradientStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
                  ),
                  Text(
                    title,
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.gray500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
