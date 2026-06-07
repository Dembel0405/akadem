import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class CuratorStudentsPage extends StatefulWidget {
  final String groupId;

  const CuratorStudentsPage({super.key, required this.groupId});

  @override
  State<CuratorStudentsPage> createState() => _CuratorStudentsPageState();
}

class _CuratorStudentsPageState extends State<CuratorStudentsPage> {
  List<dynamic> _students = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await dioClient.dio.get('${ApiConstants.groups}/${widget.groupId}');
      setState(() {
        _students = (resp.data['data']['students'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _students;
    final q = _search.toLowerCase();
    return _students.where((s) {
      final student = s as Map<String, dynamic>;
      final name = '${student['lastName']} ${student['firstName']} ${student['middleName'] ?? ''}'.toLowerCase();
      return name.contains(q) || (student['email'] as String).toLowerCase().contains(q);
    }).toList();
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(
                      (student['firstName'] as String)[0].toUpperCase(),
                      style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student['lastName']} ${student['firstName']} ${student['middleName'] ?? ''}',
                          style: AppTextStyles.h4,
                        ),
                        Text(student['email'] as String, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow(Icons.email_outlined, 'Email', student['email'] as String),
              if (student['phone'] != null)
                _detailRow(Icons.phone_outlined, 'Телефон', student['phone'] as String),
              _detailRow(Icons.person_outlined, 'Статус', 'Студент'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray500),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Студенты группы', style: AppTextStyles.h3),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load)],
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Поиск студента...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray500),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.gray200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_students.length} ст.',
                          style: AppTextStyles.captionMedium.copyWith(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const EmptyState(icon: Icons.person_outlined, title: 'Студентов нет')
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final s = _filtered[i] as Map<String, dynamic>;
                            return AppCard(
                              onTap: () => _showStudentDetails(s),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.lightBlue,
                                    child: Text(
                                      (s['firstName'] as String)[0].toUpperCase(),
                                      style: AppTextStyles.captionMedium.copyWith(color: AppColors.primaryBlue),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${s['lastName']} ${s['firstName']} ${s['middleName'] ?? ''}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        Text(s['email'] as String, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
