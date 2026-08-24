import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await context.read<ApiClient>().get('/notifications');
      final values = raw is Map
          ? (raw['notifications'] ?? raw['content'])
          : raw;
      if (mounted) {
        setState(
          () => items = values is List
              ? values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [],
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markAll() async {
    try {
      await context.read<ApiClient>().post('/notifications/read-all');
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _mark(Map<String, dynamic> item) async {
    if (item['read'] == true || item['readAt'] != null) return;
    try {
      await context.read<ApiClient>().patch(
        '/notifications/${item['id']}/read',
      );
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView(label: 'Đang tải thông báo...');
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PageIntro(
                  title: 'Thông báo',
                  subtitle:
                      'Cập nhật từ admin, menu trưa, thanh toán và hệ thống.',
                ),
              ),
              TextButton.icon(
                onPressed: items.isEmpty ? null : _markAll,
                icon: const Icon(Icons.done_all),
                label: const Text('Đọc hết'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyView(
              icon: Icons.notifications_none,
              title: 'Không có thông báo',
              subtitle: 'Thông báo mới sẽ xuất hiện tại đây.',
            )
          else
            ...items.map((item) {
              final unread = item['read'] != true && item['readAt'] == null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: unread ? const Color(0xFFEAF9F1) : Colors.white,
                  child: ListTile(
                    onTap: () => _mark(item),
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
