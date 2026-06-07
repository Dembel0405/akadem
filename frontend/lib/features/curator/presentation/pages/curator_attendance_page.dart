import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class CuratorAttendancePage extends StatefulWidget {
  final String groupId;

  const CuratorAttendancePage({super.key, required this.groupId});

  @override
  State<CuratorAttendancePage> createState() => _CuratorAttendancePageState();
}

class _CuratorAttendancePageState extends State<CuratorAttendancePage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await dioClient.dio.get('${ApiConstants.attendance}/group/${widget.groupId}/stats');
      setState(() {
        _stats = resp.data['data'] as Map<String, dynamic>;
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
        title: Text('Посещаемость группы', style: AppTextStyles.h3),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load)],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _stats == null
              ? const Center(child: Text('Нет данных'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Общая посещаемость группы', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          sections: [
                            PieChartSectionData(value: present.toDouble(), color: AppColors.success, title: '', radius: 50),
                            PieChartSectionData(value: absent.toDouble(), color: AppColors.error, title: '', radius: 50),
                            PieChartSectionData(value: late.toDouble(), color: AppColors.warning, title: '', radius: 50),
                            PieChartSectionData(value: excused.toDouble(), color: AppColors.info, title: '', radius: 50),
                          ],
                          centerSpaceRadius: 32,
                          sectionsSpace: 2,
                        )),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$rate%', style: AppTextStyles.h2),
                            Text('посещ.', style: AppTextStyles.label),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendRow('Присутствовали', present, total, AppColors.success),
                        _legendRow('Отсутствовали', absent, total, AppColors.error),
                        _legendRow('Опоздали', late, total, AppColors.warning),
                        _legendRow('Уваж. причина', excused, total, AppColors.info),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Всего записей', style: AppTextStyles.caption),
                            Text('$total', style: AppTextStyles.captionMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Оценка посещаемости', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _rateColor(rate).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _rateColor(rate).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_rateIcon(rate), color: _rateColor(rate), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_rateLabel(rate), style: AppTextStyles.bodyMedium.copyWith(color: _rateColor(rate))),
                          Text(_rateAdvice(rate), style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String label, int value, int total, Color color) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Color _rateColor(int rate) {
    if (rate >= 85) return AppColors.success;
    if (rate >= 70) return AppColors.warning;
    return AppColors.error;
  }

  IconData _rateIcon(int rate) {
    if (rate >= 85) return Icons.thumb_up_outlined;
    if (rate >= 70) return Icons.warning_amber_outlined;
    return Icons.warning_outlined;
  }

  String _rateLabel(int rate) {
    if (rate >= 85) return 'Хорошая посещаемость';
    if (rate >= 70) return 'Удовлетворительная посещаемость';
    return 'Низкая посещаемость — требует внимания';
  }

  String _rateAdvice(int rate) {
    if (rate >= 85) return 'Группа демонстрирует высокую дисциплину.';
    if (rate >= 70) return 'Есть студенты, которые часто пропускают занятия.';
    return 'Рекомендуется провести беседу со студентами.';
  }
}
