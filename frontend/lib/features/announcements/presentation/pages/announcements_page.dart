import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _listCtrl;
  List<Animation<double>> _fadeAnims = [];
  List<Animation<Offset>> _slideAnims = [];

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
    final count = _items.length.clamp(0, 12);
    final fades = <Animation<double>>[];
    final slides = <Animation<Offset>>[];
    for (var i = 0; i < count; i++) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      // Both end values clamped to 1.0 to prevent Interval assertion
      final fadeEnd = (start + 0.38).clamp(0.0, 1.0);
      final slideEnd = (start + 0.44).clamp(0.0, 1.0);
      fades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(start, fadeEnd, curve: Curves.easeIn),
          ),
        ),
      );
      slides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.16),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(start, slideEnd, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
    _fadeAnims = fades;
    _slideAnims = slides;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await dioClient.dio.get(ApiConstants.announcements);
      final rawData = response.data;
      final List<dynamic> items;
      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List<dynamic>;
      } else {
        items = [];
      }
      setState(() {
        _items = items;
        _loading = false;
      });
      _buildAnims();
      _listCtrl
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить объявления';
        _loading = false;
      });
    }
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
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _loading
            ? const LoadingIndicator(key: ValueKey('loading'))
            : _error != null
                ? ErrorView(
                    key: const ValueKey('error'),
                    message: _error!,
                    onRetry: _load,
                  )
                : _items.isEmpty
                    ? const EmptyState(
                        key: ValueKey('empty'),
                        icon: Icons.campaign_outlined,
                        title: 'Объявлений пока нет',
                      )
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        key: const ValueKey('list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = _items[i];
          if (item is! Map<String, dynamic>) return const SizedBox.shrink();
          final card = _buildCard(item, i);
          if (i >= _fadeAnims.length) return card;
          return FadeTransition(
            opacity: _fadeAnims[i],
            child: SlideTransition(position: _slideAnims[i], child: card),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final author = item['author'] is Map
        ? item['author'] as Map<String, dynamic>
        : null;
    final isPinned = item['isPinned'] == true;
    final title = item['title'] as String? ?? '';
    final content = item['content'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;
    final accent = isPinned ? AppColors.warning : AppColors.primaryBlue;
    final accentBg = isPinned ? AppColors.warningLight : AppColors.lightBlue;

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Accent bar via Stack+Positioned — avoids IntrinsicHeight+Expanded assertion
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 3),

                // Icon
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                      size: 17,
                      color: accent,
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPinned)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Закреплено',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          title,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (author != null) ...[
                              Text(
                                _shortName(author),
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: AppTextStyles.label,
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.gray500,
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
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final isPinned = item['isPinned'] == true;
    final author = item['author'] is Map
        ? item['author'] as Map<String, dynamic>
        : null;
    final title = item['title'] as String? ?? '';
    final content = item['content'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.white,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (isPinned)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Закреплённое объявление',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Row(
              children: [
                if (author != null) ...[
                  Text(_shortName(author), style: AppTextStyles.caption),
                  const SizedBox(width: 12),
                ],
                if (createdAt != null)
                  Text(_formatDate(createdAt), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              content,
              style: AppTextStyles.body.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  String _shortName(Map<String, dynamic> author) {
    final last = author['lastName'] as String? ?? '';
    final first = author['firstName'] as String? ?? '';
    if (first.isEmpty) return last;
    return '$last ${first[0]}.';
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
