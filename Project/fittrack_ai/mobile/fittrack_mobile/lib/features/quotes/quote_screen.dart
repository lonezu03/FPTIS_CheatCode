import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

const _sourceLabels = <String, String>{
  'BOOK': 'Sách',
  'ARTICLE': 'Bài viết',
  'VIDEO': 'Video',
  'PODCAST': 'Podcast',
  'SONG': 'Bài hát',
  'MOVIE': 'Phim',
  'CONVERSATION': 'Cuộc trò chuyện',
  'SOCIAL_POST': 'Bài đăng mạng xã hội',
  'OTHER': 'Khác',
};

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> quotes = [];
  List<String> tags = [];
  String status = 'ACTIVE';
  String selectedTag = '';
  int page = 0;
  int totalPages = 0;
  bool loading = true;
  bool loadingMore = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        page = 0;
      });
    } else {
      setState(() => loadingMore = true);
    }
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.get(
          '/quotes',
          queryParameters: {
            'q': searchController.text.trim(),
            if (selectedTag.isNotEmpty) 'tag': selectedTag,
            if (status.isNotEmpty) 'status': status,
            'page': reset ? 0 : page + 1,
            'size': 20,
          },
        ),
        if (reset) api.get('/quote-tags') else Future<dynamic>.value(tags),
      ]);
      final result = Map<String, dynamic>.from(results.first as Map);
      final content = (result['content'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        quotes = reset ? content : [...quotes, ...content];
        page = (result['page'] as num?)?.toInt() ?? 0;
        totalPages = (result['totalPages'] as num?)?.toInt() ?? 0;
        if (reset) {
          tags = (results[1] as List? ?? const [])
              .map((item) => item.toString())
              .toList();
        }
        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
        loadingMore = false;
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? quote]) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuoteFormSheet(quote: quote),
    );
    if (payload == null || !mounted) return;
    final api = context.read<ApiClient>();
    try {
      final check = Map<String, dynamic>.from(
        await api.post(
          '/quotes/check-duplicate',
          data: {
            'content': payload['content'],
            if (quote != null) 'excludedId': quote['id'],
          },
        ) as Map,
      );
      if (check['duplicate'] == true && check['existingQuote'] is Map) {
        final existing = Map<String, dynamic>.from(
          check['existingQuote'] as Map,
        );
        final action = await _confirmDuplicate(existing);
        if (action == 'view') {
          if (mounted) await _showDetail(existing['id'].toString());
          return;
        }
        if (action != 'save') return;
        payload['allowDuplicate'] = true;
      }
      if (quote == null) {
        await api.post('/quotes', data: payload);
      } else {
        await api.put('/quotes/${quote['id']}', data: payload);
      }
      if (!mounted) return;
      showMessage(
        context,
        quote == null ? 'Đã lưu câu nói.' : 'Đã cập nhật câu nói.',
      );
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<String?> _confirmDuplicate(Map<String, dynamic> quote) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bạn đã lưu câu này trước đó'),
        content: Text('“${quote['content']}”'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'view'),
            child: const Text('Xem câu đã lưu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Vẫn lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeState(Map<String, dynamic> quote) async {
    final archived = quote['status'] == 'ARCHIVED';
    try {
      await context.read<ApiClient>().post(
        '/quotes/${quote['id']}/${archived ? 'restore' : 'archive'}',
      );
      if (!mounted) return;
      showMessage(
        context,
        archived ? 'Đã khôi phục câu nói.' : 'Đã lưu trữ câu nói.',
      );
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _toggleDaily(Map<String, dynamic> quote) async {
    try {
      await context.read<ApiClient>().put(
        '/quotes/${quote['id']}',
        data: {
          'content': quote['content'],
          'author': quote['author'],
          'sourceType': quote['sourceType'],
          'sourceTitle': quote['sourceTitle'],
          'sourceUrl': quote['sourceUrl'],
          'sourceLocation': quote['sourceLocation'],
          'personalNote': quote['personalNote'],
          'includeInDaily': quote['includeInDaily'] != true,
          'language': quote['language'] ?? 'vi',
          'tags': quote['tags'] ?? const <String>[],
        },
      );
      if (!mounted) return;
      showMessage(
        context,
        quote['includeInDaily'] == true
            ? 'Đã tắt hiển thị hằng ngày.'
            : 'Đã đưa vào Câu nói hôm nay.',
      );
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> quote) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa vĩnh viễn?'),
        content: const Text(
          'Câu nói và toàn bộ lịch sử xuất hiện của nó sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await context.read<ApiClient>().delete('/quotes/${quote['id']}');
      if (!mounted) return;
      showMessage(context, 'Đã xóa câu nói.');
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _showDetail(String id) async {
    try {
      final detail = Map<String, dynamic>.from(
        await context.read<ApiClient>().get('/quotes/$id') as Map,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => QuoteDetailSheet(detail: detail),
      );
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _showHistory() async {
    try {
      final result = Map<String, dynamic>.from(
        await context.read<ApiClient>().get(
          '/quotes/history',
          queryParameters: {'page': 0, 'size': 100},
        ) as Map,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => QuoteHistorySheet(
          items: (result['content'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
        ),
      );
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView(label: 'Đang mở kho câu nói...');
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
                  title: 'Kho câu nói',
                  subtitle: 'Lưu lại và đọc lại những điều đáng nhớ.',
                ),
              ),
              IconButton(
                tooltip: 'Lịch sử',
                onPressed: _showHistory,
                icon: const Icon(Icons.history),
              ),
              IconButton.filled(
                tooltip: 'Thêm câu nói',
                onPressed: _edit,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Tìm câu nói, tác giả, nguồn, ghi chú...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                onPressed: _load,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Đang dùng')),
                    DropdownMenuItem(
                      value: 'ARCHIVED',
                      child: Text('Đã lưu trữ'),
                    ),
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                  ],
                  onChanged: (value) {
                    status = value ?? 'ACTIVE';
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedTag,
                  decoration: const InputDecoration(labelText: 'Nhãn'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả')),
                    ...tags.map(
                      (tag) => DropdownMenuItem(
                        value: tag,
                        child: Text('#$tag', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    selectedTag = value ?? '';
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (quotes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 38),
                child: EmptyView(
                  icon: Icons.format_quote,
                  title: searchController.text.trim().isEmpty
                      ? 'Bạn chưa có câu nói nào'
                      : 'Không tìm thấy câu phù hợp',
                  subtitle: searchController.text.trim().isEmpty
                      ? 'Lưu lại những câu khiến bạn muốn dừng lại và suy nghĩ.'
                      : 'Hãy thử từ khóa hoặc bộ lọc khác.',
                ),
              ),
            )
          else
            ...quotes.map(
              (quote) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuoteCard(
                  quote: quote,
                  onDetail: () => _showDetail(quote['id'].toString()),
                  onEdit: () => _edit(quote),
                  onState: () => _changeState(quote),
                  onToggleDaily: () => _toggleDaily(quote),
                  onDelete: () => _delete(quote),
                ),
              ),
            ),
          if (page + 1 < totalPages)
            OutlinedButton.icon(
              onPressed: loadingMore ? null : () => _load(reset: false),
              icon: loadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(loadingMore ? 'Đang tải...' : 'Tải thêm'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onDetail,
    required this.onEdit,
    required this.onState,
    required this.onToggleDaily,
    required this.onDelete,
  });

  final Map<String, dynamic> quote;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onState;
  final VoidCallback onToggleDaily;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final quoteTags = (quote['tags'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final archived = quote['status'] == 'ARCHIVED';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'daily') onToggleDaily();
                      if (value == 'state') onState();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                      if (!archived)
                        PopupMenuItem(
                          value: 'daily',
                          child: Text(
                            quote['includeInDaily'] == true
                                ? 'Không hiển thị hằng ngày'
                                : 'Hiển thị hằng ngày',
                          ),
                        ),
                      PopupMenuItem(
                        value: 'state',
                        child: Text(archived ? 'Khôi phục' : 'Lưu trữ'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa vĩnh viễn'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '“${quote['content']}”',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.45),
              ),
              if (_text(quote['author']) != null) ...[
                const SizedBox(height: 10),
                Text(
                  '— ${quote['author']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (_text(quote['sourceTitle']) != null)
                Text(
                  '${quote['sourceTitle']}${_text(quote['sourceLocation']) == null ? '' : ' · ${quote['sourceLocation']}'}',
                  style: const TextStyle(color: Colors.black54),
                ),
              if (quoteTags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quoteTags
                      .map((tag) => Chip(label: Text('#$tag')))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      archived
                          ? 'Đã lưu trữ'
                          : quote['includeInDaily'] == true
                          ? 'Có trong câu hằng ngày'
                          : 'Không hiện hằng ngày',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: quote['content'].toString()),
                      );
                      if (context.mounted) {
                        showMessage(context, 'Đã sao chép câu nói.');
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Sao chép'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuoteFormSheet extends StatefulWidget {
  const QuoteFormSheet({super.key, this.quote});
  final Map<String, dynamic>? quote;

  @override
  State<QuoteFormSheet> createState() => _QuoteFormSheetState();
}

class _QuoteFormSheetState extends State<QuoteFormSheet> {
  late final TextEditingController content;
  late final TextEditingController author;
  late final TextEditingController sourceTitle;
  late final TextEditingController sourceUrl;
  late final TextEditingController sourceLocation;
  late final TextEditingController note;
  late final TextEditingController tags;
  String? sourceType;
  bool includeInDaily = true;
  bool advanced = false;

  @override
  void initState() {
    super.initState();
    final quote = widget.quote ?? const <String, dynamic>{};
    content = TextEditingController(text: quote['content']?.toString() ?? '');
    author = TextEditingController(text: quote['author']?.toString() ?? '');
    sourceTitle = TextEditingController(
      text: quote['sourceTitle']?.toString() ?? '',
    );
    sourceUrl = TextEditingController(
      text: quote['sourceUrl']?.toString() ?? '',
    );
    sourceLocation = TextEditingController(
      text: quote['sourceLocation']?.toString() ?? '',
    );
    note = TextEditingController(text: quote['personalNote']?.toString() ?? '');
    tags = TextEditingController(
      text: (quote['tags'] as List? ?? const []).join(', '),
    );
    sourceType = _text(quote['sourceType']);
    includeInDaily = quote['includeInDaily'] != false;
    advanced =
        sourceType != null ||
        sourceUrl.text.isNotEmpty ||
        sourceLocation.text.isNotEmpty ||
        note.text.isNotEmpty ||
        tags.text.isNotEmpty;
  }

  @override
  void dispose() {
    for (final controller in [
      content,
      author,
      sourceTitle,
      sourceUrl,
      sourceLocation,
      note,
      tags,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (content.text.trim().isEmpty) {
      showMessage(context, 'Vui lòng nhập nội dung câu nói.', error: true);
      return;
    }
    Navigator.pop(context, {
      'content': content.text.trim(),
      'author': author.text.trim(),
      'sourceType': sourceType,
      'sourceTitle': sourceTitle.text.trim(),
      'sourceUrl': sourceUrl.text.trim(),
      'sourceLocation': sourceLocation.text.trim(),
      'personalNote': note.text.trim(),
      'includeInDaily': includeInDaily,
      'language': 'vi',
      'tags': tags.text
          .split(',')
          .map((item) => item.trim().replaceFirst(RegExp(r'^#+'), ''))
          .where((item) => item.isNotEmpty)
          .take(10)
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.quote == null
                          ? 'Thêm câu nói'
                          : 'Chỉnh sửa câu nói',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    controller: content,
                    minLines: 4,
                    maxLines: 8,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Câu nói *',
                      hintText: 'Nhập câu bạn muốn lưu lại...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: author,
                    decoration: const InputDecoration(
                      labelText: 'Tác giả',
                      hintText: 'Ví dụ: Lão Tử',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sourceTitle,
                    decoration: const InputDecoration(
                      labelText: 'Tên nguồn',
                      hintText: 'Ví dụ: Đạo Đức Kinh',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => advanced = !advanced),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        advanced
                            ? '− Thu gọn thông tin'
                            : '+ Thêm nguồn, ghi chú và nhãn',
                      ),
                    ),
                  ),
                  if (advanced) ...[
                    DropdownButtonFormField<String>(
                      initialValue: sourceType,
                      decoration: const InputDecoration(
                        labelText: 'Loại nguồn',
                      ),
                      items: _sourceLabels.entries
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.key,
                              child: Text(item.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => sourceType = value,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sourceLocation,
                      decoration: const InputDecoration(
                        labelText: 'Vị trí trong nguồn',
                        hintText: 'Trang, chương hoặc mốc thời gian',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sourceUrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn nguồn',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: note,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú của tôi',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: tags,
                      decoration: const InputDecoration(
                        labelText: 'Nhãn',
                        hintText: 'triết-lý, công-việc, kỷ-luật',
                        helperText: 'Ngăn cách các nhãn bằng dấu phẩy.',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: includeInDaily,
                    onChanged: (value) =>
                        setState(() => includeInDaily = value),
                    title: const Text('Đưa vào Câu nói hôm nay'),
                    subtitle: const Text(
                      'Tham gia vòng quay hằng ngày không lặp.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu câu nói'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuoteDetailSheet extends StatelessWidget {
  const QuoteDetailSheet({super.key, required this.detail});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final quote = Map<String, dynamic>.from(detail['quote'] as Map);
    final dates = (detail['displayedDates'] as List? ?? const [])
        .map((item) => _date(item.toString()))
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết câu nói',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“${quote['content']}”',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.5),
                  ),
                  if (_text(quote['author']) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('— ${quote['author']}'),
                    ),
                ],
              ),
            ),
          ),
          if (_text(quote['sourceTitle']) != null ||
              _text(quote['sourceType']) != null) ...[
            const SizedBox(height: 18),
            const Text('Nguồn', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '${_sourceLabels[quote['sourceType']] ?? 'Nguồn khác'}${_text(quote['sourceTitle']) == null ? '' : ' · ${quote['sourceTitle']}'}${_text(quote['sourceLocation']) == null ? '' : ' · ${quote['sourceLocation']}'}',
            ),
          ],
          if (_text(quote['personalNote']) != null) ...[
            const SizedBox(height: 18),
            const Text(
              'Ghi chú của tôi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(quote['personalNote'].toString()),
          ],
          const SizedBox(height: 18),
          const Text(
            'Đã xuất hiện',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            dates.isEmpty
                ? 'Chưa từng xuất hiện trên Dashboard.'
                : dates.join(' · '),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class QuoteHistorySheet extends StatelessWidget {
  const QuoteHistorySheet({super.key, required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử câu nói',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const EmptyView(
                    icon: Icons.history,
                    title: 'Chưa có lịch sử',
                    subtitle: 'Câu nói hằng ngày sẽ xuất hiện tại đây.',
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final quote = Map<String, dynamic>.from(
                        item['quote'] as Map,
                      );
                      return Card(
                        child: ListTile(
                          title: Text('“${quote['content']}”'),
                          subtitle: Text(
                            '${_date(item['displayDate'].toString())}${_text(quote['author']) == null ? '' : ' · ${quote['author']}'}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String? _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String _date(String value) {
  final parts = value.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
}
