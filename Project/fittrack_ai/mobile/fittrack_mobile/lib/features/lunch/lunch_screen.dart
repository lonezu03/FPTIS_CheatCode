import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class LunchScreen extends StatefulWidget {
  const LunchScreen({super.key});
  @override
  State<LunchScreen> createState() => _LunchScreenState();
}

class _LunchScreenState extends State<LunchScreen> {
  Map<String, dynamic>? data;
  Object? error;
  bool busy = false;
  String type = 'COMBO';
  final selected = <String>{};
  final note = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final response = await context.read<ApiClient>().get('/lunch/today');
      if (mounted) {
        setState(() => data = Map<String, dynamic>.from(response as Map));
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  List<Map<String, dynamic>> get _items {
    final menu = data?['menu'];
    if (menu is! Map) return const [];
    final raw = type == 'COMBO' ? menu['regularItems'] : menu['specialItems'];
    return raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : const [];
  }

  void _toggle(String id) {
    final limit = type == 'COMBO' ? 2 : 1;
    setState(() {
      if (selected.remove(id)) return;
      if (selected.length >= limit) {
        if (limit == 1) {
          selected.clear();
        } else {
          return;
        }
      }
      selected.add(id);
    });
  }

  Future<void> _placeOrder() async {
    final required = type == 'COMBO' ? 2 : 1;
    if (selected.length != required) {
      return showMessage(
        context,
        type == 'COMBO'
            ? 'Vui lòng chọn đúng 2 món.'
            : 'Vui lòng chọn 1 món đơn.',
        error: true,
      );
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/lunch/orders',
        data: {
          'menuId': (data!['menu'] as Map)['id'],
          'selectionType': type,
          'itemIds': selected.toList(),
          'note': note.text.trim(),
        },
      );
      selected.clear();
      note.clear();
      await _load();
      if (mounted) {
        showMessage(
          context,
          'Đặt cơm thành công. Quỹ được ghi nợ 35.000đ cho phần ăn này.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _cancelOrder(String id) async {
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().delete('/lunch/orders/$id');
      await _load();
      if (mounted) showMessage(context, 'Đã hủy đơn và hoàn lại khoản ghi nợ.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    if (data == null) {
      return const LoadingView(label: 'Đang lấy menu hôm nay...');
    }
    final menu = data!['menu'];
    if (menu is! Map) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            EmptyView(
              icon: Icons.no_meals_outlined,
              title: 'Chưa có menu hôm nay',
              subtitle:
                  'Admin sẽ import menu khi nhận được danh sách món từ quán.',
            ),
          ],
        ),
      );
    }
    final wallet = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(data!['walletBalance'] ?? 0);
    final debt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(data!['outstandingDebt'] ?? 0);
    final myOrder = data!['myMealOrder'];
    final canOrder =
        data!['canOrder'] == true && menu['acceptingOrders'] == true;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const PageIntro(
            title: 'Đặt cơm hôm nay',
            subtitle: 'Chọn 2 món cho phần cơm hoặc 1 món đơn bên dưới dấu +.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceCard(
                  label: 'Số dư quỹ',
                  value: wallet,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceCard(
                  label: 'Dư nợ',
                  value: debt,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['label']?.toString() ?? 'Menu hôm nay',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${menu['vendor'] ?? 'Quán cơm'} • ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(menu['price'] ?? 35000)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (myOrder is Map) ...[
                    const Divider(height: 28),
                    const Text(
                      'Bạn đã đặt',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(_orderNames(myOrder)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy || !canOrder
                          ? null
                          : () => _cancelOrder(myOrder['id'].toString()),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đơn'),
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'COMBO',
                          icon: Icon(Icons.rice_bowl_outlined),
                          label: Text('Cơm 2 món'),
                        ),
                        ButtonSegment(
                          value: 'SINGLE',
                          icon: Icon(Icons.ramen_dining_outlined),
                          label: Text('Món đơn'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: canOrder
                          ? (value) => setState(() {
                              type = value.first;
                              selected.clear();
                            })
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_items.isEmpty)
                      const Text(
                        'Không có món trong nhóm này.',
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      ..._items.map((item) {
                        final id = item['id'].toString();
                        final checked = selected.contains(id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: checked
                                ? const Color(0xFFE2F8ED)
                                : const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(14),
                            child: CheckboxListTile(
                              value: checked,
                              onChanged: canOrder ? (_) => _toggle(id) : null,
                              title: Text(item['name']?.toString() ?? 'Món ăn'),
                              subtitle: _nutrition(item),
                              secondary: item['imageUrl'] == null
                                  ? const Icon(Icons.restaurant_menu)
                                  : const Icon(Icons.image_outlined),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    TextField(
                      controller: note,
                      enabled: canOrder,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (không bắt buộc)',
                        hintText: 'Ví dụ: cơm thêm, rau thêm, không cay',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy || !canOrder ? null : _placeOrder,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          canOrder
                              ? 'Xác nhận đặt món'
                              : (data!['blockReason']?.toString() ??
                                    'Đã quá giờ chốt'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _orderNames(Map order) {
    final items = order['items'];
    if (items is List) {
      return items.map((e) => e is Map ? e['name'] : e).join(' + ');
    }
    return order['displayText']?.toString() ?? 'Đơn cơm hôm nay';
  }

  static Widget? _nutrition(Map<String, dynamic> item) {
    final calories =
        item['calories'] ??
        (item['nutrients'] is Map ? item['nutrients']['calories'] : null);
    final protein =
        item['protein'] ??
        (item['nutrients'] is Map ? item['nutrients']['protein'] : null);
    if (calories == null && protein == null) return null;
    return Text('${calories ?? 0} kcal • ${protein ?? 0}g đạm');
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
