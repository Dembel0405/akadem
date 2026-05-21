import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<dynamic> _items = [];
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
      final response = await dioClient.dio.get(ApiConstants.announcements);
      setState(() {
        _items = response.data['data'] as List;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Не удалось загрузить объявления'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text('Объявления', style: AppTextStyles.h3)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'Объявлений пока нет',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryBlue,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildItem(_items[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final author = item['author'] as Map<String, dynamic>?;
    final isPinned = item['isPinned'] as bool? ?? false;

    return AppCard(
      onTap: () => _showDetail(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPinned)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.push_pin_outlined, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text('Закреплено', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
                ],
              ),
            ),
          Text(item['title'] as String, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 6),
          Text(
            item['content'] as String,
            style: AppTextStyles.caption,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (author != null) ...[
                const Icon(Icons.person_outline, size: 13, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  '${author['lastName']} ${(author['firstName'] as String)[0]}.',
                  style: AppTextStyles.label,
                ),
                const SizedBox(width: 12),
              ],
              if (item['createdAt'] != null) ...[
                const Icon(Icons.access_time_outlined, size: 13, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(_formatDate(item['createdAt'] as String), style: AppTextStyles.label),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
            Text(item['title'] as String, style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(item['content'] as String, style: AppTextStyles.body.copyWith(height: 1.7)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
