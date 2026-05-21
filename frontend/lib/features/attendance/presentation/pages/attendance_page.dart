import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
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
      final response = await dioClient.dio.get('${ApiConstants.attendance}/my');
      setState(() {
        _data = response.data['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить посещаемость'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Моя посещаемость', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _data == null || (_data!['records'] as List).isEmpty
                  ? const EmptyState(
                      icon: Icons.how_to_reg_outlined,
                      title: 'Нет записей',
                      subtitle: 'Посещаемость ещё не отмечалась',
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final stats = _data!['stats'] as Map<String, dynamic>;
    final records = _data!['records'] as List;
    final total = stats['total'] as int;
    final present = stats['PRESENT'] as int? ?? 0;
    final attendanceRate = total > 0 ? (present / total * 100).round() : 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Статистика сверху
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Общая статистика', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: PieChart(PieChartData(
                        sections: [
                          PieChartSectionData(value: present.toDouble(), color: AppColors.success, title: '', radius: 40),
                          PieChartSectionData(
                            value: (total - present).toDouble(),
                            color: AppColors.gray100,
                            title: '',
                            radius: 40,
                          ),
                        ],
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      )),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$attendanceRate%', style: AppTextStyles.h1.copyWith(color: _rateColor(attendanceRate))),
                        Text('посещаемость', style: AppTextStyles.caption),
                        const SizedBox(height: 12),
                        _statRow('Всего занятий', total, AppColors.gray700),
                        _statRow('Присутствовал', present, AppColors.success),
                        _statRow('Отсутствовал', stats['ABSENT'] as int? ?? 0, AppColors.error),
                        _statRow('Опоздал', stats['LATE'] as int? ?? 0, AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('История посещаемости', style: AppTextStyles.h4),
        const SizedBox(height: 12),

        ...records.take(30).map((r) => _buildRecord(r as Map<String, dynamic>)),
      ],
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text('$value', style: AppTextStyles.captionMedium),
        ],
      ),
    );
  }

  Widget _buildRecord(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final entry = record['scheduleEntry'] as Map<String, dynamic>;
    final subject = entry['subject'] as Map<String, dynamic>;
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject['name'] as String, style: AppTextStyles.bodyMedium),
                  Text(_formatDate(record['date'] as String), style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_statusLabel(status), style: AppTextStyles.label.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'PRESENT' => AppColors.success,
        'ABSENT' => AppColors.error,
        'LATE' => AppColors.warning,
        'EXCUSED' => AppColors.info,
        _ => AppColors.gray500,
      };

  String _statusLabel(String status) => switch (status) {
        'PRESENT' => 'Присутствовал',
        'ABSENT' => 'Отсутствовал',
        'LATE' => 'Опоздал',
        'EXCUSED' => 'Уваж. причина',
        _ => status,
      };

  Color _rateColor(int rate) {
    if (rate >= 90) return AppColors.success;
    if (rate >= 70) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
