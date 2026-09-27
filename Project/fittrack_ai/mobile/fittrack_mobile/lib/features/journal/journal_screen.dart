import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _unlockKey = 'fittrack_journal_unlock';
  static const _storage = FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _pinController = TextEditingController();
  final _answerController = TextEditingController();
  final _promptSearchController = TextEditingController();
  int _tab = 0;
  bool _loading = true;
  bool _locked = false;
  bool _hasSavedUnlock = false;
  bool _submitting = false;
  Object? _error;
  Map<String, dynamic>? _today;
  Map<String, dynamic>? _settings;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _packs = [];
  List<Map<String, dynamic>> _prompts = [];
  int _promptPage = 0;
  int _promptTotalPages = 0;
  String _promptCategory = '';
  String _promptDepth = '';
  bool _promptsLoading = false;
  String? _mood;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pinController.dispose();
    _answerController.dispose();
    _promptSearchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final status = Map<String, dynamic>.from(
        await api.get('/journal/lock/status') as Map,
      );
      final saved = await _storage.read(key: _unlockKey);
      if (!mounted) return;
      _settings = status;
      _locked = status['lockEnabled'] == true;
      _hasSavedUnlock = saved?.isNotEmpty == true;
      if (!_locked) {
        await _loadContent();
      } else {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _loadContent() async {
    try {
      final api = context.read<ApiClient>();
      final result = await Future.wait([
        api.get('/journal/today'),
        api.get('/journal/entries', queryParameters: {'page': 0, 'size': 50}),
        api.get('/journal/settings'),
        api.get('/journal/packs'),
      ]);
      if (!mounted) return;
      final page = Map<String, dynamic>.from(result[1] as Map);
      setState(() {
        _today = Map<String, dynamic>.from(result[0] as Map);
        _entries = (page['content'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _settings = Map<String, dynamic>.from(result[2] as Map);
        _packs = (result[3] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
        _locked = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      context.read<ApiClient>().journalUnlockToken = null;
      await _storage.delete(key: _unlockKey);
      setState(() {
        _loading = false;
        _locked = _settings?['lockEnabled'] == true;
        _hasSavedUnlock = false;
        _error = _locked ? null : error;
      });
    }
  }

  Future<void> _unlockWithPin() async {
    if (_pinController.text.length < 4) return;
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiClient>();
      final result = Map<String, dynamic>.from(
        await api.post(
          '/journal/lock/unlock',
          data: {'pin': _pinController.text},
        ) as Map,
      );
      final token = result['unlockToken']?.toString() ?? '';
      api.journalUnlockToken = token;
      await _storage.write(key: _unlockKey, value: token);
      _pinController.clear();
      await _loadContent();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _unlockWithBiometric() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        throw Exception('Thiết bị chưa đăng ký sinh trắc học.');
      }
      final accepted = await _localAuth.authenticate(
        localizedReason: 'Xác thực để mở Nhật ký riêng tư',
        biometricOnly: true,
      );
      if (!accepted) return;
      final token = await _storage.read(key: _unlockKey);
      if (token == null || token.isEmpty) return;
      if (!mounted) return;
      context.read<ApiClient>().journalUnlockToken = token;
      await _loadContent();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  Future<void> _savePromptAnswer() async {
    if (_answerController.text.trim().isEmpty || _today == null) return;
    setState(() => _submitting = true);
    try {
      final prompt = Map<String, dynamic>.from(_today!['prompt'] as Map);
      await context.read<ApiClient>().post(
        '/journal/entries',
        data: {
          'origin': 'PROMPT',
          'promptId': prompt['id'],
          'body': _answerController.text.trim(),
          'mood': _mood,
        },
      );
      _answerController.clear();
      _mood = null;
      await _loadContent();
      if (mounted) showMessage(context, 'Đã lưu trang Nhật ký hôm nay.');
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _changePrompt([String? depth]) async {
    try {
      await context.read<ApiClient>().post(
        depth == null ? '/journal/today/skip' : '/journal/today/depth/$depth',
      );
      _answerController.clear();
      await _loadContent();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  Future<void> _editEntry([Map<String, dynamic>? entry]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JournalEntrySheet(entry: entry),
    );
    if (saved == true) await _loadContent();
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lưu trữ trang này?'),
        content: const Text(
          'Trang sẽ không còn xuất hiện trong lịch sử, nhưng hệ thống vẫn giữ dấu vết an toàn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lưu trữ'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await context.read<ApiClient>().delete('/journal/entries/${entry['id']}');
      await _loadContent();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(label: 'Đang mở Nhật ký...');
    if (_error != null) {
      return ErrorView(message: displayError(_error!), onRetry: _bootstrap);
    }
    if (_locked) return _lockView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              const Expanded(
                child: PageIntro(
                  title: 'Nhật ký',
                  subtitle:
                      'Không gian riêng chỉ tài khoản của bạn có thể đọc.',
                ),
              ),
              IconButton(
                tooltip: 'Cài đặt',
                onPressed: _openSettings,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Hôm nay'),
                icon: Icon(Icons.auto_awesome),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Lịch sử'),
                icon: Icon(Icons.history),
              ),
              ButtonSegment(
                value: 2,
                label: Text('Khám phá'),
                icon: Icon(Icons.library_books_outlined),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (value) {
              final next = value.first;
              setState(() => _tab = next);
              if (next == 2 && _prompts.isEmpty) {
                _loadPrompts(reset: true);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: switch (_tab) {
            0 => _todayView(),
            1 => _historyView(),
            _ => _packsView(),
          },
        ),
      ],
    );
  }

  Widget _lockView() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 80),
      const Icon(Icons.lock_outline, size: 64, color: Color(0xFF087A55)),
      const SizedBox(height: 18),
      Text(
        'Nhật ký đang được khóa',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Nhập PIN đã đặt trên FitTrack. Mã mở khóa được lưu an toàn trong thiết bị trong tối đa 12 giờ.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _pinController,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 8,
        decoration: const InputDecoration(labelText: 'PIN 4–8 chữ số'),
      ),
      FilledButton.icon(
        onPressed: _submitting ? null : _unlockWithPin,
        icon: const Icon(Icons.lock_open),
        label: const Text('Mở Nhật ký'),
      ),
      if (_hasSavedUnlock) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _unlockWithBiometric,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Mở bằng sinh trắc học'),
        ),
      ],
    ],
  );

  Widget _todayView() {
    final prompt = _today?['prompt'] is Map
        ? Map<String, dynamic>.from(_today!['prompt'] as Map)
        : null;
    final answered = _today?['answered'] == true;
    final entry = _today?['entry'] is Map
        ? Map<String, dynamic>.from(_today!['entry'] as Map)
        : null;
    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(_depthLabel(prompt?['depth']))),
                      if (prompt?['pack'] is Map)
                        Chip(
                          label: Text(
                            '${(prompt!['pack'] as Map)['icon'] ?? ''} ${(prompt['pack'] as Map)['name'] ?? ''}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    prompt?['content']?.toString() ?? '',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  if (answered && entry != null) ...[
                    Text(
                      entry['body']?.toString() ?? '',
                      style: const TextStyle(height: 1.55),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _editEntry(entry),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Viết tiếp'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _answerController,
                      minLines: 6,
                      maxLines: 12,
                      maxLength: 20000,
                      decoration: const InputDecoration(
                        hintText: 'Viết vài dòng cũng được...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    _moodPicker(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _submitting ? null : () => _changePrompt(),
                          child: const Text('Đổi câu'),
                        ),
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _changePrompt('LIGHT'),
                          child: const Text('Nhẹ hơn'),
                        ),
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _changePrompt('DEEP'),
                          child: const Text('Sâu hơn'),
                        ),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _savePromptAnswer,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Lưu'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _editEntry(),
            icon: const Icon(Icons.add),
            label: const Text('Viết tự do'),
          ),
          const SizedBox(height: 12),
          Text(
            'Gần đây',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          ..._entries.take(3).map(_entryCard),
        ],
      ),
    );
  }

  Widget _historyView() => RefreshIndicator(
    onRefresh: _loadContent,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lịch sử của tôi',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _editEntry(),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_entries.isEmpty)
          const EmptyView(
            icon: Icons.menu_book_outlined,
            title: 'Chưa có trang Nhật ký',
            subtitle: 'Viết một trang đầu tiên cho chính bạn.',
          )
        else
          ..._entries.map(_entryCard),
      ],
    ),
  );

  Future<void> _loadPrompts({bool reset = false, int? page}) async {
    if (_promptsLoading) return;
    setState(() {
      _promptsLoading = true;
      if (reset) _promptPage = 0;
      if (page != null) _promptPage = page;
    });
    try {
      final result = Map<String, dynamic>.from(
        await context.read<ApiClient>().get(
          '/journal/prompts',
          queryParameters: {
            'q': _promptSearchController.text.trim(),
            if (_promptCategory.isNotEmpty) 'category': _promptCategory,
            if (_promptDepth.isNotEmpty) 'depth': _promptDepth,
            'page': _promptPage,
            'size': 20,
          },
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _prompts = (result['content'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _promptTotalPages = (result['totalPages'] as num?)?.toInt() ?? 0;
      });
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _promptsLoading = false);
    }
  }

  Widget _packsView() {
    const categoryLabels = <String, String>{
      'OBSERVATION': 'Quan sát',
      'SELF': 'Bản thân',
      'MEMORY': 'Ký ức',
      'IMAGINATION': 'Tưởng tượng',
      'REFLECTION': 'Chiêm nghiệm',
      'RELATIONSHIP': 'Mối quan hệ',
      'FUTURE': 'Tương lai',
      'QUIRKY': 'Khác lạ',
    };
    return RefreshIndicator(
      onRefresh: () async {
        await _loadContent();
        await _loadPrompts();
      },
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Ưu tiên bộ bạn thích để câu hỏi hằng ngày gần với mình hơn.',
          ),
          const SizedBox(height: 12),
          ..._packs.map(
            (pack) => Card(
              child: ListTile(
                leading: Text(
                  pack['icon']?.toString() ?? '📚',
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(pack['name']?.toString() ?? ''),
                subtitle: Text(
                  '${pack['description'] ?? ''}\n${pack['promptCount'] ?? 0} câu',
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: pack['followed'] == true,
                  onChanged: (value) => _followPack(pack, value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Kho câu hỏi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _promptSearchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Tìm trong kho câu hỏi',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _loadPrompts(reset: true),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _promptCategory,
                  decoration: const InputDecoration(labelText: 'Chủ đề'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả')),
                    ...categoryLabels.entries.map(
                      (item) => DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _promptCategory = value ?? '';
                    _loadPrompts(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _promptDepth,
                  decoration: const InputDecoration(labelText: 'Độ sâu'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'LIGHT', child: Text('Nhẹ nhàng')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Suy ngẫm')),
                    DropdownMenuItem(value: 'DEEP', child: Text('Sâu sắc')),
                  ],
                  onChanged: (value) {
                    _promptDepth = value ?? '';
                    _loadPrompts(reset: true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _promptsLoading ? null : () => _loadPrompts(reset: true),
            icon: const Icon(Icons.manage_search),
            label: const Text('Tìm câu hỏi'),
          ),
          if (_promptsLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_prompts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Không có câu hỏi phù hợp.'),
            )
          else
            ..._prompts.map((prompt) {
              final pack = prompt['pack'];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${categoryLabels[prompt['category']] ?? prompt['category']} · ${_depthLabel(prompt['depth'])}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (pack is Map)
                        Text(
                          '${pack['icon'] ?? '📚'} ${pack['name'] ?? ''}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 8),
                      Text(prompt['content']?.toString() ?? ''),
                    ],
                  ),
                ),
              );
            }),
          if (_promptTotalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: _promptsLoading || _promptPage == 0
                      ? null
                      : () => _loadPrompts(page: _promptPage - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang ${_promptPage + 1}/$_promptTotalPages'),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed:
                      _promptsLoading || _promptPage + 1 >= _promptTotalPages
                      ? null
                      : () => _loadPrompts(page: _promptPage + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _entryCard(Map<String, dynamic> entry) => Card(
    child: ListTile(
      onTap: () => _editEntry(entry),
      title: Text(
        entry['title']?.toString() ??
            (entry['prompt'] is Map
                ? (entry['prompt'] as Map)['content']?.toString()
                : 'Một trang Nhật ký') ??
            'Một trang Nhật ký',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry['entryDate'] ?? ''}\n${entry['body'] ?? ''}',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') _editEntry(entry);
          if (value == 'delete') _deleteEntry(entry);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
          PopupMenuItem(value: 'delete', child: Text('Lưu trữ')),
        ],
      ),
    ),
  );

  Widget _moodPicker() => Wrap(
    spacing: 6,
    children:
        const [
              ('VERY_LOW', '😞'),
              ('LOW', '🙁'),
              ('NEUTRAL', '😐'),
              ('GOOD', '🙂'),
              ('VERY_GOOD', '😊'),
            ]
            .map(
              (item) => ChoiceChip(
                label: Text(item.$2),
                selected: _mood == item.$1,
                onSelected: (selected) =>
                    setState(() => _mood = selected ? item.$1 : null),
              ),
            )
            .toList(),
  );

  Future<void> _followPack(Map<String, dynamic> pack, bool follow) async {
    try {
      final api = context.read<ApiClient>();
      if (follow) {
        await api.put('/journal/packs/${pack['id']}/follow');
      } else {
        await api.delete('/journal/packs/${pack['id']}/follow');
      }
      await _loadContent();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  Future<void> _openSettings() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JournalSettingsSheet(settings: _settings ?? const {}),
    );
    if (changed == true) await _bootstrap();
  }

  static String _depthLabel(dynamic depth) => switch (depth?.toString()) {
    'LIGHT' => 'Nhẹ nhàng',
    'DEEP' => 'Sâu một chút',
    _ => 'Suy ngẫm',
  };
}

class _JournalEntrySheet extends StatefulWidget {
  const _JournalEntrySheet({this.entry});
  final Map<String, dynamic>? entry;
  @override
  State<_JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<_JournalEntrySheet> {
  late final TextEditingController title;
  late final TextEditingController body;
  late final TextEditingController tags;
  String? mood;
  List<String> images = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text: widget.entry?['title']?.toString() ?? '',
    );
    body = TextEditingController(text: widget.entry?['body']?.toString() ?? '');
    tags = TextEditingController(
      text: ((widget.entry?['tags'] as List?) ?? const []).join(', '),
    );
    mood = widget.entry?['mood']?.toString();
    images = ((widget.entry?['imageUrls'] as List?) ?? const [])
        .map((value) => value.toString())
        .toList();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final next = <String>[];
    for (final file in result.take(4 - images.length)) {
      if (await file.length() > 1024 * 1024) continue;
      final bytes = await file.readAsBytes();
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';
      next.add('data:$mime;base64,${base64Encode(bytes)}');
    }
    setState(() => images = [...images, ...next].take(4).toList());
  }

  Future<void> save() async {
    if (body.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final entry = widget.entry;
      final prompt = entry?['prompt'];
      final payload = {
        'origin': entry?['origin'] ?? 'FREEFORM',
        'promptId': prompt is Map ? prompt['id'] : null,
        'entryDate': entry?['entryDate'],
        'title': title.text.trim(),
        'body': body.text.trim(),
        'mood': mood,
        'tags': tags.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        'imageUrls': images,
      };
      if (entry == null) {
        await context.read<ApiClient>().post('/journal/entries', data: payload);
      } else {
        await context.read<ApiClient>().put(
          '/journal/entries/${entry['id']}',
          data: payload,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _image(String value) {
    if (value.startsWith('data:image/')) {
      return Image.memory(
        base64Decode(value.split(',').last),
        width: 76,
        height: 76,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      value,
      width: 76,
      height: 76,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const SizedBox(width: 76, child: Icon(Icons.broken_image_outlined)),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 18,
      right: 18,
      top: 18,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry == null ? 'Viết tự do' : 'Chỉnh sửa trang',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề (không bắt buộc)',
            ),
          ),
          TextField(
            controller: body,
            minLines: 7,
            maxLines: 14,
            maxLength: 20000,
            decoration: const InputDecoration(
              labelText: 'Bạn đang nghĩ gì?',
              alignLabelWithHint: true,
            ),
          ),
          DropdownButtonFormField<String?>(
            initialValue: mood,
            decoration: const InputDecoration(
              labelText: 'Tâm trạng (không bắt buộc)',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Không chọn')),
              DropdownMenuItem(value: 'VERY_LOW', child: Text('😞 Rất tệ')),
              DropdownMenuItem(value: 'LOW', child: Text('🙁 Không ổn')),
              DropdownMenuItem(value: 'NEUTRAL', child: Text('😐 Bình thường')),
              DropdownMenuItem(value: 'GOOD', child: Text('🙂 Tốt')),
              DropdownMenuItem(value: 'VERY_GOOD', child: Text('😊 Rất tốt')),
            ],
            onChanged: (value) => setState(() => mood = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tags,
            decoration: const InputDecoration(
              labelText: 'Nhãn, cách nhau bằng dấu phẩy',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: images.length >= 4 ? null : pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text('Thêm ảnh (${images.length}/4)'),
          ),
          if (images.isNotEmpty)
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: images
                    .asMap()
                    .entries
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () =>
                              setState(() => images.removeAt(item.key)),
                          child: _image(item.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu trang Nhật ký'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _JournalSettingsSheet extends StatefulWidget {
  const _JournalSettingsSheet({required this.settings});
  final Map<String, dynamic> settings;
  @override
  State<_JournalSettingsSheet> createState() => _JournalSettingsSheetState();
}

class _JournalSettingsSheetState extends State<_JournalSettingsSheet> {
  late bool reminder;
  late bool personalized;
  late bool ai;
  late TimeOfDay time;
  final pin = TextEditingController();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reminder = widget.settings['reminderEnabled'] == true;
    personalized = widget.settings['personalizedPromptsEnabled'] == true;
    ai = widget.settings['aiFollowUpEnabled'] == true;
    final parts = (widget.settings['reminderTime']?.toString() ?? '21:30')
        .split(':');
    time = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 21,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30,
    );
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().put(
        '/journal/settings',
        data: {
          'reminderEnabled': reminder,
          'reminderTime':
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'personalizedPromptsEnabled': personalized,
          'aiFollowUpEnabled': ai,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> togglePin() async {
    if (pin.text.length < 4) return;
    try {
      final locked = widget.settings['lockEnabled'] == true;
      final api = context.read<ApiClient>();
      if (locked) {
        await api.delete('/journal/lock/pin', data: {'pin': pin.text});
        api.journalUnlockToken = null;
        await _JournalScreenState._storage.delete(
          key: _JournalScreenState._unlockKey,
        );
      } else {
        await api.put('/journal/lock/pin', data: {'pin': pin.text});
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 18,
      right: 18,
      top: 18,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thói quen & riêng tư',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc viết nhẹ nhàng'),
            value: reminder,
            onChanged: (value) => setState(() => reminder = value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Giờ nhắc'),
            subtitle: Text(time.format(context)),
            enabled: reminder,
            onTap: () async {
              final value = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (value != null) setState(() => time = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cá nhân hóa từ hoạt động FitTrack'),
            subtitle: const Text('Chỉ hoạt động khi bạn đã đồng ý dùng AI.'),
            value: personalized,
            onChanged: (value) => setState(() => personalized = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AI gợi ý câu hỏi đào sâu'),
            value: ai,
            onChanged: (value) => setState(() => ai = value),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : save,
              child: const Text('Lưu cài đặt'),
            ),
          ),
          const Divider(height: 32),
          TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(labelText: 'PIN 4–8 chữ số'),
          ),
          OutlinedButton.icon(
            onPressed: togglePin,
            icon: Icon(
              widget.settings['lockEnabled'] == true
                  ? Icons.lock_open
                  : Icons.lock,
            ),
            label: Text(
              widget.settings['lockEnabled'] == true
                  ? 'Tắt khóa Nhật ký'
                  : 'Bật khóa Nhật ký',
            ),
          ),
        ],
      ),
    ),
  );
}
