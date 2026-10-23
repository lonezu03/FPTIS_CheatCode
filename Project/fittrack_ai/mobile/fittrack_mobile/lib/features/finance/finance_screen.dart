import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? dashboard;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> recurring = [];
  Object? error;
  bool loading = true;

  String get monthValue => DateFormat('yyyy-MM').format(month);
  String get monthDateValue => '$monthValue-01';
  String get firstDay => '$monthValue-01';
  String get lastDay =>
      DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month + 1, 0));

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final values = await Future.wait([
        api.get(
          '/finance/dashboard',
          queryParameters: {'month': monthDateValue},
        ),
        api.get(
          '/finance/transactions',
          queryParameters: {
            'from': firstDay,
            'to': lastDay,
            'page': 0,
            'size': 50,
          },
        ),
        api.get('/finance/accounts'),
        api.get('/finance/categories'),
        api.get('/finance/budgets', queryParameters: {'month': monthDateValue}),
        api.get('/finance/recurring'),
      ]);
      if (!mounted) return;
      setState(() {
        dashboard = Map<String, dynamic>.from(values[0] as Map);
        transactions = _pageItems(values[1]);
        accounts = _maps(values[2]);
        categories = _maps(values[3]);
        budgets = _maps(values[4]);
        recurring = _maps(values[5]);
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(dynamic raw) => (raw as List? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  List<Map<String, dynamic>> _pageItems(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    return _maps(map['content']);
  }

  Future<void> _changeMonth(int delta) async {
    setState(() => month = DateTime(month.year, month.month + delta));
    await _load();
  }

  Future<void> _mutate(
    Future<dynamic> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      showMessage(context, success);
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _transactionDialog([Map<String, dynamic>? current]) async {
    var type = current?['type']?.toString() ?? 'EXPENSE';
    String? accountId = current?['accountId']?.toString() ?? _firstId(accounts);
    String? destinationId = current?['destinationAccountId']?.toString();
    String? categoryId = current?['categoryId']?.toString();
    final amount = TextEditingController(
      text: current?['amount']?.toString() ?? '',
    );
    final merchant = TextEditingController(
      text: current?['merchant']?.toString() ?? '',
    );
    final note = TextEditingController(
      text: current?['note']?.toString() ?? '',
    );
    final savedDate = current?['occurredAt']?.toString().replaceFirst('T', ' ');
    final occurredAt = TextEditingController(
      text: savedDate != null && savedDate.length >= 16
          ? savedDate.substring(0, 16)
          : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    var analyzingReceipt = false;
    var receiptDraft = false;
    String? receiptWarning;
    var dialogOpen = true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(current == null ? 'Thêm giao dịch' : 'Sửa giao dịch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (current == null) ...[
                  OutlinedButton.icon(
                    onPressed: analyzingReceipt
                        ? null
                        : () async {
                            setLocal(() => analyzingReceipt = true);
                            try {
                              final useCamera =
                                  await showModalBottomSheet<bool>(
                                    context: dialogContext,
                                    builder: (sheetContext) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                              Icons.camera_alt_outlined,
                                            ),
                                            title: const Text(
                                              'Chụp ảnh hóa đơn',
                                            ),
                                            onTap: () => Navigator.pop(
                                              sheetContext,
                                              true,
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library_outlined,
                                            ),
                                            title: const Text(
                                              'Chọn ảnh có sẵn',
                                            ),
                                            onTap: () => Navigator.pop(
                                              sheetContext,
                                              false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                              if (useCamera == null ||
                                  !dialogOpen ||
                                  !dialogContext.mounted) {
                                return;
                              }
                              final cameraFile = useCamera
                                  ? await ImagePicker().pickImage(
                                      source: ImageSource.camera,
                                    )
                                  : null;
                              final file = useCamera
                                  ? null
                                  : await FilePicker.pickFile(
                                      type: FileType.image,
                                    );
                              if ((cameraFile == null && file == null) ||
                                  !dialogOpen ||
                                  !dialogContext.mounted) {
                                return;
                              }
                              final extension =
                                  (cameraFile?.name.split('.').last ??
                                          file?.extension ??
                                          '')
                                      .toLowerCase();
                              final mime = switch (extension) {
                                'jpg' || 'jpeg' => 'image/jpeg',
                                'png' => 'image/png',
                                'webp' => 'image/webp',
                                _ => null,
                              };
                              if (mime == null) {
                                showMessage(
                                  dialogContext,
                                  'Chỉ hỗ trợ ảnh JPG, PNG hoặc WebP.',
                                  error: true,
                                );
                                return;
                              }
                              final bytes = cameraFile != null
                                  ? await cameraFile.readAsBytes()
                                  : await file!.readAsBytes();
                              if (!dialogOpen || !dialogContext.mounted) return;
                              if (bytes.isEmpty || bytes.length > 1500000) {
                                showMessage(
                                  dialogContext,
                                  'Ảnh phải nhỏ hơn 1,5 MB.',
                                  error: true,
                                );
                                return;
                              }
                              final oldAmount = amount.text;
                              final oldDate = occurredAt.text;
                              final oldMerchant = merchant.text;
                              final oldNote = note.text;
                              final raw = await dialogContext
                                  .read<ApiClient>()
                                  .post(
                                    '/finance/receipt/analyze',
                                    data: {
                                      'imageData':
                                          'data:$mime;base64,${base64Encode(bytes)}',
                                    },
                                  );
                              if (!dialogOpen || !dialogContext.mounted) return;
                              final result = Map<String, dynamic>.from(
                                raw as Map,
                              );
                              setLocal(() {
                                receiptDraft = true;
                                // Never overwrite fields edited while the request was pending.
                                if (amount.text == oldAmount &&
                                    result['amount'] != null) {
                                  amount.text = result['amount'].toString();
                                }
                                final date = result['occurredAt']?.toString();
                                if (occurredAt.text == oldDate &&
                                    date != null &&
                                    DateTime.tryParse(date) != null) {
                                  occurredAt.text = DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(DateTime.parse(date));
                                }
                                if (merchant.text == oldMerchant &&
                                    result['merchant'] != null) {
                                  merchant.text = result['merchant'].toString();
                                }
                                if (note.text == oldNote &&
                                    result['note'] != null) {
                                  note.text = result['note'].toString();
                                }
                                type = 'EXPENSE';
                                accountId = null;
                                categoryId = null;
                                receiptWarning = result['warning']?.toString();
                              });
                            } catch (error) {
                              if (dialogOpen && dialogContext.mounted) {
                                showMessage(
                                  dialogContext,
                                  displayError(error),
                                  error: true,
                                );
                              }
                            } finally {
                              if (dialogOpen && dialogContext.mounted) {
                                setLocal(() => analyzingReceipt = false);
                              }
                            }
                          },
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      analyzingReceipt
                          ? 'Đang đọc hóa đơn…'
                          : 'Chụp hoặc chọn ảnh hóa đơn',
                    ),
                  ),
                  const Text(
                    'Ảnh chỉ dùng để gợi ý bản nháp. Kiểm tra lại số tiền, ngày và chọn tài khoản, danh mục trước khi lưu.',
                  ),
                  if (receiptWarning?.isNotEmpty == true) Text(receiptWarning!),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(
                  key: ValueKey('transaction-type-$receiptDraft'),
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Loại giao dịch',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'EXPENSE', child: Text('Chi tiêu')),
                    DropdownMenuItem(value: 'INCOME', child: Text('Thu nhập')),
                    DropdownMenuItem(
                      value: 'TRANSFER',
                      child: Text('Chuyển khoản'),
                    ),
                  ],
                  onChanged: receiptDraft
                      ? null
                      : (v) => setLocal(() => type = v!),
                ),
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: ValueKey('account-$receiptDraft'),
                  child: _mapDropdown(
                    'Tài khoản',
                    accounts,
                    accountId,
                    (v) => setLocal(() => accountId = v),
                  ),
                ),
                if (type == 'TRANSFER') ...[
                  const SizedBox(height: 10),
                  _mapDropdown(
                    'Tài khoản nhận',
                    accounts,
                    destinationId,
                    (v) => setLocal(() => destinationId = v),
                  ),
                ],
                if (type != 'TRANSFER') ...[
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: ValueKey('category-$type-$receiptDraft'),
                    child: _mapDropdown(
                      'Danh mục',
                      categories
                          .where((c) => c['transactionKind'] == type)
                          .toList(),
                      categoryId,
                      (v) => setLocal(() => categoryId = v),
                      optional: !receiptDraft,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền (đ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: occurredAt,
                  decoration: const InputDecoration(
                    labelText: 'Ngày giờ (yyyy-MM-dd HH:mm)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: merchant,
                  decoration: const InputDecoration(
                    labelText: 'Người nhận / nguồn tiền',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: analyzingReceipt
                  ? null
                  : () {
                      if (accountId == null ||
                          (receiptDraft && categoryId == null)) {
                        showMessage(
                          dialogContext,
                          'Hãy chọn tài khoản và danh mục trước khi lưu.',
                          error: true,
                        );
                        return;
                      }
                      if ((double.tryParse(
                                amount.text.replaceAll(',', '').trim(),
                              ) ??
                              0) <=
                          0) {
                        showMessage(
                          dialogContext,
                          'Số tiền phải lớn hơn 0.',
                          error: true,
                        );
                        return;
                      }
                      if (DateTime.tryParse(
                            occurredAt.text.trim().replaceFirst(' ', 'T'),
                          ) ==
                          null) {
                        showMessage(
                          dialogContext,
                          'Ngày giờ không hợp lệ.',
                          error: true,
                        );
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    dialogOpen = false;
    if (accepted != true) return;
    if (accountId == null || (receiptDraft && categoryId == null)) {
      if (mounted) {
        showMessage(
          context,
          'Hãy chọn tài khoản và danh mục trước khi lưu.',
          error: true,
        );
      }
      return;
    }
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      if (mounted) showMessage(context, 'Số tiền phải lớn hơn 0.', error: true);
      return;
    }
    final parsedDate = DateTime.tryParse(
      occurredAt.text.trim().replaceFirst(' ', 'T'),
    );
    if (parsedDate == null) {
      if (mounted) {
        showMessage(
          context,
          'Ngày giờ không hợp lệ. Dùng định dạng yyyy-MM-dd HH:mm.',
          error: true,
        );
      }
      return;
    }
    final payload = {
      'type': type,
      'amount': value,
      'accountId': accountId,
      'destinationAccountId': type == 'TRANSFER' ? destinationId : null,
      'categoryId': type == 'TRANSFER' ? null : categoryId,
      'expenseNature': current?['expenseNature'],
      'occurredAt': parsedDate.toIso8601String(),
      'merchant': merchant.text.trim(),
      'note': note.text.trim(),
    };
    await _mutate(
      () => current == null
          ? context.read<ApiClient>().post(
              '/finance/transactions',
              data: payload,
            )
          : context.read<ApiClient>().put(
              '/finance/transactions/${current['id']}',
              data: payload,
            ),
      'Đã lưu giao dịch.',
    );
  }

  Future<void> _accountDialog([Map<String, dynamic>? current]) async {
    final name = TextEditingController(
      text: current?['name']?.toString() ?? '',
    );
    final opening = TextEditingController(
      text: current?['openingBalance']?.toString() ?? '0',
    );
    var type = current?['accountType']?.toString() ?? 'CASH';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            current == null ? 'Thêm tài khoản tiền' : 'Sửa tài khoản tiền',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên tài khoản'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Loại'),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 'BANK', child: Text('Ngân hàng')),
                  DropdownMenuItem(
                    value: 'E_WALLET',
                    child: Text('Ví điện tử'),
                  ),
                  DropdownMenuItem(
                    value: 'CREDIT_CARD',
                    child: Text('Thẻ tín dụng'),
                  ),
                ],
                onChanged: (v) => setLocal(() => type = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: opening,
                enabled: current == null,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số dư ban đầu'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final payload = {
      'name': name.text.trim(),
      'accountType': type,
      'currencyCode': 'VND',
      'openingBalance': double.tryParse(opening.text) ?? 0,
    };
    await _mutate(
      () => current == null
          ? context.read<ApiClient>().post('/finance/accounts', data: payload)
          : context.read<ApiClient>().put(
              '/finance/accounts/${current['id']}',
              data: payload,
            ),
      'Đã lưu tài khoản.',
    );
  }

  Future<void> _categoryDialog([Map<String, dynamic>? current]) async {
    final name = TextEditingController(
      text: current?['name']?.toString() ?? '',
    );
    var kind = current?['transactionKind']?.toString() ?? 'EXPENSE';
    var nature = current?['expenseNature']?.toString() ?? 'ESSENTIAL_VARIABLE';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(current == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Nhóm'),
                items: const [
                  DropdownMenuItem(value: 'EXPENSE', child: Text('Chi tiêu')),
                  DropdownMenuItem(value: 'INCOME', child: Text('Thu nhập')),
                ],
                onChanged: (v) => setLocal(() => kind = v!),
              ),
              if (kind == 'EXPENSE') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: nature,
                  decoration: const InputDecoration(
                    labelText: 'Tính chất chi tiêu',
                  ),
                  items: _natureItems,
                  onChanged: (v) => setLocal(() => nature = v!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final payload = {
      'name': name.text.trim(),
      'transactionKind': kind,
      'expenseNature': kind == 'EXPENSE' ? nature : null,
      'parentId': current?['parentId'],
      'icon': current?['icon'],
    };
    await _mutate(
      () => current == null
          ? context.read<ApiClient>().post('/finance/categories', data: payload)
          : context.read<ApiClient>().put(
              '/finance/categories/${current['id']}',
              data: payload,
            ),
      'Đã lưu danh mục.',
    );
  }

  Future<void> _budgetDialog([Map<String, dynamic>? current]) async {
    String? categoryId =
        current?['categoryId']?.toString() ??
        _firstId(
          categories.where((c) => c['transactionKind'] == 'EXPENSE').toList(),
        );
    final amount = TextEditingController(
      text: current?['amount']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Ngân sách tháng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mapDropdown(
                'Danh mục chi',
                categories
                    .where((c) => c['transactionKind'] == 'EXPENSE')
                    .toList(),
                categoryId,
                (v) => setLocal(() => categoryId = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hạn mức (đ)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || categoryId == null) return;
    final payload = {
      'categoryId': categoryId,
      'month': monthDateValue,
      'amount': double.tryParse(amount.text) ?? 0,
      'rolloverEnabled': current?['rolloverEnabled'] == true,
    };
    await _mutate(
      () => current == null
          ? context.read<ApiClient>().post('/finance/budgets', data: payload)
          : context.read<ApiClient>().put(
              '/finance/budgets/${current['id']}',
              data: payload,
            ),
      'Đã lưu ngân sách.',
    );
  }

  String? _firstId(List<Map<String, dynamic>> values) =>
      values.isEmpty ? null : values.first['id']?.toString();

  Widget _mapDropdown(
    String label,
    List<Map<String, dynamic>> values,
    String? selected,
    ValueChanged<String?> changed, {
    bool optional = false,
  }) {
    final ids = values
        .map((e) => e['id']?.toString())
        .whereType<String>()
        .toSet();
    final value = ids.contains(selected) ? selected : null;
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (optional)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Không chọn'),
          ),
        ...values.map(
          (e) => DropdownMenuItem(
            value: e['id']?.toString(),
            child: Text(e['name']?.toString() ?? '-'),
          ),
        ),
      ],
      onChanged: changed,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && dashboard == null) return const LoadingView();
    if (error != null && dashboard == null)
      return ErrorView(message: displayError(error!), onRetry: _load);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  'Tài chính · ${DateFormat('MM/yyyy').format(month)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Giao dịch'),
            Tab(text: 'Thiết lập'),
            Tab(text: 'Kế hoạch'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [_overview(), _transactionList(), _setup(), _plans()],
          ),
        ),
      ],
    );
  }

  Widget _overview() {
    final data = dashboard ?? const <String, dynamic>{};
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat(
                'Tổng số dư',
                data['totalBalance'],
                Icons.account_balance_wallet_outlined,
              ),
              _stat(
                'Thu nhập',
                data['income'],
                Icons.south_west,
                positive: true,
              ),
              _stat(
                'Chi tiêu',
                data['expense'],
                Icons.north_east,
                negative: true,
              ),
              _stat(
                'Tiết kiệm ròng',
                data['netSaving'],
                Icons.savings_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Gợi ý tháng này'),
              subtitle: Text(
                data['insight']?.toString() ?? 'Chưa đủ dữ liệu để phân tích.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tài khoản',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          ...accounts.map(
            (a) => Card(
              child: ListTile(
                title: Text(a['name']?.toString() ?? '-'),
                subtitle: Text(a['accountType']?.toString() ?? ''),
                trailing: Text(
                  _money(a['currentBalance']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionList() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: accounts.isEmpty ? null : () => _transactionDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm giao dịch'),
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const EmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            subtitle: 'Thêm khoản thu, chi hoặc chuyển khoản đầu tiên.',
          ),
        ...transactions.map(
          (t) => Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  t['type'] == 'INCOME'
                      ? Icons.south_west
                      : t['type'] == 'TRANSFER'
                      ? Icons.swap_horiz
                      : Icons.north_east,
                ),
              ),
              title: Text(
                t['merchant']?.toString().trim().isNotEmpty == true
                    ? t['merchant'].toString()
                    : t['categoryName']?.toString() ?? _typeLabel(t['type']),
              ),
              subtitle: Text(
                '${t['accountName'] ?? '-'} · ${t['occurredAt']?.toString().split('T').first ?? ''}${t['status'] == 'VOID' ? ' · ĐÃ HỦY' : ''}',
              ),
              trailing: Text(
                _money(t['amount']),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: t['type'] == 'INCOME' ? Colors.green : null,
                ),
              ),
              onTap: t['status'] == 'VOID' ? null : () => _transactionDialog(t),
              onLongPress: t['status'] == 'VOID'
                  ? null
                  : () => _mutate(
                      () => context.read<ApiClient>().delete(
                        '/finance/transactions/${t['id']}',
                      ),
                      'Đã hủy giao dịch.',
                    ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _setup() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tài khoản tiền',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _accountDialog(),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        ...accounts.map(
          (a) => Card(
            child: ListTile(
              title: Text(a['name']?.toString() ?? '-'),
              subtitle: Text(_money(a['currentBalance'])),
              onTap: () => _accountDialog(a),
              trailing: IconButton(
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _mutate(
                  () => context.read<ApiClient>().delete(
                    '/finance/accounts/${a['id']}',
                  ),
                  'Đã lưu trữ tài khoản.',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Danh mục',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _categoryDialog(),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        ...categories.map(
          (c) => Card(
            child: ListTile(
              title: Text(c['name']?.toString() ?? '-'),
              subtitle: Text(
                c['transactionKind'] == 'INCOME'
                    ? 'Thu nhập'
                    : 'Chi tiêu · ${_natureLabel(c['expenseNature'])}',
              ),
              onTap: c['systemCategory'] == true
                  ? null
                  : () => _categoryDialog(c),
              trailing: c['systemCategory'] == true
                  ? const Icon(Icons.lock_outline)
                  : IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: () => _mutate(
                        () => context.read<ApiClient>().delete(
                          '/finance/categories/${c['id']}',
                        ),
                        'Đã lưu trữ danh mục.',
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _plans() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ngân sách',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _budgetDialog(),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        ...budgets.map(
          (b) => Card(
            child: ListTile(
              title: Text(b['categoryName']?.toString() ?? '-'),
              subtitle: LinearProgressIndicator(
                value:
                    ((b['percent'] as num?)?.toDouble() ?? 0).clamp(0, 100) /
                    100,
              ),
              trailing: Text(
                '${_money(b['spent'])}\n/ ${_money(b['amount'])}',
                textAlign: TextAlign.right,
              ),
              onTap: () => _budgetDialog(b),
              onLongPress: () => _mutate(
                () => context.read<ApiClient>().delete(
                  '/finance/budgets/${b['id']}',
                ),
                'Đã xóa ngân sách.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Khoản định kỳ',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (recurring.isEmpty)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Chưa có khoản định kỳ. Bạn có thể tạo và chỉnh chi tiết trên web; app hỗ trợ xác nhận, nhắc lại và lưu trữ.',
            ),
          ),
        ...recurring.map(
          (r) => Card(
            child: ListTile(
              title: Text(r['name']?.toString() ?? '-'),
              subtitle: Text(
                '${_money(r['amount'])} · kỳ tới ${r['nextDueDate'] ?? '-'}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'confirm')
                    _mutate(
                      () => context.read<ApiClient>().post(
                        '/finance/recurring/${r['id']}/confirm',
                      ),
                      'Đã ghi nhận giao dịch.',
                    );
                  if (value == 'snooze')
                    _mutate(
                      () => context.read<ApiClient>().post(
                        '/finance/recurring/${r['id']}/snooze',
                      ),
                      'Đã nhắc lại vào ngày mai.',
                    );
                  if (value == 'archive')
                    _mutate(
                      () => context.read<ApiClient>().delete(
                        '/finance/recurring/${r['id']}',
                      ),
                      'Đã lưu trữ khoản định kỳ.',
                    );
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'confirm',
                    child: Text('Xác nhận giao dịch'),
                  ),
                  PopupMenuItem(
                    value: 'snooze',
                    child: Text('Nhắc lại ngày mai'),
                  ),
                  PopupMenuItem(value: 'archive', child: Text('Lưu trữ')),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(
    String label,
    dynamic value,
    IconData icon, {
    bool positive = false,
    bool negative = false,
  }) => SizedBox(
    width: 172,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(
              _money(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: positive
                    ? Colors.green
                    : negative
                    ? Colors.red
                    : null,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );

  String _money(dynamic value) => NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format((value as num?) ?? 0);
  String _typeLabel(dynamic value) => value == 'INCOME'
      ? 'Thu nhập'
      : value == 'TRANSFER'
      ? 'Chuyển khoản'
      : 'Chi tiêu';
  String _natureLabel(dynamic value) =>
      const {
        'FIXED_MANDATORY': 'Cố định bắt buộc',
        'ESSENTIAL_VARIABLE': 'Thiết yếu biến đổi',
        'TRUE_EXPENSE': 'Chi phí dự phòng',
        'SAVING': 'Tiết kiệm',
        'DISCRETIONARY': 'Linh hoạt',
      }[value] ??
      'Chưa phân loại';
}

const _natureItems = [
  DropdownMenuItem(value: 'FIXED_MANDATORY', child: Text('Cố định bắt buộc')),
  DropdownMenuItem(
    value: 'ESSENTIAL_VARIABLE',
    child: Text('Thiết yếu biến đổi'),
  ),
  DropdownMenuItem(value: 'TRUE_EXPENSE', child: Text('Chi phí dự phòng')),
  DropdownMenuItem(value: 'SAVING', child: Text('Tiết kiệm')),
  DropdownMenuItem(value: 'DISCRETIONARY', child: Text('Linh hoạt')),
];
