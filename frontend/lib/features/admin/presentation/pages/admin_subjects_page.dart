import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminSubjectsPage extends StatefulWidget {
  const AdminSubjectsPage({super.key});

  @override
  State<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends State<AdminSubjectsPage> {
  List<dynamic> _subjects = [];
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
      final resp = await dioClient.dio.get(ApiConstants.subjects);
      setState(() {
        _subjects = resp.data['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _subjects;
    final q = _search.toLowerCase();
    return _subjects.where((s) {
      final sub = s as Map<String, dynamic>;
      return (sub['name'] as String).toLowerCase().contains(q) ||
          (sub['code'] as String).toLowerCase().contains(q);
    }).toList();
  }

  void _showSubjectDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String?);
    final codeCtrl = TextEditingController(text: existing?['code'] as String?);
    final descCtrl = TextEditingController(text: existing?['description'] as String?);
    final hoursCtrl = TextEditingController(text: existing?['hoursTotal']?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
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
                  child: const Icon(Icons.book_outlined, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(existing == null ? 'Новая дисциплина' : 'Редактировать дисциплину', style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(label: 'Название', hint: 'Математика', controller: nameCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Код', hint: 'MATH.01', controller: codeCtrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Часов всего',
                    hint: '72',
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Описание (необязательно)', hint: 'Высшая математика...', controller: descCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final hours = int.tryParse(hoursCtrl.text.trim());

                  if (name.isEmpty || code.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Заполните название и код')),
                      );
                    }
                    return;
                  }
                  if (hours == null || hours < 1) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите корректное количество часов (мин. 1)')),
                      );
                    }
                    return;
                  }

                  try {
                    final data = {
                      'name': name,
                      'code': code,
                      'hoursTotal': hours,
                      if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                    };
                    if (existing == null) {
                      await dioClient.dio.post(ApiConstants.subjects, data: data);
                    } else {
                      await dioClient.dio.patch('${ApiConstants.subjects}/${existing['id']}', data: data);
                    }
                    if (mounted) Navigator.pop(context);
                    _load();
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ошибка сохранения. Проверьте данные.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(existing == null ? 'Создать' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить дисциплину?'),
        content: const Text('Дисциплина будет деактивирована.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    await dioClient.dio.delete('${ApiConstants.subjects}/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Дисциплины', style: AppTextStyles.h3),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubjectDialog,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Добавить', style: AppTextStyles.button.copyWith(color: AppColors.white)),
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию или коду...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray500),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text('${_filtered.length} дисциплин', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const EmptyState(icon: Icons.book_outlined, title: 'Дисциплин нет', subtitle: 'Нажмите «Добавить»')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = _filtered[i] as Map<String, dynamic>;
                            final hours = s['hoursTotal'] as int?;
                            return AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.book_outlined, color: AppColors.primaryBlue, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'] as String, style: AppTextStyles.bodyMedium),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            _chip(s['code'] as String, AppColors.primaryBlue),
                                            if (hours != null) ...[
                                              const SizedBox(width: 6),
                                              _chip('$hours ч.', AppColors.gray500),
                                            ],
                                          ],
                                        ),
                                        if (s['description'] != null && (s['description'] as String).isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              s['description'] as String,
                                              style: AppTextStyles.caption,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.gray500),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.error))),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'edit') _showSubjectDialog(existing: s);
                                      if (v == 'delete') _delete(s['id'] as String);
                                    },
                                  ),
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
