import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

/// Lets a user compose several lunch portions before submitting them together.
///
/// A normal portion contains exactly two regular dishes; a special portion
/// contains exactly one dish below the `+` separator. The backend receives all
/// portions in one transaction through `/lunch/orders/batch`.
class LunchScreen extends StatefulWidget {
  const LunchScreen({super.key});

  @override
  State<LunchScreen> createState() => _LunchScreenState();
}

class _LunchScreenState extends State<LunchScreen> {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _busy = false;
  String _selectionType = 'COMBO';
  final _selectedIds = <String>[];
  final _noteController = TextEditingController();
  final _cart = <_LunchPortionDraft>[];
  final _requestIdRandom = Random.secure();
  String? _cartRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final response = await context.read<ApiClient>().get('/lunch/today');
      if (mounted) {
        setState(() => _data = Map<String, dynamic>.from(response as Map));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Map<String, dynamic>? get _menu {
    final menu = _data?['menu'];
    return menu is Map ? Map<String, dynamic>.from(menu) : null;
  }

  List<Map<String, dynamic>> get _items {
    final menu = _menu;
    if (menu == null) return const [];
    final raw = _selectionType == 'COMBO'
        ? menu['regularItems']
        : menu['specialItems'];
    return raw is List
        ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const [];
  }

  /// Supports both the new plural API field and old mobile/backend versions.
  List<Map<String, dynamic>> get _myOrders {
    final plural = _data?['myMealOrders'];
    if (plural is List) {
      return plural
          .whereType<Map>()
          .map((order) => Map<String, dynamic>.from(order))
          .toList();
    }
    final legacy = _data?['myMealOrder'];
    return legacy is Map ? [Map<String, dynamic>.from(legacy)] : const [];
  }

  bool get _canOrder =>
      _data?['canOrder'] == true && _menu?['acceptingOrders'] == true;

  int get _requiredSelectionCount => _selectionType == 'COMBO' ? 2 : 1;

  num get _price => _asNumber(_menu?['price'] ?? 35000);

  int _itemCount(String id) => _selectedIds.where((itemId) => itemId == id).length;

  void _toggleItem(String id) {
    setState(() {
      if (_selectionType == 'SINGLE') {
        _selectedIds
          ..clear()
          ..add(id);
        return;
      }
      if (_itemCount(id) > 0) {
        _selectedIds.removeWhere((itemId) => itemId == id);
        return;
      }
      if (_selectedIds.length < _requiredSelectionCount) _selectedIds.add(id);
    });
  }

  void _addSameItem(String id) {
    if (_selectionType != 'COMBO' || _itemCount(id) != 1 || _selectedIds.length >= _requiredSelectionCount) return;
    setState(() => _selectedIds.add(id));
  }

  void _changeSelectionType(String nextType) {
    setState(() {
      _selectionType = nextType;
      _selectedIds.clear();
    });
  }

  void _addPortionToCart() {
    if (_selectedIds.length != _requiredSelectionCount) {
      showMessage(
        context,
        _selectionType == 'COMBO'
            ? 'Vui lòng chọn đúng 2 món cho một phần cơm.'
            : 'Vui lòng chọn 1 món đơn.',
        error: true,
      );
      return;
    }

    final namesById = {
      for (final item in _items)
        item['id'].toString(): item['name']?.toString() ?? 'Món ăn',
    };
    final ids = _selectedIds.toList(growable: false);
    setState(() {
      _cart.add(
        _LunchPortionDraft(
          selectionType: _selectionType,
          itemIds: ids,
          itemNames: ids.map((id) => namesById[id] ?? 'Món ăn').toList(),
          note: _noteController.text.trim(),
        ),
      );
      _cartRequestId = null;
      _selectedIds.clear();
      _noteController.clear();
    });
    showMessage(context, 'Đã thêm phần ăn vào danh sách đặt.');
  }

  Future<void> _submitCart() async {
    final menu = _menu;
    if (menu == null || _cart.isEmpty || _busy) return;

    final portionCount = _cart.length;
    final total = _price * portionCount;
    final clientRequestId = _cartRequestId ??= _newCartRequestId();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shopping_bag_outlined),
        title: Text('Đặt $portionCount phần ăn?'),
        content: Text(
          'Hệ thống sẽ ghi nợ ${_formatCurrency(total)}. '
          'Bạn vẫn có thể hủy từng phần trước giờ chốt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận đặt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<ApiClient>().post(
        '/lunch/orders/batch',
        data: {
          'menuId': menu['id'],
          'clientRequestId': clientRequestId,
          'portions': _cart.map((portion) => portion.toRequest()).toList(),
        },
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _cartRequestId = null;
      });
      await _load();
      if (mounted) {
        showMessage(
          context,
          'Đã đặt $portionCount phần ăn. Khoản ghi nợ đã được cập nhật.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _newCartRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = _requestIdRandom.nextInt(1 << 32).toRadixString(36);
    return 'mobile_${timestamp}_$random';
  }

  Future<void> _cancelOrder(String id) async {
    setState(() => _busy = true);
    try {
      await context.read<ApiClient>().delete('/lunch/orders/$id');
      await _load();
      if (mounted) {
        showMessage(context, 'Đã hủy phần ăn và hoàn lại khoản ghi nợ.');
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorView(message: displayError(_error!), onRetry: _load);
    }
    if (_data == null) {
      return const LoadingView(label: 'Đang lấy menu hôm nay...');
    }

    final menu = _menu;
    if (menu == null) {
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

    final myOrders = _myOrders;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          const PageIntro(
            title: 'Đặt cơm hôm nay',
            subtitle: 'Mỗi phần cơm chọn 2 món phía trên dấu +; món đơn chọn 1 món phía dưới.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceCard(
                  label: 'Số dư quỹ',
                  value: _formatCurrency(_data!['walletBalance']),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceCard(
                  label: 'Dư nợ',
                  value: _formatCurrency(_data!['outstandingDebt']),
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
                    menu['orderLabel']?.toString() ??
                        menu['label']?.toString() ??
                        'Menu hôm nay',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${menu['vendorName'] ?? menu['vendor'] ?? 'Quán cơm'} '
                    '• ${_formatCurrency(_price)} / phần',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (!_canOrder) ...[
                    const SizedBox(height: 14),
                    _InfoBanner(
                      icon: Icons.lock_clock_outlined,
                      text:
                          _data!['blockReason']?.toString() ??
                          'Đã qua giờ chốt hoặc menu đã đóng.',
                    ),
                  ],
                  if (myOrders.isNotEmpty) ...[
                    const Divider(height: 30),
                    Text(
                      'Phần ăn của bạn (${myOrders.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...myOrders.asMap().entries.map(
                      (entry) => _PlacedOrderCard(
                        order: entry.value,
                        index: entry.key + 1,
                        canCancel: _canOrder && !_busy,
                        onCancel: () =>
                            _cancelOrder(entry.value['id'].toString()),
                      ),
                    ),
                  ],
                  const Divider(height: 30),
                  Text(
                    _cart.isEmpty ? 'Tạo phần ăn mới' : 'Thêm một phần khác',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bạn có thể thêm nhiều phần với các lựa chọn khác nhau, hoặc chọn cùng một món 2 lần cho một phần cơm.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
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
                    selected: {_selectionType},
                    onSelectionChanged: _canOrder && !_busy
                        ? (value) => _changeSelectionType(value.first)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _SelectionCounter(
                    current: _selectedIds.length,
                    required: _requiredSelectionCount,
                    isComplete: _selectedIds.length == _requiredSelectionCount,
                  ),
                  const SizedBox(height: 10),
                  if (_items.isEmpty)
                    const _InfoBanner(
                      icon: Icons.restaurant_menu_outlined,
                      text: 'Chưa có món trong nhóm lựa chọn này.',
                    )
                  else
                    ..._items.map((item) {
                      final id = item['id'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MenuItemTile(
                          item: item,
                          selected: _itemCount(id) > 0,
                          selectedCount: _itemCount(id),
                          canAddSame: _selectionType == 'COMBO' && _selectedIds.length < _requiredSelectionCount,
                          enabled: _canOrder && !_busy,
                          onTap: () => _toggleItem(id),
                          onAddSame: () => _addSameItem(id),
                        ),
                      );
                    }),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    enabled: _canOrder && !_busy,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú cho phần này (không bắt buộc)',
                      hintText: 'Ví dụ: cơm thêm, rau thêm, không cay',
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _canOrder && !_busy ? _addPortionToCart : null,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: Text(
                        _canOrder
                            ? 'Thêm phần vào danh sách'
                            : (_data!['blockReason']?.toString() ??
                                  'Đã qua giờ chốt'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_cart.isNotEmpty) ...[
            const SizedBox(height: 14),
            _OrderCart(
              portions: _cart,
              pricePerPortion: _price,
              busy: _busy,
              onRemove: (index) => setState(() {
                _cart.removeAt(index);
                _cartRequestId = null;
              }),
              onSubmit: _submitCart,
            ),
          ],
        ],
      ),
    );
  }

  static num _asNumber(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatCurrency(Object? value) => NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(_asNumber(value));

  static String _orderNames(Map order) {
    final items = order['items'];
    if (items is List) {
      return items
          .map((item) => item is Map ? item['name'] : item)
          .where((name) => name != null)
          .join(' + ');
    }
    return order['displayText']?.toString() ?? 'Phần cơm hôm nay';
  }

  static String? _nutrition(Map<String, dynamic> item) {
    final nutrients = item['nutrients'];
    final calories =
        item['calories'] ?? (nutrients is Map ? nutrients['calories'] : null);
    final protein =
        item['protein'] ?? (nutrients is Map ? nutrients['protein'] : null);
    if (calories == null && protein == null) return null;
    return '${calories ?? 0} kcal • ${protein ?? 0}g đạm';
  }
}

class _LunchPortionDraft {
  const _LunchPortionDraft({
    required this.selectionType,
    required this.itemIds,
    required this.itemNames,
    required this.note,
  });

  final String selectionType;
  final List<String> itemIds;
  final List<String> itemNames;
  final String note;

  Map<String, dynamic> toRequest() => {
    'selectionType': selectionType,
    'itemIds': itemIds,
    if (note.isNotEmpty) 'note': note,
  };
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({
    required this.current,
    required this.required,
    required this.isComplete,
  });

  final int current;
  final int required;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isComplete
        ? Theme.of(context).colorScheme.primary
        : Colors.black54;
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle_outline : Icons.touch_app_outlined,
          size: 19,
          color: color,
        ),
        const SizedBox(width: 7),
        Text(
          isComplete
              ? 'Đã chọn đủ $required/$required món'
              : 'Đã chọn $current/$required món${required == 2 ? ' · Có thể chọn một món 2 lần' : ''}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.selected,
    required this.selectedCount,
    required this.canAddSame,
    required this.enabled,
    required this.onTap,
    required this.onAddSame,
  });

  final Map<String, dynamic> item;
  final bool selected;
  final int selectedCount;
  final bool canAddSame;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onAddSame;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['imageUrl']?.toString();
    return Material(
      color: selected ? const Color(0xFFE2F8ED) : const Color(0xFFF7FAF8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _FoodThumbnail(imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? 'Món ăn',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_LunchScreenState._nutrition(item)
                        case final nutrition?)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          nutrition,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selectedCount > 0 && canAddSame)
                IconButton(
                  tooltip: 'Chọn thêm món này',
                  onPressed: enabled ? onAddSame : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'x$selectedCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Checkbox(
                value: selected,
                onChanged: enabled ? (_) => onTap() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodThumbnail extends StatelessWidget {
  const _FoodThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.restaurant_menu_outlined),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _PlacedOrderCard extends StatelessWidget {
  const _PlacedOrderCard({
    required this.order,
    required this.index,
    required this.canCancel,
    required this.onCancel,
  });

  final Map<String, dynamic> order;
  final int index;
  final bool canCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('$index'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _LunchScreenState._orderNames(order),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if ((order['note']?.toString().trim() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Ghi chú: ${order['note']}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Hủy phần này',
          onPressed: canCancel ? onCancel : null,
          icon: const Icon(Icons.cancel_outlined),
        ),
      ],
    ),
  );
}

class _OrderCart extends StatelessWidget {
  const _OrderCart({
    required this.portions,
    required this.pricePerPortion,
    required this.busy,
    required this.onRemove,
    required this.onSubmit,
  });

  final List<_LunchPortionDraft> portions;
  final num pricePerPortion;
  final bool busy;
  final ValueChanged<int> onRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final total = pricePerPortion * portions.length;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer
          .withValues(alpha: .48),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Danh sách đặt (${portions.length} phần)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  _LunchScreenState._formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...portions.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(entry.value.itemNames.join(' + ')),
                subtitle: entry.value.note.isEmpty
                    ? Text(
                        entry.value.selectionType == 'COMBO'
                            ? 'Phần cơm 2 món'
                            : 'Món đơn',
                      )
                    : Text('Ghi chú: ${entry.value.note}'),
                trailing: IconButton(
                  tooltip: 'Bỏ phần này',
                  onPressed: busy ? null : () => onRemove(entry.key),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  busy
                      ? 'Đang gửi đơn...'
                      : 'Đặt ${portions.length} phần • ${_LunchScreenState._formatCurrency(total)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
