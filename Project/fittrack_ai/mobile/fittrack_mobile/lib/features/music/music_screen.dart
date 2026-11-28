import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import 'music_tools_screen.dart';

const _instruments = {'GUITAR': 'Ghi-ta', 'FLUTE': 'Sáo trúc C5'};
const _exercises = {
  'guitar-warmup': 'Khởi động tay',
  'guitar-spider': 'Spider 1-2-3-4',
  'guitar-finger-independence': 'Độc lập ngón',
  'guitar-chord-change': 'Đổi hợp âm',
  'guitar-strumming': 'Tiết tấu quạt dây',
  'guitar-song': 'Đệm bài hát',
  'flute-warmup': 'Khởi động hơi thở',
  'flute-long-tones': 'Ngân dài',
  'flute-scale': 'Thang âm lên xuống',
  'flute-note-reading': 'Đọc nốt',
  'flute-song': 'Thổi bài hát',
};

DateTime _musicToday() {
  final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
  return DateTime.utc(vn.year, vn.month, vn.day);
}

String _date(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String _exerciseLabel(Object? key) {
  final text = key?.toString() ?? '';
  const prefix = 'guitar-one-minute-';
  if (text.startsWith(prefix)) {
    final chords = text.substring(prefix.length).split('-');
    if (chords.length == 2)
      return 'Đổi hợp âm 1 phút: ${chords.join(' ↔ ').toUpperCase()}';
  }
  return _exercises[text] ?? text;
}

String encodeMusicCsv(List<Map<String, dynamic>> rows) {
  String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (value is String &&
        (RegExp(r'^\s*[=+@-]').hasMatch(text) ||
            text.startsWith('\t') ||
            text.startsWith('\r') ||
            text.startsWith('\n'))) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  return '\ufeff${[
    ['Ngày', 'Nhạc cụ', 'Bài tập', 'Số phút', 'BPM', 'Ghi chú'],
    ...rows.map((row) => [row['practicedOn'], _instruments[row['instrument']], _exerciseLabel(row['exerciseKey']), row['minutes'], row['bpm'], row['note']]),
  ].map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String instrument = 'GUITAR';
  String? filter;
  int duration = 15,
      page = 0,
      totalPages = 0,
      revision = 0,
      summaryRevision = 0;
  DateTimeRange? range;
  bool loading = true, saving = false, exporting = false;
  Object? summaryError, historyError;
  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  Map<String, dynamic> query(int index, int size) => {
    'page': index,
    'size': size,
    if (filter != null) 'instrument': filter,
    if (range != null) 'from': _date(range!.start),
    if (range != null) 'to': _date(range!.end),
  };

  List<Map<String, dynamic>> rows(dynamic data) => (data as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  Future<void> load({bool refreshSummary = true}) async {
    final generation = ++revision;
    final api = context.read<ApiClient>();
    setState(() {
      loading = true;
      historyError = null;
      sessions = [];
      totalPages = 0;
      if (refreshSummary) summaryError = null;
    });
    Future<void> fetchSummary() async {
      final summaryGeneration = ++summaryRevision;
      try {
        final data = Map<String, dynamic>.from(
          await api.get('/music/summary') as Map,
        );
        if (mounted && summaryGeneration == summaryRevision) {
          setState(() {
            summary = data;
            summaryError = null;
          });
        }
      } catch (e) {
        if (mounted && summaryGeneration == summaryRevision) {
          setState(() => summaryError = e);
        }
      }
    }

    Future<void> fetchHistory() async {
      try {
        final data = await api.get(
          '/music/sessions',
          queryParameters: query(page, 15),
        ) as Map;
        final items = rows(data['content']);
        final pages = (data['totalPages'] as num).toInt();
        if (mounted && generation == revision)
          setState(() {
            sessions = items;
            totalPages = pages;
          });
      } catch (e) {
        if (mounted && generation == revision) setState(() => historyError = e);
      } finally {
        if (mounted && generation == revision) setState(() => loading = false);
      }
    }

    await Future.wait([
      fetchHistory(),
      if (refreshSummary || summary == null) fetchSummary(),
    ]);
  }

  Future<void> logSession({
    String? exercise,
    int? duration,
    String? selectedInstrument,
    String? initialNote,
    int? initialBpm,
  }) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _SessionEditor(
        instrument: selectedInstrument ?? instrument,
        exercise: exercise,
        minutes: duration ?? 15,
        initialNote: initialNote,
        initialBpm: initialBpm,
      ),
    );
    if (added == true && mounted) {
      page = 0;
      await load();
    }
  }

  Future<void> remove(String id) async {
    if (saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Xóa buổi luyện tập?'),
        content: const Text('Buổi này sẽ được bỏ khỏi lịch sử và thống kê.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || saving) return;
    setState(() => saving = true);
    try {
      await context.read<ApiClient>().delete(
        '/music/sessions/${Uri.encodeComponent(id)}',
      );
      if (mounted) {
        if (sessions.length == 1 && page > 0) page--;
        await load();
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> export() async {
    if (exporting) return;
    final api = context.read<ApiClient>();
    final parameters = query(0, 100);
    setState(() => exporting = true);
    try {
      final items = <Map<String, dynamic>>[];
      for (var index = 0; ; index++) {
        final data = await api.get(
          '/music/sessions',
          queryParameters: {...parameters, 'page': index},
        ) as Map;
        if (!mounted) return;
        items.addAll(rows(data['content']));
        if (items.length > 5000 ||
            (index + 1 >= 50 && index + 1 < (data['totalPages'] as num))) {
          throw StateError('Hãy chọn khoảng ngày ngắn hơn để xuất CSV.');
        }
        if (index + 1 >= (data['totalPages'] as num)) break;
      }
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Lưu lịch sử luyện tập',
        fileName: 'ancai-am-nhac-${_date(_musicToday())}.csv',
        bytes: utf8.encode(encodeMusicCsv(items)),
      );
      if (mounted && saved != null) showMessage(context, 'Đã lưu file CSV.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;
    final steps = _steps(instrument, duration, data);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Âm nhạc'),
        actions: [
          IconButton(
            tooltip: 'Công cụ âm nhạc',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MusicToolsScreen(),
                ),
              );
              if (mounted) await load();
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Luyện tập hôm nay',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _instruments.entries
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item.value),
                      selected: instrument == item.key,
                      onSelected: (_) => setState(() => instrument = item.key),
                    ),
                  )
                  .toList(),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final value in [15, 20])
                  ChoiceChip(
                    label: Text('$value phút'),
                    selected: duration == value,
                    onSelected: (_) => setState(() => duration = value),
                  ),
              ],
            ),
            for (final step in steps)
              Card(
                child: ListTile(
                  title: Text(step.title),
                  subtitle: Text(
                    '${step.minutes} phút${step.bpm == null ? '' : ' · ${step.bpm} BPM'}\n${step.how}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Bắt đầu ${step.title}',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () async {
                      final finished = await showDialog<bool>(
                        context: context,
                        builder: (_) => _PracticeTimer(step: step),
                      );
                      if (finished == true && mounted)
                        await logSession(
                          exercise: step.key,
                          duration: step.minutes,
                          selectedInstrument: step.key.startsWith('flute-')
                              ? 'FLUTE'
                              : 'GUITAR',
                          initialBpm: step.bpm,
                        );
                    },
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: () => logSession(),
              icon: const Icon(Icons.add),
              label: const Text('Ghi buổi luyện tập'),
            ),
            const SizedBox(height: 18),
            Text('Tiến độ', style: Theme.of(context).textTheme.titleLarge),
            if (summaryError != null)
              _error(summaryError!, load)
            else if (data == null)
              const LinearProgressIndicator()
            else
              _summary(data),
            const SizedBox(height: 18),
            Text('Lịch sử', style: Theme.of(context).textTheme.titleLarge),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: filter ?? '',
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Mọi nhạc cụ'),
                    ),
                    ..._instruments.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    filter = value == '' ? null : value;
                    page = 0;
                    load(refreshSummary: false);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    range == null
                        ? 'Khoảng ngày'
                        : '${_date(range!.start)} – ${_date(range!.end)}',
                  ),
                  onPressed: () async {
                    final today = _musicToday();
                    final chosen = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: today,
                      initialDateRange: range,
                    );
                    if (chosen != null && mounted) {
                      range = chosen;
                      page = 0;
                      await load(refreshSummary: false);
                    }
                  },
                ),
                if (range != null)
                  TextButton(
                    onPressed: () {
                      range = null;
                      page = 0;
                      load(refreshSummary: false);
                    },
                    child: const Text('Bỏ lọc ngày'),
                  ),
                TextButton.icon(
                  onPressed:
                      exporting ||
                          loading ||
                          historyError != null ||
                          sessions.isEmpty
                      ? null
                      : export,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(exporting ? 'Đang xuất…' : 'Xuất CSV'),
                ),
              ],
            ),
            if (loading)
              const LinearProgressIndicator()
            else if (historyError != null)
              _error(historyError!, load)
            else if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Chưa có buổi luyện tập trong bộ lọc này.'),
              ),
            for (final row in sessions)
              Card(
                child: ListTile(
                  title: Text(_exerciseLabel(row['exerciseKey'])),
                  subtitle: Text(
                    '${row['practicedOn']} · ${_instruments[row['instrument']] ?? ''} · ${row['minutes']} phút${row['bpm'] == null ? '' : ' · ${row['bpm']} BPM'}${row['note'] == null ? '' : '\n${row['note']}'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    enabled: !saving,
                    onSelected: (value) {
                      if (value == 'remove') {
                        remove(row['id'].toString());
                      } else {
                        logSession(
                          exercise: row['exerciseKey']?.toString(),
                          duration: (row['minutes'] as num).toInt(),
                          selectedInstrument: row['instrument']?.toString(),
                          initialBpm: (row['bpm'] as num?)?.toInt(),
                          initialNote: row['note']?.toString(),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'repeat',
                        child: Text('Ghi lại bài này'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Xóa buổi luyện tập'),
                      ),
                    ],
                  ),
                ),
              ),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Trang trước',
                    onPressed: loading || page == 0
                        ? null
                        : () {
                            page--;
                            load(refreshSummary: false);
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${page + 1}/$totalPages'),
                  IconButton(
                    tooltip: 'Trang sau',
                    onPressed: loading || page + 1 >= totalPages
                        ? null
                        : () {
                            page++;
                            load(refreshSummary: false);
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _error(Object error, VoidCallback retry) => ListTile(
    title: Text(displayError(error)),
    trailing: TextButton(onPressed: retry, child: const Text('Thử lại')),
  );

  Widget _summary(Map<String, dynamic> data) {
    final week = rows(data['weekByDay']);
    final best = rows(data['bestBpmByExercise']);
    int minutes(Map row) =>
        (row['guitarMinutes'] as num).toInt() +
        (row['fluteMinutes'] as num).toInt();
    final peak = week.fold<int>(
      1,
      (max, row) => minutes(row) > max ? minutes(row) : max,
    );
    final totals = data['totalMinutesByInstrument'] as Map;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data['streakDays']} ngày liên tiếp · ${data['todayMinutes']} phút hôm nay · ${data['weekMinutes']} phút / 7 ngày',
            ),
            Text(
              '${data['sessionsCount']} buổi · Ghi-ta ${totals['GUITAR'] ?? 0} phút · Sáo ${totals['FLUTE'] ?? 0} phút',
            ),
            for (final row in week)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${row['date']} · ${minutes(row)} phút'),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: minutes(row) / peak,
                      ),
                    ),
                  ],
                ),
              ),
            if (best.isNotEmpty)
              ExpansionTile(
                title: const Text('BPM tốt nhất'),
                children: [
                  for (final row in best)
                    ListTile(
                      title: Text(_exerciseLabel(row['exerciseKey'])),
                      trailing: Text('${row['bpm']} BPM'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

typedef _Step = ({String key, String title, int minutes, int? bpm, String how});

List<_Step> _steps(
  String instrument,
  int duration,
  Map<String, dynamic>? summary,
) {
  final guitar = instrument == 'GUITAR';
  final day =
      _musicToday().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  const pairs = ['Em ↔ Am', 'Am ↔ E', 'C ↔ Am', 'G ↔ Em', 'D ↔ A', 'G ↔ C'];
  const strums = ['Bốn phách xuống', 'Xuống – lên đều', 'Điệu cơ bản ↓ ↓↑ ↑↓↑'];
  const songs = [
    ('Ngôi sao lấp lánh', 'Đô Đô Sol Sol La La Sol –'),
    ('Khúc hoan ca', 'Mi Mi Fa Sol | Sol Fa Mi Rê'),
    ('Mary có chú cừu non', 'Mi Rê Đô Rê | Mi Mi Mi –'),
  ];
  final song = songs[day % songs.length];
  final keys = guitar
      ? [
          'guitar-warmup',
          day.isEven ? 'guitar-spider' : 'guitar-finger-independence',
          'guitar-chord-change',
          'guitar-strumming',
        ]
      : ['flute-warmup', 'flute-long-tones', 'flute-scale', 'flute-song'];
  final tips = guitar
      ? [
          'Xoay cổ tay, lên dây và bấm thử từng ngón.',
          'Mỗi phách một nốt, giữ ngón sát phím.',
          'Đặt cả các ngón cùng lúc, quạt bốn phách mỗi hợp âm.',
          'Quạt xuống đều tay rồi thêm nhịp lên khi đã ổn.',
        ]
      : [
          'Thở đều, bắt đầu nhẹ với nốt Sol.',
          'Ngân từ Đô đến Si, giữ tiếng đều.',
          'Thổi Đô đến Đô cao rồi quay về, mỗi phách một nốt.',
          '${song.$2}. Tập chậm từng câu, nối câu sau khi thổi đúng nốt.',
        ];
  final lengths = duration == 15 ? [2, 4, 5, 4] : [3, 5, 6, 6];
  return List.generate(keys.length, (i) {
    final best = ((summary?['bestBpmByExercise'] as List?) ?? [])
        .whereType<Map>()
        .where(
          (row) =>
              row['instrument'] == instrument && row['exerciseKey'] == keys[i],
        )
        .firstOrNull;
    final bpm = i == 0 || (!guitar && i == 1)
        ? null
        : best == null
        ? (guitar && (i == 2 || (i == 1 && day.isOdd)) ? 50 : 60)
        : ((best['bpm'] as num).toInt() + 5).clamp(40, 208).toInt();
    return (
      key: keys[i],
      title: switch (keys[i]) {
        'guitar-chord-change' => 'Đổi hợp âm ${pairs[day % pairs.length]}',
        'guitar-strumming' => 'Tiết tấu ${strums[day % strums.length]}',
        'flute-song' => 'Bài: ${song.$1}',
        _ => _exerciseLabel(keys[i]),
      },
      minutes: lengths[i],
      bpm: bpm,
      how: tips[i],
    );
  });
}

class _PracticeTimer extends StatefulWidget {
  const _PracticeTimer({required this.step});
  final _Step step;
  @override
  State<_PracticeTimer> createState() => _PracticeTimerState();
}

class _PracticeTimerState extends State<_PracticeTimer> {
  final stopwatch = Stopwatch();
  Timer? ticker;

  int get seconds => (widget.step.minutes * 60 - stopwatch.elapsed.inSeconds)
      .clamp(0, widget.step.minutes * 60)
      .toInt();

  void toggle() {
    if (stopwatch.isRunning) {
      stopwatch.stop();
      ticker?.cancel();
    } else {
      stopwatch.start();
      ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (seconds == 0) {
          stopwatch.stop();
          ticker?.cancel();
        }
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    ticker?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.step.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.step.how),
        Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      if (seconds > 0)
        FilledButton(
          onPressed: toggle,
          child: Text(stopwatch.isRunning ? 'Tạm dừng' : 'Bắt đầu'),
        ),
      if (seconds == 0)
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ghi buổi tập'),
        ),
    ],
  );
}

class _SessionEditor extends StatefulWidget {
  const _SessionEditor({
    required this.instrument,
    required this.minutes,
    this.exercise,
    this.initialNote,
    this.initialBpm,
  });
  final String instrument;
  final String? exercise, initialNote;
  final int minutes;
  final int? initialBpm;
  @override
  State<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<_SessionEditor> {
  final form = GlobalKey<FormState>();
  late String instrument = _instruments.containsKey(widget.instrument)
      ? widget.instrument
      : 'GUITAR';
  late String exercise = widget.exercise ?? _keys.first;
  late final minutes = TextEditingController(text: '${widget.minutes}');
  late final bpm = TextEditingController(
    text: widget.initialBpm?.toString() ?? '',
  );
  late final note = TextEditingController(text: widget.initialNote ?? '');
  DateTime day = _musicToday();
  bool busy = false;
  Object? error;

  Iterable<String> get _keys => _exercises.keys.where(
    (key) => key.startsWith(instrument == 'GUITAR' ? 'guitar-' : 'flute-'),
  );

  @override
  void dispose() {
    minutes.dispose();
    bpm.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<ApiClient>().post(
        '/music/sessions',
        data: {
          'instrument': instrument,
          'exerciseKey': exercise,
          'practicedOn': _date(day),
          'minutes': int.parse(minutes.text.trim()),
          'bpm': int.tryParse(bpm.text.trim()),
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Ghi buổi luyện tập'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: instrument,
                decoration: const InputDecoration(labelText: 'Nhạc cụ'),
                items: _instruments.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                        instrument = value!;
                        exercise = _keys.first;
                        bpm.clear();
                      }),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(instrument),
                initialValue: exercise,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bài tập'),
                items: {..._keys, exercise}
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(
                          _exerciseLabel(key),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => exercise = value!),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final today = _musicToday();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: day,
                          firstDate: today.subtract(const Duration(days: 365)),
                          lastDate: today,
                        );
                        if (picked != null && mounted)
                          setState(() => day = picked);
                      },
                child: Text('Ngày tập ${_date(day)}'),
              ),
              TextFormField(
                controller: minutes,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số phút luyện tập',
                ),
                validator: (value) => _number(value, 1, 600),
              ),
              TextFormField(
                controller: bpm,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'BPM (tùy chọn)'),
                validator: (value) => value?.trim().isEmpty != false
                    ? null
                    : _number(value, 20, 300),
              ),
              TextField(
                controller: note,
                enabled: !busy,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              if (error != null)
                Text(
                  displayError(error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: const Text('Lưu buổi tập'),
        ),
      ],
    ),
  );

  String? _number(String? input, int min, int max) {
    final value = int.tryParse(input?.trim() ?? '');
    return value != null && value >= min && value <= max
        ? null
        : 'Nhập số từ $min đến $max.';
  }
}
