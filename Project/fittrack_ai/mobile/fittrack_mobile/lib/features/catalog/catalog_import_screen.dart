import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_session.dart';
import 'catalog_contract.dart';

class CatalogImportScreen extends StatefulWidget {
  const CatalogImportScreen({super.key, required this.kind});
  final String kind;
  @override
  State<CatalogImportScreen> createState() => _CatalogImportScreenState();
}

class _CatalogImportScreenState extends State<CatalogImportScreen> {
  final text = TextEditingController(), ignored = TextEditingController();
  final mappingFields = <String, TextEditingController>{};
  PlatformFile? file;
  Uint8List? fileBytes;
  Map<String, dynamic>? batch;
  List<Map<String, dynamic>> selections = [], history = [];
  bool busy = false, confirmed = false, historyVisible = false;
  bool get food => widget.kind == 'FOOD';
  List<String> get columns =>
      food ? catalogFoodColumns : catalogExerciseColumns;
  List<Map<String, dynamic>> get rows => catalogMaps(batch?['rows']);
  int get selected => selections.where((e) => e['action'] != 'SKIP').length;
  bool get committed => batch?['committedAt'] != null;
  ApiClient get api => context.read<ApiClient>();
  @override
  void initState() {
    super.initState();
    for (final column in columns) {
      mappingFields[column] = TextEditingController();
    }
  }

  @override
  void dispose() {
    text.dispose();
    ignored.dispose();
    for (final field in mappingFields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void reset() {
    setState(() {
      batch = null;
      selections = [];
      confirmed = false;
    });
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
    } catch (e) {
      message(friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pick() async {
    await run(() async {
      final next = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );
      if (next == null) return;
      if (await next.length() > 2000000) {
        message('File tối đa 2 MB. Hãy chia thành nhiều lô.');
        return;
      }
      final bytes = await next.readAsBytes();
      if (bytes.length > 2000000) {
        message('File tối đa 2 MB. Hãy chia thành nhiều lô.');
        return;
      }
      if (mounted) {
        setState(() {
          file = next;
          fileBytes = bytes;
          batch = null;
          selections = [];
          confirmed = false;
        });
      }
    });
  }

  Future<void> download(String path, String name) async {
    await run(() async {
      final response = await api.dio.get<List<int>>(
        '/catalog-imports/$path',
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Lưu file',
        fileName: name,
        bytes: Uint8List.fromList(response.data ?? []),
      );
      if (saved != null) message('Đã lưu file.');
    });
  }

  Future<void> loadHistory() async {
    await run(() async {
      final result = catalogMaps(
        await api.get(
          '/catalog-imports',
          queryParameters: {'kind': widget.kind},
        ),
      );
      if (mounted) {
        setState(() {
          history = result;
          historyVisible = true;
        });
      }
    });
  }

  Future<void> preview() async {
    await run(() async {
      if (file == null && utf8.encode(text.text).length > 2000000) {
        message('Bảng dán tối đa 2 MB.');
        return;
      }
      final mapping = <String, String>{};
      for (final entry in mappingFields.entries) {
        final header = entry.value.text.trim();
        if (header.isNotEmpty) {
          if (mapping.containsKey(header)) {
            throw const FormatException(
              'Một cột nguồn chỉ được ánh xạ tới một trường.',
            );
          }
          mapping[header] = entry.key;
        }
      }
      for (final key
          in ignored.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)) {
        if (mapping.containsKey(key)) {
          throw const FormatException(
            'Cột đã ánh xạ không thể đồng thời bỏ qua.',
          );
        }
        mapping[key] = '__IGNORE__';
      }
      final body = FormData.fromMap({
        'mapping': jsonEncode(mapping),
        if (file != null)
          'file': MultipartFile.fromBytes(fileBytes!, filename: file!.name)
        else
          'text': text.text,
      });
      final result = catalogMap(
        (await api.dio.post(
          '/catalog-imports/${widget.kind}/preview',
          data: body,
          options: Options(contentType: 'multipart/form-data'),
        )).data,
      );
      if (mounted) {
        setState(() {
          batch = result;
          selections = catalogMaps(result['rows'])
              .map(catalogDefaultSelection)
              .toList();
          confirmed = false;
        });
      }
    });
  }

  Future<void> commit() async {
    if (batch == null || !confirmed || selected == 0 || committed || busy) {
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập $selected dòng vào kho?'),
        content: const Text(
          'Các dòng đã chọn sẽ được ghi vào dữ liệu dùng chung. Đã đọc cảnh báo trùng và phần trước → sau chưa? Chưa có hoàn tác cả lô.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận ghi'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await run(() async {
      final result = catalogMap(
        await api.post(
          '/catalog-imports/${batch!['id']}/commit',
          data: {'selections': selections},
        ),
      );
      if (mounted) setState(() => batch = result);
      message('Đã xử lý lô nhập. Không gửi lại bằng lô mới.');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthSession>().user?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nhập kho')),
        body: const Center(child: Text('Chỉ admin được nhập / xuất kho.')),
      );
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text('Nhập ${food ? 'thực phẩm' : 'bài tập'}')),
        body: ListView(
          key: const ValueKey('catalog-import-list'),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tối đa 500 dòng, 2 MB; CSV UTF-8, XLSX hoặc bảng dán. Chỉ worksheet đầu; không dùng công thức, macro hay liên kết ngoài. Bản xem trước hết hạn sau 24 giờ.',
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final format in ['csv', 'xlsx'])
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => download(
                            '${widget.kind}/template?format=$format',
                            '${widget.kind}-mau.$format',
                          ),
                    child: Text('Mẫu ${format.toUpperCase()}'),
                  ),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => download(
                          '${widget.kind}/export?format=xlsx',
                          '${widget.kind}-kho.xlsx',
                        ),
                  child: const Text('Xuất kho kèm ID'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : loadHistory,
                  child: const Text('Lịch sử nhập'),
                ),
              ],
            ),
            if (busy) const LinearProgressIndicator(),
            if (historyVisible)
              ExpansionTile(
                initiallyExpanded: true,
                title: const Text('30 lô gần nhất của bạn'),
                children: [
                  if (history.isEmpty) const Text('Chưa có lịch sử.'),
                  ...history.map(
                    (item) => ListTile(
                      title: Text(
                        '${item['createdAt']} · ${item['rowCount']} dòng',
                      ),
                      subtitle: Text(
                        '${item['committedAt'] == null ? 'Đã xem trước' : 'Đã nhập ${item['importedCount']}'} · ${item['errorCount']} lỗi',
                      ),
                      trailing: IconButton(
                        tooltip: 'Lưu dòng lỗi',
                        onPressed: busy
                            ? null
                            : () => download(
                                '${item['id']}/errors.csv',
                                'dong-loi.csv',
                              ),
                        icon: const Icon(Icons.download),
                      ),
                    ),
                  ),
                ],
              ),
            OutlinedButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.attach_file),
              label: Text(file?.name ?? 'Chọn CSV / XLSX'),
            ),
            if (file != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        setState(() => file = null);
                        reset();
                      },
                child: const Text('Bỏ file để dùng bảng dán'),
              ),
            TextField(
              controller: text,
              enabled: !busy && file == null,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Dán bảng (gồm dòng tiêu đề)',
                hintText: columns.join('\t'),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => reset(),
            ),
            ExpansionTile(
              title: const Text('Ánh xạ tên cột tùy chỉnh'),
              subtitle: const Text('Dùng đúng mẫu thì để trống'),
              children: [
                ...mappingFields.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: '${catalogLabels[entry.key]} (${entry.key})',
                        hintText: 'Tên cột nguồn',
                      ),
                      onChanged: (_) => reset(),
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: ignored,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Cột bỏ qua, cách nhau bằng dấu phẩy',
              ),
              onChanged: (_) => reset(),
            ),
            const SizedBox(height: 12),
            if (food)
              const Text(
                'basis: PER_SERVING = một khẩu phần; PER_100G = theo 100 g và cần servingSizeGrams. Vi chất chưa biết để trống. Không quy đổi g ↔ ml. Đơn vị vi chất được ghi trong ánh xạ.',
              ),
            const Text(
              'Thêm: ID trống. Sửa: ID thật từ file xuất. Ô trống khi sửa GIỮ giá trị cũ; chọn xóa rõ ràng nếu muốn xóa trường tùy chọn. Xuất kho không kèm ảnh, nhập lại ô ảnh trống giữ ảnh cũ.',
            ),
            FilledButton(
              onPressed: busy || (file == null && text.text.trim().isEmpty)
                  ? null
                  : preview,
              child: const Text('Kiểm tra và xem trước'),
            ),
            if (batch != null) ...[
              const Divider(),
              Text(
                '${rows.length} dòng · ${rows.where((r) => catalogStrings(r['errors']).isNotEmpty).length} dòng lỗi · $selected chọn',
              ),
              if (!committed)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          for (final s in selections) {
                            s['action'] = 'SKIP';
                          }
                          confirmed = false;
                        }),
                  child: const Text('Bỏ chọn tất cả'),
                ),
              ...rows.map(rowCard),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => download(
                        '${batch!['id']}/errors.csv',
                        'dong-loi.csv',
                      ),
                child: const Text('Lưu các dòng lỗi'),
              ),
              if (!committed)
                CheckboxListTile(
                  value: confirmed,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => confirmed = v == true),
                  title: Text(
                    'Tôi đã đọc dữ liệu và cảnh báo trùng của $selected dòng',
                  ),
                ),
              if (committed)
                const Text(
                  'Lô đã hoàn tất. Xem kết quả từng dòng và tải lại kho để kiểm tra.',
                ),
              FilledButton(
                onPressed: busy || !confirmed || selected == 0 || committed
                    ? null
                    : commit,
                child: Text('Xác nhận nhập $selected dòng'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget rowCard(Map<String, dynamic> row) {
    final values = catalogMap(row['values']),
        before = catalogMap(row['before']),
        after = catalogMap(row['after']);
    final selection = selections.firstWhere(
      (s) => s['number'] == row['number'],
    );
    final clears = catalogStrings(selection['clearFields']);
    final errors = catalogStrings(row['errors']),
        warnings = catalogStrings(row['warnings']);
    final hasId = '${values['id'] ?? ''}'.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dòng ${row['number']}: ${values['name'] ?? '(Chưa tên)'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            DropdownButtonFormField<String>(
              key: ValueKey(
                '${batch!['id']}-${row['number']}-${selection['action']}',
              ),
              initialValue: selection['action'] as String,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: 'SKIP', child: Text('Bỏ qua')),
                DropdownMenuItem(
                  value: hasId ? 'UPDATE' : 'CREATE',
                  child: Text(hasId ? 'Cập nhật theo ID' : 'Thêm mới'),
                ),
              ],
              onChanged: busy || committed || errors.isNotEmpty
                  ? null
                  : (v) => setState(() {
                      selection['action'] = v;
                      confirmed = false;
                    }),
            ),
            ...errors.map(
              (e) => Text(
                e,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            ...warnings.map(
              (e) => Text(
                '⚠ $e',
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
            if (row['resultId'] != null)
              SelectableText('ID kết quả: ${row['resultId']}'),
            ExpansionTile(
              title: const Text('Dữ liệu trước → sau'),
              children: [
                if (values['basis'] == 'PER_100G')
                  const Text('Sau chuẩn hóa: giá trị theo một khẩu phần.'),
                ...{...before, ...values, ...after}.keys
                    .where(
                      (key) =>
                          key != 'imageUrl' ||
                          '${after[key] ?? before[key] ?? ''}'.isNotEmpty,
                    )
                    .map((key) {
                      final next = clears.contains(key)
                          ? '(Xóa giá trị)'
                          : after[key] ?? values[key] ?? before[key] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            '${catalogLabels[key] ?? key}: ${before[key] != null ? '${before[key]} → ' : ''}$next',
                          ),
                        ),
                      );
                    }),
              ],
            ),
            if (selection['action'] == 'UPDATE' && !committed)
              ExpansionTile(
                title: const Text('Xóa rõ ràng trường tùy chọn'),
                children: [
                  ...(food
                          ? [
                              ...catalogMicros,
                              'barcode',
                              'dataSourceName',
                              'imageUrl',
                            ]
                          : ['description', 'imageUrl'])
                      .map(
                        (key) => CheckboxListTile(
                          title: Text(catalogLabels[key] ?? key),
                          value: clears.contains(key),
                          onChanged: busy
                              ? null
                              : (v) => setState(() {
                                  final next = catalogStrings(
                                    selection['clearFields'],
                                  );
                                  if (v == true) {
                                    next.add(key);
                                  } else {
                                    next.remove(key);
                                  }
                                  selection['clearFields'] = next;
                                  confirmed = false;
                                }),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
