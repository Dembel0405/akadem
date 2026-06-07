import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

/// Экран отметки посещаемости для преподавателя.
/// groupId передаётся через параметры роутера.
class MarkAttendancePage extends StatefulWidget {
  final String groupId;

  const MarkAttendancePage({super.key, required this.groupId});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  List<dynamic> _students = [];
  List<dynamic> _scheduleEntries = [];
  String? _selectedEntryId;
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Статус каждого студента: studentId → AttendanceStatus
  final Map<String, String> _statuses = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final [studentsResp, scheduleResp] = await Future.wait([
        dioClient.dio.get('${ApiConstants.groups}/${widget.groupId}'),
        dioClient.dio.get('${ApiConstants.schedule}/group/${widget.groupId}'),
      ]);

      final students = (studentsResp.data['data']['students'] as List);
      final entries = (scheduleResp.data['data'] as List);

      // Инициализируем всех студентов как PRESENT
      for (final s in students) {
        _statuses[(s as Map)['id'] as String] = 'PRESENT';
      }

      // Находим запись на сегодня
      final todayDay = _dayOfWeek(_date.weekday);
      final todayEntry = (entries as List).cast<Map<String, dynamic>>().firstWhere(
        (e) => e['dayOfWeek'] == todayDay,
        orElse: () => entries.isNotEmpty ? entries.first as Map<String, dynamic> : {},
      );

      setState(() {
        _students = students;
        _scheduleEntries = entries;
        _selectedEntryId = todayEntry.isNotEmpty ? todayEntry['id'] as String? : null;
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Не удалось загрузить данные'; _loading = false; });
    }
  }

  Future<void> _save() async {
    if (_selectedEntryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите занятие')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final records = _statuses.entries.map((e) => {
        'studentId': e.key,
        'status': e.value,
      }).toList();

      await dioClient.dio.post('${ApiConstants.attendance}/mark', data: {
        'scheduleEntryId': _selectedEntryId,
        'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        'records': records,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Посещаемость сохранена'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сохранения'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Отметить посещаемость', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Сохранить', style: AppTextStyles.buttonSmall.copyWith(color: AppColors.primaryBlue)),
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildStudentList()),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Выбор занятия
          if (_scheduleEntries.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: _selectedEntryId,
              decoration: const InputDecoration(labelText: 'Занятие', isDense: true),
              items: _scheduleEntries.cast<Map<String, dynamic>>().map((e) {
                final subject = e['subject'] as Map;
                final day = _dayName(e['dayOfWeek'] as String);
                return DropdownMenuItem(
                  value: e['id'] as String,
                  child: Text('$day — ${subject['name']}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedEntryId = v),
            ),
            const SizedBox(height: 10),
          ],

          // Выбор даты
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray200),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.gray500),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                    style: AppTextStyles.body,
                  ),
                  const Spacer(),
                  Text('Изменить', style: AppTextStyles.caption.copyWith(color: AppColors.primaryBlue)),
                ],
              ),
            ),
          ),

          // Быстрые кнопки "Все присутствуют / Все отсутствуют"
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Все присутствуют',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  onPressed: () => setState(() {
                    for (final id in _statuses.keys) _statuses[id] = 'PRESENT';
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Все отсутствуют',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.small,
                  onPressed: () => setState(() {
                    for (final id in _statuses.keys) _statuses[id] = 'ABSENT';
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final presentCount = _statuses.values.where((s) => s == 'PRESENT').length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.gray50,
          child: Row(
            children: [
              Text('Студентов: ${_students.length}', style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('$presentCount присут.', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              const SizedBox(width: 8),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('${_students.length - presentCount} отсут.', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _students.length,
            itemBuilder: (_, i) => _buildStudentRow(_students[i] as Map<String, dynamic>, i),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student, int index) {
    final id = student['id'] as String;
    final status = _statuses[id] ?? 'PRESENT';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Номер
            SizedBox(
              width: 28,
              child: Text('${index + 1}', style: AppTextStyles.caption, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            // Имя
            Expanded(
              child: Text(
                '${student['lastName']} ${student['firstName']} ${student['middleName'] ?? ''}',
                style: AppTextStyles.body,
              ),
            ),
            const SizedBox(width: 8),
            // Кнопки статуса
            _statusButton(id, 'PRESENT', Icons.check, AppColors.success, status),
            const SizedBox(width: 4),
            _statusButton(id, 'LATE', Icons.access_time, AppColors.warning, status),
            const SizedBox(width: 4),
            _statusButton(id, 'ABSENT', Icons.close, AppColors.error, status),
            const SizedBox(width: 4),
            _statusButton(id, 'EXCUSED', Icons.note_alt_outlined, AppColors.info, status),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String studentId, String statusValue, IconData icon, Color color, String current) {
    final isSelected = current == statusValue;
    return GestureDetector(
      onTap: () => setState(() => _statuses[studentId] = statusValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.gray50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : AppColors.gray200),
        ),
        child: Icon(icon, size: 16, color: isSelected ? AppColors.white : AppColors.gray500),
      ),
    );
  }

  String _dayOfWeek(int weekday) {
    const map = {1: 'MONDAY', 2: 'TUESDAY', 3: 'WEDNESDAY', 4: 'THURSDAY', 5: 'FRIDAY', 6: 'SATURDAY', 7: 'SUNDAY'};
    return map[weekday] ?? 'MONDAY';
  }

  String _dayName(String day) => switch (day) {
        'MONDAY' => 'Пн',
        'TUESDAY' => 'Вт',
        'WEDNESDAY' => 'Ср',
        'THURSDAY' => 'Чт',
        'FRIDAY' => 'Пт',
        'SATURDAY' => 'Сб',
        _ => day,
      };
}
