import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';

class CuratorDashboardPage extends StatefulWidget {
  const CuratorDashboardPage({super.key});

  @override
  State<CuratorDashboardPage> createState() => _CuratorDashboardPageState();
}

class _CuratorDashboardPageState extends State<CuratorDashboardPage> {
  Map<String, dynamic>? _group;
  Map<String, dynamic>? _attendanceStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Find the group this curator manages
      final userData = tokenStorage.getUser();
      final userId = userData?['id']?.toString();

      final groupsResp = await dioClient.dio.get(ApiConstants.groups);
      final allGroups = (groupsResp.data['data'] as List).cast<Map<String, dynamic>>();

      final myGroup = allGroups.firstWhere(
        (g) => g['curatorId']?.toString() == userId,
        orElse: () => <String, dynamic>{},
      );

      if (myGroup.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final groupId = myGroup['id'] as String;
      final attResp = await dioClient.dio.get('${ApiConstants.attendance}/group/$groupId/stats');

      setState(() {
        _group = myGroup;
        _attendanceStats = attResp.data['data'] as Map<String, dynamic>;
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
        title: Text('Дашборд куратора', style: AppTextStyles.h3),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load)],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _group == null
              ? const Center(child: Text('Группа не назначена'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGroupCard(),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      if (_attendanceStats != null) _buildAttendanceSummary(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGroupCard() {
    final g = _group!;
    final specialty = g['specialty'] as Map?;
    final studentCount = (g['_count'] as Map?)?['students'] as int? ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_outlined, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['name'] as String, style: AppTextStyles.h3),
                    if (specialty != null)
                      Text(specialty['name'] as String, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$studentCount', style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue)),
                  Text('студентов', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          if (g['year'] != null) ...[
            const Divider(height: 20),
            Text('Год поступления: ${g['year']}', style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final groupId = _group!['id'] as String;
    final actions = [
      _ActionItem('Студенты', Icons.people_outlined, AppColors.primaryBlue, '/curator/students/$groupId'),
      _ActionItem('Посещаемость', Icons.how_to_reg_outlined, AppColors.success, '/curator/attendance/$groupId'),
      _ActionItem('Успеваемость', Icons.grade_outlined, AppColors.warning, '/curator/grades/$groupId'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Быстрые действия', style: AppTextStyles.h4),
        const SizedBox(height: 10),
        Row(
          children: actions.asMap().entries.map((e) {
            final a = e.value;
            final isLast = e.key == actions.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: GestureDetector(
                  onTap: () => context.push(a.route),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: a.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.icon, size: 20, color: a.color),
                        ),
                        const SizedBox(height: 8),
                        Text(a.label, style: AppTextStyles.captionMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    final stats = _attendanceStats!;
    final present = (stats['PRESENT'] ?? 0) as int;
    final absent = (stats['ABSENT'] ?? 0) as int;
    final late = (stats['LATE'] ?? 0) as int;
    final excused = (stats['EXCUSED'] ?? 0) as int;
    final total = present + absent + late + excused;
    if (total == 0) return const SizedBox.shrink();

    final rate = (present / total * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Посещаемость группы', style: AppTextStyles.h4)),
              Text('$rate%', style: AppTextStyles.h3.copyWith(color: _rateColor(rate))),
            ],
          ),
          const SizedBox(height: 12),
          _attRow('Присутствуют', present, total, AppColors.success),
          _attRow('Отсутствуют', absent, total, AppColors.error),
          _attRow('Опоздали', late, total, AppColors.warning),
          _attRow('Уваж. причина', excused, total, AppColors.info),
        ],
      ),
    );
  }

  Widget _attRow(String label, int value, int total, Color color) {
    final ratio = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.gray100,
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: AppTextStyles.captionMedium),
        ],
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 85) return AppColors.success;
    if (rate >= 70) return AppColors.warning;
    return AppColors.error;
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionItem(this.label, this.icon, this.color, this.route);
}
