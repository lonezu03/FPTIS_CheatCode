import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_session.dart';
import 'catalog_contract.dart';
import 'catalog_image.dart';
import 'catalog_import_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(kind == 'FOOD' ? 'Kho thực phẩm' : 'Kho bài tập'),
    ),
    body: CatalogBrowser(kind: kind),
  );
}

/// Server paging is shared by the library and the exercise picker. Selection
/// remains keyed by ID across search/page changes, not only the visible page.
class CatalogBrowser extends StatefulWidget {
  const CatalogBrowser({
    super.key,
    required this.kind,
    this.onSelected,
    this.multiple = false,
  });
  final String kind;
  final ValueChanged<List<Map<String, dynamic>>>? onSelected;
  final bool multiple;
  @override
  State<CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<CatalogBrowser> {
  final search = TextEditingController();
  final selected = <String, Map<String, dynamic>>{};
  Timer? debounce;
  List<Map<String, dynamic>> rows = [];
  List<String> muscles = [], tools = [];
  String? muscle, equipment, error;
  int page = 0, totalPages = 0, total = 0, generation = 0;
  bool loading = true, inactive = false, mine = false;
  bool get exercise => widget.kind == 'EXERCISE';
  bool get picker => widget.onSelected != null;
  bool get admin => context.read<AuthSession>().user?.isAdmin == true;
  String get base => exercise ? '/exercises' : '/foods';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
      if (exercise) facets();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> facets() async {
    try {
      final data = catalogMap(
        await context.read<ApiClient>().get('/exercises/facets'),
      );
      if (mounted) {
        setState(() {
          muscles = catalogStrings(data['muscleGroups']);
          tools = catalogStrings(data['equipment']);
        });
      }
    } catch (_) {
      /* Main request remains usable; retry also reloads facets. */
    }
  }

  Future<void> load() async {
    final ticket = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await context.read<ApiClient>().get(
        mine ? '$base/mine' : '$base/page',
        queryParameters: mine
            ? null
            : {
                'page': page,
                'size': 20,
                'keyword': search.text.trim(),
                if (!picker && admin) 'includeInactive': inactive,
                if (exercise && muscle != null) 'muscleGroup': muscle,
                if (exercise && equipment != null) 'equipment': equipment,
              },
      );
      if (!mounted || ticket != generation) return;
      final result = catalogMap(data);
      setState(() {
        rows = mine ? catalogMaps(data) : catalogMaps(result['content']);
        if (picker) rows = rows.where(catalogSelectableExercise).toList();
        totalPages = mine ? 1 : (result['totalPages'] as num?)?.toInt() ?? 0;
        total = mine
            ? rows.length
            : (result['totalElements'] as num?)?.toInt() ?? 0;
        loading = false;
      });
    } catch (e) {
      if (mounted && ticket == generation) {
        setState(() {
          error = friendlyErrorMessage(e);
          loading = false;
        });
      }
    }
  }

  void filterChanged() {
    page = 0;
    load();
  }

  Future<void> edit([Map<String, dynamic>? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _CatalogEditor(kind: widget.kind, item: item, admin: admin),
      ),
    );
    if (changed == true && mounted) load();
  }

  Future<void> detail(Map<String, dynamic> item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if ('${item['imageUrl'] ?? ''}'.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CatalogImage(
                      '${item['imageUrl']}',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (exercise) ...[
                  Text('Nhóm cơ: ${item['muscleGroup'] ?? 'Chưa có'}'),
                  Text('Dụng cụ: ${item['equipment'] ?? 'Chưa có'}'),
                  const SizedBox(height: 12),
                  Text('${item['description'] ?? 'Chưa có hướng dẫn'}'),
                ] else ...[
                  Text(
                    'Khẩu phần: ${item['unit'] ?? 'Chưa có'} · ${item['servingSizeGrams'] ?? '?'} ${'${item['unit']}'.toLowerCase().contains('ml') ? 'ml' : 'g'}',
                  ),
                  Text(
                    'Nguồn: ${item['dataSourceName'] ?? 'Chưa khai báo'} (${item['dataSourceType'] ?? 'UNKNOWN'})',
                  ),
                  Text(
                    item['verified'] == true ? 'Đã xác minh' : 'Chưa xác minh',
                  ),
                  Text(catalogCoverage(item)),
                  const Text(
                    'Giá trị trống là chưa biết, không phải bằng 0. Không tự quy đổi g ↔ ml.',
                  ),
                  const Divider(),
                  ...catalogNutrients.map(
                    (key) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${catalogLabels[key]}: ${item[key] ?? 'Chưa biết'} / khẩu phần',
                      ),
                    ),
                  ),
                  if ((item['servingSizeGrams'] as num?)?.toDouble().isFinite ==
                          true &&
                      (item['servingSizeGrams'] as num) > 0) ...[
                    const Divider(),
                    Text(
                      'Theo 100 ${'${item['unit']}'.toLowerCase().contains('ml') ? 'ml' : 'g'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...catalogNutrients.map(
                      (key) => Text(
                        '${catalogLabels[key]}: ${item[key] is num ? ((item[key] as num) * 100 / (item['servingSizeGrams'] as num)).toStringAsFixed(2) : 'Chưa biết'}',
                      ),
                    ),
                  ],
                ],
                const Divider(),
                Text(
                  'Trạng thái: ${item['active'] == true ? 'Đang dùng' : 'Lưu trữ'} · ${item['approvalStatus'] ?? ''}',
                ),
                if (item['adminNote'] != null)
                  Text('Phản hồi: ${item['adminNote']}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> archive(Map<String, dynamic> item) async {
    final restore = item['active'] != true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restore ? 'Khôi phục mục này?' : 'Lưu trữ mục này?'),
        content: Text('${item['name']}\nDữ liệu lịch sử được giữ nguyên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      final api = context.read<ApiClient>();
      if (restore) {
        await api.dio.patch('$base/${item['id']}/restore');
      } else {
        await api.delete('$base/${item['id']}');
      }
      if (mounted) load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: search,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm (có hoặc không dấu)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                debounce?.cancel();
                debounce = Timer(
                  const Duration(milliseconds: 350),
                  filterChanged,
                );
              },
            ),
            if (exercise)
              Wrap(
                spacing: 8,
                children: [
                  _filter('Nhóm cơ', muscles, muscle, (v) {
                    muscle = v;
                    filterChanged();
                  }),
                  _filter('Dụng cụ', tools, equipment, (v) {
                    equipment = v;
                    filterChanged();
                  }),
                ],
              ),
            if (!picker)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => edit(),
                    icon: const Icon(Icons.add),
                    label: Text(admin ? 'Thêm mới' : 'Gửi đề xuất duyệt'),
                  ),
                  if (admin)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CatalogImportScreen(kind: widget.kind),
                          ),
                        );
                        if (mounted) load();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Nhập / xuất'),
                    ),
                  if (admin)
                    FilterChip(
                      label: const Text('Cả lưu trữ'),
                      selected: inactive,
                      onSelected: (v) {
                        setState(() => inactive = v);
                        filterChanged();
                      },
                    ),
                  if (!admin)
                    FilterChip(
                      label: const Text('Đề xuất của tôi'),
                      selected: mine,
                      onSelected: (v) {
                        setState(() => mine = v);
                        filterChanged();
                      },
                    ),
                ],
              ),
            if (picker && widget.multiple)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => widget.onSelected!(selected.values.toList()),
                  child: Text('Chọn ${selected.length} bài'),
                ),
              ),
          ],
        ),
      ),
      if (loading) const LinearProgressIndicator(),
      Expanded(
        child: error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      TextButton(
                        onPressed: () {
                          load();
                          if (exercise) facets();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: rows.isEmpty ? 1 : rows.length,
                  itemBuilder: (context, index) {
                    if (rows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Không có dữ liệu phù hợp.'),
                      );
                    }
                    final item = rows[index];
                    final id = '${item['id']}';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ('${item['imageUrl'] ?? ''}'.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: CatalogImage(
                                      '${item['imageUrl']}',
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['name']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        exercise
                                            ? '${item['muscleGroup'] ?? ''} · ${item['equipment'] ?? ''}'
                                            : '${item['unit'] ?? ''} · ${item['calories'] ?? '?'} kcal',
                                      ),
                                      if (!exercise)
                                        Text(catalogCoverage(item)),
                                      if (mine)
                                        Text(
                                          'Duyệt: ${item['approvalStatus']}',
                                        ),
                                    ],
                                  ),
                                ),
                                if (picker)
                                  Checkbox(
                                    value: selected.containsKey(id),
                                    onChanged: (_) {
                                      if (!widget.multiple) {
                                        widget.onSelected!([item]);
                                        return;
                                      }
                                      setState(() {
                                        if (selected.containsKey(id)) {
                                          selected.remove(id);
                                        } else {
                                          selected[id] = item;
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                TextButton(
                                  onPressed: () => detail(item),
                                  child: const Text('Chi tiết'),
                                ),
                                if (admin && !picker) ...[
                                  TextButton(
                                    onPressed: () => edit(item),
                                    child: const Text('Sửa'),
                                  ),
                                  TextButton(
                                    onPressed: () => archive(item),
                                    child: Text(
                                      item['active'] == true
                                          ? 'Lưu trữ'
                                          : 'Khôi phục',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      if (!mine)
        SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: loading || page == 0
                    ? null
                    : () {
                        page--;
                        load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Text(
                  '${page + 1}/${totalPages == 0 ? 1 : totalPages} · $total mục',
                ),
              ),
              IconButton(
                onPressed: loading || page + 1 >= totalPages
                    ? null
                    : () {
                        page++;
                        load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
    ],
  );
  Widget _filter(
    String label,
    List<String> values,
    String? value,
    ValueChanged<String?> change,
  ) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 250),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        ...values.toSet().map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(e, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: change,
    ),
  );
}

class _CatalogEditor extends StatefulWidget {
  const _CatalogEditor({required this.kind, required this.admin, this.item});
  final String kind;
  final bool admin;
  final Map<String, dynamic>? item;
  @override
  State<_CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends State<_CatalogEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool busy = false, verified = false;
  bool get food => widget.kind == 'FOOD';
  @override
  void initState() {
    super.initState();
    for (final key
        in (food ? catalogFoodColumns : catalogExerciseColumns).where(
          (e) => e != 'id' && e != 'basis',
        )) {
      fields[key] = TextEditingController(
        text: widget.item?[key]?.toString() ?? '',
      );
    }
    verified = widget.item?['verified'] == true;
  }

  @override
  void dispose() {
    for (final value in fields.values) {
      value.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    final payload = <String, dynamic>{};
    for (final entry in fields.entries) {
      final v = entry.value.text.trim();
      payload[entry.key] =
          catalogNutrients.contains(entry.key) ||
              entry.key == 'servingSizeGrams'
          ? (v.isEmpty ? null : double.parse(v.replaceAll(',', '.')))
          : (v.isEmpty ? null : v);
    }
    if (food) payload['verified'] = verified;
    try {
      final base = food ? '/foods' : '/exercises';
      final api = context.read<ApiClient>();
      if (widget.item != null) {
        await api.put('$base/${widget.item!['id']}', data: payload);
      } else {
        await api.post(
          widget.admin ? base : '$base/suggestions',
          data: payload,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.admin
                  ? 'Đã lưu vào kho'
                  : 'Đã gửi đề xuất, chờ admin duyệt',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.item == null
            ? 'Thêm ${food ? 'thực phẩm' : 'bài tập'}'
            : 'Chỉnh sửa',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (food)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Nhập dinh dưỡng theo MỘT khẩu phần. Vi chất chưa biết để trống; không thay bằng 0. Kích thước khẩu phần theo g hoặc ml đúng đơn vị, không quy đổi giữa hai loại.',
              ),
            ),
          ...fields.entries.map((entry) {
            final numeric =
                catalogNutrients.contains(entry.key) ||
                entry.key == 'servingSizeGrams';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: entry.value,
                enabled: !busy,
                maxLines: entry.key == 'description' ? 4 : 1,
                maxLength: entry.key == 'description'
                    ? 2000
                    : entry.key == 'imageUrl'
                    ? null
                    : entry.key == 'barcode'
                    ? 80
                    : entry.key == 'unit'
                    ? 100
                    : entry.key == 'dataSourceType'
                    ? 30
                    : entry.key == 'muscleGroup' || entry.key == 'equipment'
                    ? 120
                    : 255,
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : null,
                decoration: InputDecoration(
                  labelText: catalogLabels[entry.key] ?? entry.key,
                  helperText: entry.key == 'dataSourceType'
                      ? 'Ví dụ: ESTIMATED, LABEL, DATABASE'
                      : null,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (entry.key == 'name' && v.isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  if (numeric && v.isNotEmpty) {
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null ||
                        !n.isFinite ||
                        n < 0 ||
                        (entry.key == 'servingSizeGrams' && n == 0)) {
                      return 'Nhập số ${entry.key == 'servingSizeGrams' ? 'lớn hơn' : 'từ'} 0';
                    }
                  }
                  return null;
                },
              ),
            );
          }),
          if (food && widget.admin)
            CheckboxListTile(
              value: verified,
              onChanged: busy
                  ? null
                  : (v) => setState(() => verified = v == true),
              title: const Text('Đã xác minh nguồn dữ liệu'),
            ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              busy
                  ? 'Đang lưu…'
                  : widget.admin
                  ? 'Lưu'
                  : 'Gửi admin duyệt',
            ),
          ),
        ],
      ),
    ),
  );
}
