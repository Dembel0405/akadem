import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _listCtrl;
  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _load();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  void _buildAnims() {
    final count = _items.length.clamp(0, 15);
    final fades = <Animation<double>>[];
    final slides = <Animation<Offset>>[];
    for (var i = 0; i < count; i++) {
      final start = (i * 0.07).clamp(0.0, 0.72);
      // Clamp both ends to 1.0 to prevent Interval assertion
      final fadeEnd = (start + 0.35).clamp(0.0, 1.0);
      final slideEnd = (start + 0.40).clamp(0.0, 1.0);
      fades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(start, fadeEnd, curve: Curves.easeIn),
          ),
        ),
      );
      slides.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(start, slideEnd, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
    _fadeAnims
      ..clear()
      ..addAll(fades);
    _slideAnims
      ..clear()
      ..addAll(slides);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await dioClient.dio
          .get(ApiConstants.announcements, queryParameters: {'limit': 100});
      final rawData = resp.data;
      final List<dynamic> items = (rawData is Map && rawData['data'] is List)
          ? rawData['data'] as List<dynamic>
          : [];
      setState(() {
        _items = items;
        _loading = false;
      });
      _buildAnims();
      _listCtrl
        ..reset()
        ..forward();
    } catch (_) {
      setState(() {
        _error = 'Не удалось загрузить объявления';
        _loading = false;
      });
    }
  }

  void _showDialog({Map<String, dynamic>? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?['title'] as String?);
    final contentCtrl =
        TextEditingController(text: existing?['content'] as String?);
    bool isPinned = existing?['isPinned'] as bool? ?? false;

    final List<String> targetRoles = existing != null
        ? List<String>.from(existing['targetRoles'] as List? ?? [])
        : ['ALL'];

    const roles = [
      ('ALL', 'Все пользователи', Icons.people_outline),
      ('ADMINS', 'Администраторы', Icons.admin_panel_settings_outlined),
      ('TEACHERS', 'Преподаватели', Icons.school_outlined),
      ('STUDENTS', 'Студенты', Icons.person_outline),
      ('CURATORS', 'Кураторы', Icons.supervisor_account_outlined),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      existing == null
                          ? 'Новое объявление'
                          : 'Редактировать объявление',
                      style: AppTextStyles.h4,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Заголовок',
                  hint: 'Важное сообщение',
                  controller: titleCtrl,
                ),
                const SizedBox(height: 12),
                Text(
                  'Текст объявления',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.gray700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Введите текст...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Аудитория',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.gray700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: roles.map((r) {
                    final selected = targetRoles.contains(r.$1);
                    return GestureDetector(
                      onTap: () => setModal(() {
                        if (selected) {
                          targetRoles.remove(r.$1);
                        } else {
                          targetRoles.add(r.$1);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.lightBlue : AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.gray200,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              r.$3,
                              size: 14,
                              color: selected
                                  ? AppColors.primaryBlue
                                  : AppColors.gray500,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              r.$2,
                              style: AppTextStyles.captionMedium.copyWith(
                                color: selected
                                    ? AppColors.primaryBlue
                                    : AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setModal(() => isPinned = !isPinned),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isPinned ? AppColors.warningLight : AppColors.gray50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isPinned ? AppColors.warning : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.push_pin_rounded,
                          size: 18,
                          color: isPinned ? AppColors.warning : AppColors.gray500,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Закрепить объявление',
                          style: AppTextStyles.body.copyWith(
                            color: isPinned ? AppColors.warning : AppColors.gray700,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isPinned,
                          onChanged: (v) => setModal(() => isPinned = v),
                          activeColor: AppColors.warning,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().length < 3) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Заголовок: минимум 3 символа'),
                          ),
                        );
                        return;
                      }
                      if (contentCtrl.text.trim().length < 10) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Текст: минимум 10 символов'),
                          ),
                        );
                        return;
                      }
                      if (targetRoles.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Выберите хотя бы одну аудиторию'),
                          ),
                        );
                        return;
                      }
                      try {
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'content': contentCtrl.text.trim(),
                          'isPinned': isPinned,
                          'targetRoles': targetRoles,
                        };
                        if (existing == null) {
                          await dioClient.dio
                              .post(ApiConstants.announcements, data: data);
                        } else {
                          await dioClient.dio.patch(
                            '${ApiConstants.announcements}/${existing['id']}',
                            data: data,
                          );
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
                    child: Text(existing == null ? 'Опубликовать' : 'Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить объявление?'),
            content: const Text('Это действие нельзя отменить.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Удалить',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await dioClient.dio.delete('${ApiConstants.announcements}/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Объявления', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDialog,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text(
          'Создать',
          style: AppTextStyles.button.copyWith(color: AppColors.white),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? const LoadingIndicator()
            : _error != null
                ? ErrorView(
                    message: _error!,
                    onRetry: _load,
                  )
                : _items.isEmpty
                    ? const EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'Объявлений нет',
                        subtitle: 'Нажмите «Создать», чтобы добавить',
                      )
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final card = _buildCard(_items[i] as Map<String, dynamic>);
        if (i >= _fadeAnims.length) return card;
        return FadeTransition(
          opacity: _fadeAnims[i],
          child: SlideTransition(position: _slideAnims[i], child: card),
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isPinned = item['isPinned'] as bool? ?? false;
    final roles = (item['targetRoles'] as List?)?.cast<String>() ?? <String>[];
    final author = item['author'] as Map<String, dynamic>?;
    final accent = isPinned ? AppColors.warning : AppColors.primaryBlue;
    final accentLight = isPinned ? AppColors.warningLight : AppColors.lightBlue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: accent),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 10, right: 6),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                    size: 17,
                    color: accent,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? '',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: AppColors.gray500,
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Редактировать'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Удалить',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (v) {
                              if (v == 'edit') _showDialog(existing: item);
                              if (v == 'delete') _delete(item['id'] as String);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['content'] as String? ?? '',
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Wrap(
                            spacing: 4,
                            children: roles
                                .map(
                                  (r) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _roleName(r),
                                      style: AppTextStyles.label
                                          .copyWith(color: AppColors.gray700),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const Spacer(),
                          if (author != null)
                            Text(
                              _shortAuthorName(author),
                              style: AppTextStyles.label,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortAuthorName(Map<String, dynamic> author) {
    final last = author['lastName'] as String? ?? '';
    final first = (author['firstName'] as String?) ?? '';
    if (first.isEmpty) return last;
    return '$last ${first[0]}.';
  }

  String _roleName(String r) => switch (r) {
        'ALL' => 'Все',
        'ADMINS' => 'Администраторы',
        'TEACHERS' => 'Преподаватели',
        'STUDENTS' => 'Студенты',
        'CURATORS' => 'Кураторы',
        _ => r,
      };
}
