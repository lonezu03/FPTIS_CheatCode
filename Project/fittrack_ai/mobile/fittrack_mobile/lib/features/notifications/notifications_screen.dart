import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_center.dart';
import '../../core/widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAll(BuildContext context) async {
    try {
      await context.read<NotificationCenter>().markAllRead();
    } catch (error) {
      if (context.mounted) {
        showMessage(context, displayError(error), error: true);
      }
    }
  }

  Future<void> _mark(BuildContext context, Map<String, dynamic> item) async {
    if (item['readAt'] != null) return;
    try {
      await context.read<NotificationCenter>().markRead(item['id'].toString());
    } catch (error) {
      if (context.mounted) {
        showMessage(context, displayError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = context.watch<NotificationCenter>();
    if (center.loading && center.items.isEmpty) {
      return const LoadingView(label: 'Đang tải thông báo...');
    }
    if (center.error != null && center.items.isEmpty) {
      return ErrorView(
        message: displayError(center.error!),
        onRetry: center.refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: center.refresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PageIntro(
                  title: 'Thông báo',
                  subtitle: 'App kiểm tra cập nhật khi đang mở và định kỳ ở chế độ nền.',
                ),
              ),
              TextButton.icon(
                onPressed: center.items.isEmpty
                    ? null
                    : () => _markAll(context),
                icon: const Icon(Icons.done_all),
                label: const Text('Đọc hết'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (center.items.isEmpty)
            const EmptyView(
              icon: Icons.notifications_none,
              title: 'Không có thông báo',
              subtitle: 'Thông báo mới sẽ xuất hiện tại đây.',
            )
          else
            ...center.items.map((item) {
              final unread = item['readAt'] == null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: unread ? const Color(0xFFEAF9F1) : Colors.white,
                  child: ListTile(
                    onTap: () => _mark(context, item),
                    leading: CircleAvatar(child: Icon(_icon(item['type']))),
                    title: Text(
                      item['title']?.toString() ?? 'Thông báo',
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${item['message'] ?? ''}${_time(item).isEmpty ? '' : '\n${_time(item)}'}',
                    ),
                    isThreeLine: true,
                    trailing: unread
                        ? const Badge()
                        : const Icon(Icons.done, size: 18),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  static IconData _icon(dynamic type) => switch (type?.toString()) {
    'LUNCH_MENU' || 'LUNCH' => Icons.lunch_dining_outlined,
    'PAYMENT' || 'PAYMENT_REQUEST' => Icons.payments_outlined,
    'REMINDER' => Icons.alarm_outlined,
    _ => Icons.campaign_outlined,
  };

  static String _time(Map<String, dynamic> item) {
    final value = item['createdAt'] ?? item['sentAt'];
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
