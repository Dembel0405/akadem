import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminGroupsPage extends StatefulWidget {
  const AdminGroupsPage({super.key});

  @override
  State<AdminGroupsPage> createState() => _AdminGroupsPageState();
}

class _AdminGroupsPageState extends State<AdminGroupsPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _groups = [];
  List<dynamic> _specialties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [gResp, sResp] = await Future.wait([
        dioClient.dio.get(ApiConstants.groups),
        dioClient.dio.get(ApiConstants.specialties),
      ]);
      setState(() {
        _groups = gResp.data['data'] as List;
        _specialties = sResp.data['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showGroupDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String?);
    final yearCtrl = TextEditingController(text: existing?['year']?.toString() ?? DateTime.now().year.toString());
    String? selectedSpecialtyId = existing?['specialtyId'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              Text(existing == null ? 'Создать группу' : 'Редактировать группу', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              AppTextField(label: 'Название группы', hint: 'ИС-24-1', controller: nameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Год поступления', hint: '2024', controller: yearCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Text('Специальность', style: AppTextStyles.captionMedium.copyWith(color: AppColors.gray700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedSpecialtyId,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('Выберите специальность'),
                items: _specialties.cast<Map<String, dynamic>>().map((s) => DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text('${s['code']} — ${s['name']}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedSpecialtyId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      if (existing == null) {
                        await dioClient.dio.post(ApiConstants.groups, data: {
                          'name': nameCtrl.text.trim(),
                          'year': int.tryParse(yearCtrl.text) ?? DateTime.now().year,
                          'specialtyId': selectedSpecialtyId,
                        });
                      } else {
                        await dioClient.dio.patch('${ApiConstants.groups}/${existing['id']}', data: {
                          'name': nameCtrl.text.trim(),
                          'year': int.tryParse(yearCtrl.text),
                          'specialtyId': selectedSpecialtyId,
                        });
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (_) {}
                  },
                  child: Text(existing == null ? 'Создать' : 'Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialtyDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String?);
    final codeCtrl = TextEditingController(text: existing?['code'] as String?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
            Text(existing == null ? 'Новая специальность' : 'Редактировать специальность', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            AppTextField(label: 'Название', hint: 'Информационные системы', controller: nameCtrl),
            const SizedBox(height: 12),
            AppTextField(label: 'Код специальности', hint: '09.02.07', controller: codeCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    if (existing == null) {
                      await dioClient.dio.post(ApiConstants.specialties, data: {
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim(),
                      });
                    } else {
                      await dioClient.dio.patch('${ApiConstants.specialties}/${existing['id']}', data: {
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim(),
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                    _load();
                  } catch (_) {}
                },
                child: Text(existing == null ? 'Создать' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Группы и специальности', style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primaryBlue,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.buttonSmall,
          tabs: const [Tab(text: 'Группы'), Tab(text: 'Специальности')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabs.index == 0) _showGroupDialog();
          else _showSpecialtyDialog();
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _loading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabs,
              children: [_buildGroupsTab(), _buildSpecialtiesTab()],
            ),
    );
  }

  Widget _buildGroupsTab() {
    if (_groups.isEmpty) {
      return const EmptyState(icon: Icons.group_outlined, title: 'Групп нет', subtitle: 'Нажмите + чтобы создать');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final g = _groups[i] as Map<String, dynamic>;
        final specialty = g['specialty'] as Map<String, dynamic>?;
        final count = (g['_count'] as Map?)?['students'] as int? ?? 0;
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.group_outlined, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['name'] as String, style: AppTextStyles.bodyMedium),
                    if (specialty != null)
                      Text(specialty['name'] as String, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('$count ст.', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.gray500),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.error))),
                ],
                onSelected: (v) {
                  if (v == 'edit') _showGroupDialog(existing: g);
                  if (v == 'delete') _deleteGroup(g['id'] as String);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialtiesTab() {
    if (_specialties.isEmpty) {
      return const EmptyState(icon: Icons.school_outlined, title: 'Специальностей нет');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _specialties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final s = _specialties[i] as Map<String, dynamic>;
        final groupCount = (s['_count'] as Map?)?['groups'] as int? ?? 0;
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bookmark_outlined, color: AppColors.gray500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'] as String, style: AppTextStyles.bodyMedium),
                    Text(s['code'] as String, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text('$groupCount гр.', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.gray500),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.error))),
                ],
                onSelected: (v) {
                  if (v == 'edit') _showSpecialtyDialog(existing: s);
                  if (v == 'delete') _deleteSpecialty(s['id'] as String);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteGroup(String id) async {
    final confirmed = await _confirm('Удалить группу?', 'Группа будет деактивирована.');
    if (!confirmed) return;
    await dioClient.dio.delete('${ApiConstants.groups}/$id');
    _load();
  }

  Future<void> _deleteSpecialty(String id) async {
    final confirmed = await _confirm('Удалить специальность?', 'Специальность будет деактивирована.');
    if (!confirmed) return;
    await dioClient.dio.delete('${ApiConstants.specialties}/$id');
    _load();
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }
}
