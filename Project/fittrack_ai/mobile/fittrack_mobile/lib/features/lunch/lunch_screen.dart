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
  List<Map<String, dynamic>> _people = const [];
  Object? _error;
  Object? _peopleError;
  bool _busy = false;
  String _selectionType = 'COMBO';
  final _selectedIds = <String>[];
  final _selectedExtraIds = <String>[];
  String? _selectedBeneficiaryId;
  String? _selectedMenuId;
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
    setState(() {
      _error = null;
      _peopleError = null;
    });
    try {
      final api = context.read<ApiClient>();
      final response = await api.get('/lunch/today');
      List<Map<String, dynamic>> people = const [];
      Object? peopleError;
      try {
        final peopleResponse = await api.get('/lunch/people');
        if (peopleResponse is List) {
          people = peopleResponse
              .whereType<Map>()
              .map((person) => Map<String, dynamic>.from(person))
              .toList(growable: false);
        }
      } catch (error) {
        peopleError = error;
      }
      if (mounted) {
        setState(() {
          _data = Map<String, dynamic>.from(response as Map);
          _people = people;
          _peopleError = peopleError;
          if (_selectedBeneficiaryId != null &&
              !_people.any(
                (person) => person['id']?.toString() == _selectedBeneficiaryId,
              )) {
            _selectedBeneficiaryId = null;
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<Map<String, dynamic>> get _menus {
    final plural = _data?['menus'];
    if (plural is List && plural.isNotEmpty) {
      return plural
          .whereType<Map>()
          .map((menu) => Map<String, dynamic>.from(menu))
          .toList();
    }
    final singular = _data?['menu'];
    return singular is Map ? [Map<String, dynamic>.from(singular)] : const [];
  }

  Map<String, dynamic>? get _menu {
    final menus = _menus;
    if (menus.isEmpty) return null;
    return menus.firstWhere(
      (menu) => menu['id']?.toString() == _selectedMenuId,
      orElse: () => menus.first,
    );
  }

  List<Map<String, dynamic>> get _extraItems {
    final raw = _menu?['extraItems'];
    return raw is List
        ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const [];
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

  List<Map<String, dynamic>> get _placedForOthers {
    final raw = _data?['placedForOthers'];
    return raw is List
        ? raw
              .whereType<Map>()
              .map((order) => Map<String, dynamic>.from(order))
              .toList()
        : const [];
  }

  Map<String, dynamic>? get _selectedBeneficiary {
    final id = _selectedBeneficiaryId;
    if (id == null) return null;
    for (final person in _people) {
      if (person['id']?.toString() == id) return person;
    }
    return null;
  }

  bool get _canOrder =>
      _data?['canOrder'] == true && _menu?['acceptingOrders'] == true;

  int get _requiredSelectionCount => _selectionType == 'COMBO' ? 2 : 1;

  num get _price => _asNumber(_menu?['price'] ?? 35000);

  int _extraCount(String id) =>
      _selectedExtraIds.where((itemId) => itemId == id).length;

  void _changeMenu(String id) {
    if (_selectedMenuId == id) return;
    setState(() {
      _selectedMenuId = id;
      _selectedIds.clear();
      _selectedExtraIds.clear();
      _selectedBeneficiaryId = null;
      _cart.clear();
      _cartRequestId = null;
      _noteController.clear();
    });
  }

  void _changeExtra(String id, int delta) {
    setState(() {
      if (delta > 0) {
        _selectedExtraIds.add(id);
      } else {
        final index = _selectedExtraIds.indexOf(id);
        if (index >= 0) _selectedExtraIds.removeAt(index);
      }
    });
  }

  int _itemCount(String id) =>
      _selectedIds.where((itemId) => itemId == id).length;

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
    if (_selectionType != 'COMBO' ||
        _itemCount(id) != 1 ||
        _selectedIds.length >= _requiredSelectionCount) {
      return;
    }
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
    final extraIds = _selectedExtraIds.toList(growable: false);
    final namesByExtraId = {
      for (final item in _extraItems)
        item['id'].toString(): item['name']?.toString() ?? 'Món thêm',
    };
    setState(() {
      _cart.add(
        _LunchPortionDraft(
          selectionType: _selectionType,
          itemIds: ids,
          extraItemIds: extraIds,
          itemNames: [
            ...ids.map((id) => namesById[id] ?? 'Món ăn'),
            ...extraIds.map(
              (id) => '${namesByExtraId[id] ?? 'Món thêm'} (thêm)',
            ),
          ],
          beneficiaryUserId: _selectedBeneficiaryId,
          beneficiaryName:
              _selectedBeneficiary?['fullName']?.toString() ?? 'Bạn',
          note: _noteController.text.trim(),
        ),
      );
      _cartRequestId = null;
      _selectedIds.clear();
      _selectedExtraIds.clear();
      _selectedBeneficiaryId = null;
      _noteController.clear();
    });
    showMessage(context, 'Đã thêm phần ăn vào danh sách đặt.');
  }

  Future<void> _submitCart() async {
    final menu = _menu;
    if (menu == null || _cart.isEmpty || _busy) return;

    final portionCount = _cart.length;
    final total = _cart.fold<num>(
      0,
      (sum, portion) => sum + portion.total(_price, _extraItems),
    );
    final clientRequestId = _cartRequestId ??= _newCartRequestId();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shopping_bag_outlined),
        title: Text('Đặt $portionCount phần ăn?'),
        content: Text(
          _cart.any((portion) => portion.beneficiaryUserId != null)
              ? 'Tổng giá trị ${_formatCurrency(total)}. Mỗi phần sẽ dùng quỹ của đúng người nhận; phần thiếu được ghi vào công nợ của người đó. Bạn vẫn có thể hủy trước giờ chốt.'
              : 'Hệ thống sẽ dùng quỹ của bạn và ghi phần thiếu trong ${_formatCurrency(total)} vào công nợ. Bạn vẫn có thể hủy từng phần trước giờ chốt.',
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
          'Đã đặt $portionCount phần ăn. Quỹ và công nợ của từng người nhận đã được cập nhật.',
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
    final placedForOthers = _placedForOthers;
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
                  if (_menus.length > 1) ...[
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer
                          .withValues(alpha: .45),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn bộ menu / điều phối viên',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Chọn quán hoặc admin điều phối trước khi tạo phần ăn.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            ..._menus.map(
                              (candidate) => RadioListTile<String>(
                                value: candidate['id'].toString(),
                                groupValue: _menu?['id']?.toString(),
                                onChanged: _busy || _cart.isNotEmpty
                                    ? null
                                    : (value) {
                                        if (value != null) _changeMenu(value);
                                      },
                                title: Text(
                                  candidate['orderLabel']?.toString() ??
                                      'Menu hôm nay',
                                ),
                                subtitle: Text(
                                  '${candidate['vendorName'] ?? 'Quán cơm'} • ${candidate['coordinator'] is Map ? (candidate['coordinator']['fullName'] ?? 'Điều phối viên') : 'Điều phối viên'}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
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
                  if (placedForOthers.isNotEmpty) ...[
                    const Divider(height: 30),
                    Text(
                      'Phần bạn đặt hộ (${placedForOthers.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...placedForOthers.asMap().entries.map(
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
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedBeneficiaryId ?? ''),
                    initialValue: _selectedBeneficiaryId ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Người nhận phần ăn',
                      prefixIcon: Icon(Icons.person_outline),
                      helperText: 'Đặt hộ không dùng quỹ của bạn. Chi phí thuộc về người nhận.',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Tôi — đặt cho bản thân'),
                      ),
                      ..._people.map(
                        (person) => DropdownMenuItem(
                          value: person['id']?.toString() ?? '',
                          child: Text(
                            '${person['fullName'] ?? person['email'] ?? 'Đồng nghiệp'} — đặt hộ',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _canOrder && !_busy
                        ? (value) => setState(
                            () => _selectedBeneficiaryId =
                                value == null || value.isEmpty ? null : value,
                          )
                        : null,
                  ),
                  if (_peopleError != null) ...[
                    const SizedBox(height: 8),
                    const _InfoBanner(
                      icon: Icons.people_outline,
                      text: 'Chưa tải được danh sách đồng nghiệp. Kéo xuống để thử lại; bạn vẫn có thể tự đặt.',
                    ),
                  ],
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
                          canAddSame:
                              _selectionType == 'COMBO' &&
                              _selectedIds.length < _requiredSelectionCount,
                          enabled: _canOrder && !_busy,
                          onTap: () => _toggleItem(id),
                          onAddSame: () => _addSameItem(id),
                        ),
                      );
                    }),
                  if (_extraItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Món thêm / đồ uống',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Có thể chọn nhiều chai/cốc; giá cộng vào phần này.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ..._extraItems.map((item) {
                      final id = item['id'].toString();
                      final count = _extraCount(id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: const Color(0xFFF2F8FF),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? 'Món thêm',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(item['unitPrice']),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _canOrder && !_busy && count > 0
                                      ? () => _changeExtra(id, -1)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _canOrder && !_busy
                                      ? () => _changeExtra(id, 1)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
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
              extraItems: _extraItems,
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
    required this.extraItemIds,
    required this.itemNames,
    required this.beneficiaryName,
    required this.note,
    this.beneficiaryUserId,
  });

  final String selectionType;
  final List<String> itemIds;
  final List<String> extraItemIds;
  final List<String> itemNames;
  final String? beneficiaryUserId;
  final String beneficiaryName;
  final String note;

  num total(num basePrice, List<Map<String, dynamic>> extraItems) =>
      basePrice +
      extraItemIds.fold<num>(0, (sum, id) {
        final item = extraItems.firstWhere(
          (candidate) => candidate['id'].toString() == id,
          orElse: () => <String, dynamic>{},
        );
        return sum + _LunchScreenState._asNumber(item['unitPrice']);
      });

  Map<String, dynamic> toRequest() => {
    'selectionType': selectionType,
    'itemIds': itemIds,
    if (beneficiaryUserId != null) 'beneficiaryUserId': beneficiaryUserId,
    if (extraItemIds.isNotEmpty) 'extraItemIds': extraItemIds,
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
  Widget build(BuildContext context) {
    final beneficiary = order['beneficiary'];
    final orderedBy = order['orderedBy'];
    final beneficiaryId = beneficiary is Map
        ? beneficiary['id']?.toString()
        : null;
    final orderedById = orderedBy is Map ? orderedBy['id']?.toString() : null;
    final isProxyOrder =
        beneficiaryId != null &&
        orderedById != null &&
        beneficiaryId != orderedById;
    final beneficiaryName = beneficiary is Map
        ? beneficiary['fullName']?.toString() ?? 'Đồng nghiệp'
        : 'Đồng nghiệp';
    return Container(
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
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isProxyOrder)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Người nhận: $beneficiaryName • Chi phí tính cho người nhận',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _OrderCart extends StatelessWidget {
  const _OrderCart({
    required this.portions,
    required this.pricePerPortion,
    required this.extraItems,
    required this.busy,
    required this.onRemove,
    required this.onSubmit,
  });

  final List<_LunchPortionDraft> portions;
  final num pricePerPortion;
  final List<Map<String, dynamic>> extraItems;
  final bool busy;
  final ValueChanged<int> onRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final total = portions.fold<num>(
      0,
      (sum, portion) => sum + portion.total(pricePerPortion, extraItems),
    );
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
                subtitle: Text(
                  '${entry.value.selectionType == 'COMBO' ? 'Phần cơm 2 món' : 'Món đơn'}'
                  ' • Người nhận: ${entry.value.beneficiaryName}'
                  '${entry.value.note.isEmpty ? '' : '\nGhi chú: ${entry.value.note}'}',
                ),
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
