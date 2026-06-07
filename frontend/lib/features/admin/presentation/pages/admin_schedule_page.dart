import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  List<dynamic> _entries = [];
  List<dynamic> _groups = [];
  List<dynamic> _subjects = [];
  List<dynamic> _teachers = [];
  bool _loading = true;
  String? _filterGroupId;

  static const _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

  // Column widths for the timetable
  static const double _wTime = 108;
  static const double _wSubject = 200;
  static const double _wGroup = 100;
  static const double _wTeacher = 160;
  static const double _wRoom = 68;
  static const double _wActions = 48;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [schResp, grResp, subResp, usersResp] = await Future.wait([
        dioClient.dio.get(ApiConstants.schedule),
        dioClient.dio.get(ApiConstants.groups),
        dioClient.dio.get(ApiConstants.subjects),
        dioClient.dio.get(ApiConstants.users, queryParameters: {'role': 'TEACHER', 'limit': 100}),
      ]);
      setState(() {
        _entries = schResp.data['data'] as List;
        _groups = grResp.data['data'] as List;
        _subjects = subResp.data['data'] as List;
        _teachers = usersResp.data['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filterGroupId == null) return _entries;
    return _entries.where((e) => (e as Map)['groupId'] == _filterGroupId).toList();
  }

  Map<String, List<dynamic>> _groupByDay(List<dynamic> entries) {
    final map = <String, List<dynamic>>{};
    for (final day in _days) {
      map[day] = entries.where((e) => (e as Map)['dayOfWeek'] == day).toList()
        ..sort((a, b) {
          return ((a as Map)['startTime'] as String).compareTo((b as Map)['startTime'] as String);
        });
    }
    return map;
  }

  void _showEntryDialog({Map<String, dynamic>? existing}) {
    String? groupId = existing?['groupId'] as String?;
    String? subjectId = existing?['subjectId'] as String?;
    String? teacherId = existing?['teacherId'] as String?;
    String dayOfWeek = existing?['dayOfWeek'] as String? ?? 'MONDAY';
    final startCtrl = TextEditingController(text: existing?['startTime'] as String? ?? '09:00');
    final endCtrl = TextEditingController(text: existing?['endTime'] as String? ?? '10:30');
    final roomCtrl = TextEditingController(text: existing?['room'] as String?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
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
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(existing == null ? 'Добавить занятие' : 'Редактировать занятие', style: AppTextStyles.h4),
                ],
              ),
              const SizedBox(height: 20),
              _dropdown('Группа', _groups, groupId, (v) => setModal(() => groupId = v), (g) => g['name'] as String),
              const SizedBox(height: 12),
              _dropdown('Дисциплина', _subjects, subjectId, (v) => setModal(() => subjectId = v),
                  (s) => '${s['code']} — ${s['name']}'),
              const SizedBox(height: 12),
              _dropdown('Преподаватель', _teachers, teacherId, (v) => setModal(() => teacherId = v),
                  (t) => '${t['lastName']} ${t['firstName']}'),
              const SizedBox(height: 12),
              Text('День недели', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: dayOfWeek,
                decoration: const InputDecoration(isDense: true),
                items: _days.map((d) => DropdownMenuItem(value: d, child: Text(_dayName(d)))).toList(),
                onChanged: (v) => setModal(() => dayOfWeek = v ?? dayOfWeek),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Начало', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: startCtrl,
                          decoration: const InputDecoration(hintText: '09:00', isDense: true),
                          keyboardType: TextInputType.datetime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Конец', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: endCtrl,
                          decoration: const InputDecoration(hintText: '10:30', isDense: true),
                          keyboardType: TextInputType.datetime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Аудитория', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
              const SizedBox(height: 6),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(hintText: '101', isDense: true),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final data = {
                        'groupId': groupId,
                        'subjectId': subjectId,
                        'teacherId': teacherId,
                        'dayOfWeek': dayOfWeek,
                        'startTime': startCtrl.text.trim(),
                        'endTime': endCtrl.text.trim(),
                        if (roomCtrl.text.trim().isNotEmpty) 'room': roomCtrl.text.trim(),
                      };
                      if (existing == null) {
                        await dioClient.dio.post(ApiConstants.schedule, data: data);
                      } else {
                        await dioClient.dio.patch('${ApiConstants.schedule}/${existing['id']}', data: data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (_) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Ошибка сохранения. Проверьте данные.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(existing == null ? 'Добавить' : 'Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<dynamic> items, String? value, void Function(String?) onChanged,
      String Function(Map<String, dynamic>) nameOf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(isDense: true),
          hint: Text('Выберите $label'.toLowerCase()),
          items: items.cast<Map<String, dynamic>>().map((item) => DropdownMenuItem(
            value: item['id'] as String,
            child: Text(nameOf(item), overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить занятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: AppColors.error))),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    await dioClient.dio.delete('${ApiConstants.schedule}/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final byDay = _groupByDay(filtered);
    final hasEntries = _days.any((d) => (byDay[d] ?? []).isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Расписание', style: AppTextStyles.h3),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEntryDialog,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Занятие', style: AppTextStyles.button.copyWith(color: AppColors.white)),
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: !hasEntries
                      ? const EmptyState(
                          icon: Icons.calendar_today_outlined,
                          title: 'Занятий нет',
                          subtitle: 'Нажмите «Занятие» чтобы добавить',
                        )
                      : _buildScheduleTable(byDay),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.gray500),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterGroupId,
              decoration: const InputDecoration(labelText: 'Фильтр по группе', isDense: true),
              hint: const Text('Все группы'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все группы')),
                ..._groups.cast<Map<String, dynamic>>().map((g) => DropdownMenuItem(
                  value: g['id'] as String,
                  child: Text(g['name'] as String),
                )),
              ],
              onChanged: (v) => setState(() => _filterGroupId = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable(Map<String, List<dynamic>> byDay) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AppCard(
          padding: EdgeInsets.zero,
          borderRadius: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                ..._buildTableBody(byDay),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          _headerCell('Время', _wTime, icon: Icons.access_time_outlined),
          _vDivider(),
          _headerCell('Дисциплина', _wSubject, icon: Icons.book_outlined),
          _vDivider(),
          _headerCell('Группа', _wGroup, icon: Icons.group_outlined),
          _vDivider(),
          _headerCell('Преподаватель', _wTeacher, icon: Icons.person_outline),
          _vDivider(),
          _headerCell('Ауд.', _wRoom, icon: Icons.meeting_room_outlined),
          const SizedBox(width: _wActions),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.15));

  Widget _headerCell(String text, double width, {required IconData icon}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              text,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTableBody(Map<String, List<dynamic>> byDay) {
    final rows = <Widget>[];
    bool first = true;

    for (final day in _days) {
      final entries = byDay[day] ?? [];
      if (entries.isEmpty) continue;

      rows.add(_buildDayBanner(day, entries.length, isFirst: first));
      first = false;

      for (int i = 0; i < entries.length; i++) {
        rows.add(_buildDataRow(entries[i] as Map<String, dynamic>, isEven: i.isEven));
      }
    }

    return rows;
  }

  Widget _buildDayBanner(String day, int count, {bool isFirst = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        border: Border(
          top: BorderSide(color: isFirst ? Colors.transparent : AppColors.gray200),
          bottom: const BorderSide(color: AppColors.gray200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _dayName(day).toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count пар',
              style: AppTextStyles.label.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> entry, {bool isEven = false}) {
    final subject = entry['subject'] as Map?;
    final group = entry['group'] as Map?;
    final teacher = entry['teacher'] as Map?;
    final room = entry['room'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? AppColors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time cell
          SizedBox(
            width: _wTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['startTime'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
                  ),
                  Text(
                    entry['endTime'] as String,
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.gray100),
          // Subject
          SizedBox(
            width: _wSubject,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Text(
                subject?['name'] as String? ?? '—',
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.gray100),
          // Group
          SizedBox(
            width: _wGroup,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  group?['name'] as String? ?? '—',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.gray100),
          // Teacher
          SizedBox(
            width: _wTeacher,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: teacher != null
                  ? Text(
                      '${teacher['lastName']} ${(teacher['firstName'] as String)[0]}.',
                      style: AppTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text('—', style: AppTextStyles.caption),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.gray100),
          // Room
          SizedBox(
            width: _wRoom,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: room != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(room, style: AppTextStyles.captionMedium, textAlign: TextAlign.center),
                    )
                  : Text('—', style: AppTextStyles.caption),
            ),
          ),
          // Actions
          SizedBox(
            width: _wActions,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 16, color: AppColors.gray500),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {
                if (v == 'edit') _showEntryDialog(existing: entry);
                if (v == 'delete') _delete(entry['id'] as String);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(String d) => switch (d) {
        'MONDAY' => 'Понедельник',
        'TUESDAY' => 'Вторник',
        'WEDNESDAY' => 'Среда',
        'THURSDAY' => 'Четверг',
        'FRIDAY' => 'Пятница',
        'SATURDAY' => 'Суббота',
        _ => d,
      };
}
