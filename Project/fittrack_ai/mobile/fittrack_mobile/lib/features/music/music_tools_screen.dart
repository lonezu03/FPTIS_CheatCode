import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

typedef _Chord = ({String name, List<int> frets, List<int> fingers});

const _chords = <_Chord>[
  (name: 'Em', frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0]),
  (name: 'Am', frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
  (name: 'E', frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
  (name: 'C', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
  (name: 'G', frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3]),
  (name: 'D', frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
  (name: 'A', frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
  (name: 'Dm', frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
  (name: 'F', frets: [-1, -1, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1]),
  (name: 'E7', frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0]),
  (name: 'A7', frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 2, 0, 3, 0]),
  (name: 'D7', frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3]),
];
const _strings = [40, 45, 50, 55, 59, 64];
const _fluteMidi = [72, 74, 76, 77, 79, 81, 83];
const _solfege = ['Đô', 'Rê', 'Mi', 'Fa', 'Sol', 'La', 'Si'];
const _pitchNames = [
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];
const _patterns = [
  ('Bốn phách xuống', ['↓', '↓', '↓', '↓']),
  ('Xuống – lên đều', ['↓', '↑', '↓', '↑', '↓', '↑', '↓', '↑']),
  ('Điệu cơ bản', ['↓', '·', '↓', '↑', '·', '↑', '↓', '↑']),
  ('Ballad', ['↓', '·', '↓', '↑', '↓', '↑', '↓', '↑']),
];

double musicPitchHz(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();
double musicPitchCents(double hz, int midi) =>
    1200 * math.log(hz / musicPitchHz(midi)) / math.ln2;
String _pitchLabel(int midi) => '${_pitchNames[midi % 12]}${midi ~/ 12 - 1}';

class MusicToolsScreen extends StatefulWidget {
  const MusicToolsScreen({super.key});

  @override
  State<MusicToolsScreen> createState() => _MusicToolsScreenState();
}

class _MusicToolsScreenState extends State<MusicToolsScreen>
    with WidgetsBindingObserver {
  static const _audio = MethodChannel('ancai/music/audio');
  static const _pitch = EventChannel('ancai/music/pitch');

  int _tab = 0, _chord = 0, _secondChord = 1, _pattern = 0, _fluteNote = 0;
  int _bpm = 60, _beats = 4, _tick = 0, _changes = 0, _seconds = 60;
  int _longTarget = 6, _longSeconds = 0, _readNote = 0, _correct = 0;
  int? _tunerTarget;
  bool _upper = false,
      _strumming = false,
      _micActive = false,
      _checkingMic = false;
  bool _longTone = false, _reading = false, _saving = false, _saved = false;
  bool _correctCurrent = false;
  double? _heard;
  String? _error;
  Timer? _metronome, _challenge;
  final _metroClock = Stopwatch();
  final _heldNote = Stopwatch();
  final _offTune = Stopwatch();
  static const _longToneGraceMs = 400;
  StreamSubscription<dynamic>? _samples;
  int _audioGeneration = 0;
  int _consecutiveMisses = 0;

  bool get _nativeAudio =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  int get _fluteTarget => _fluteMidi[_fluteNote] + (_upper ? 12 : 0);
  List<String> get _slots =>
      _strumming ? _patterns[_pattern].$2 : List.filled(_beats, '●');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopAll();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAll();
    super.dispose();
  }

  Future<void> _play(
    List<double> frequencies, {
    int milliseconds = 420,
    bool click = false,
  }) async {
    try {
      if (_nativeAudio) {
        await _audio.invokeMethod<void>('play', {
          'frequencies': frequencies,
          'milliseconds': milliseconds,
        });
      } else if (click) {
        await SystemSound.play(SystemSoundType.click);
      }
    } on PlatformException catch (error) {
      if (mounted)
        setState(() => _error = error.message ?? 'Không phát được âm thanh.');
    } on MissingPluginException {
      if (mounted)
        setState(() => _error = 'Chưa hỗ trợ âm tham chiếu trên thiết bị này.');
    }
  }

  void _stopAll() {
    _stopMetronome();
    _challenge?.cancel();
    _challenge = null;
    _stopMic();
    if (_nativeAudio)
      unawaited(
        _audio.invokeMethod<void>('stopPlayback').catchError((Object _) {}),
      );
  }

  void _stopMetronome() {
    _metronome?.cancel();
    _metronome = null;
    _metroClock.stop();
    _metroClock.reset();
  }

  void _toggleMetronome({bool strumming = false}) {
    if (_metronome != null && _strumming == strumming) {
      setState(_stopMetronome);
      return;
    }
    _stopMetronome();
    _stopMic();
    setState(() {
      _strumming = strumming;
      _tick = 0;
      _error = null;
      _metroClock.start();
      _scheduleBeat(0);
    });
  }

  void _scheduleBeat(int index) {
    final subdivisions = _slots.length == 8 ? 2 : 1;
    final interval = 60000000 / (_bpm * subdivisions);
    final delay = math.max(
      0,
      (index * interval).round() - _metroClock.elapsedMicroseconds,
    );
    _metronome = Timer(Duration(microseconds: delay), () {
      if (!mounted) return;
      final current = math.max(
        index,
        (_metroClock.elapsedMicroseconds / interval).floor(),
      );
      setState(() => _tick = current % _slots.length);
      unawaited(
        _play([_tick == 0 ? 1500.0 : 1000.0], milliseconds: 30, click: true),
      );
      _scheduleBeat(current + 1);
    });
  }

  void _stopMic() {
    _audioGeneration++;
    final samples = _samples;
    _samples = null;
    if (samples != null) unawaited(samples.cancel());
    _heldNote.stop();
    _offTune
      ..stop()
      ..reset();
    _micActive = false;
    _longTone = false;
    _heard = null;
  }

  Future<void> _startMic({bool longTone = false}) async {
    if (_checkingMic) return;
    if (_micActive) {
      setState(_stopMic);
      return;
    }
    _stopMetronome();
    final generation = ++_audioGeneration;
    setState(() {
      _checkingMic = true;
      _error = null;
    });
    try {
      final granted = await _audio.invokeMethod<bool>('permission') ?? false;
      if (!mounted || generation != _audioGeneration) return;
      if (!granted) {
        setState(
          () => _error = 'Chưa có quyền micrô. Bạn có thể cấp quyền trong cài đặt ứng dụng.',
        );
        return;
      }
      setState(() {
        _micActive = true;
        _longTone = longTone;
        if (longTone) _longSeconds = 0;
        _heldNote.reset();
      });
      _samples = _pitch.receiveBroadcastStream().listen(
        _onPitch,
        onError: (Object error) {
          if (!mounted || generation != _audioGeneration) return;
          setState(() {
            _stopMic();
            _error = 'Không đọc được micrô. Kiểm tra quyền rồi thử lại.';
          });
        },
        // The native side may close the stream (app hidden, mic taken by a call):
        // never leave the screen claiming it is still listening.
        onDone: () {
          if (!mounted || generation != _audioGeneration) return;
          setState(_stopMic);
        },
      );
    } on PlatformException {
      if (mounted) setState(() => _error = 'Không thể bắt đầu đo cao độ.');
    } on MissingPluginException {
      if (mounted)
        setState(() => _error = 'Thiết bị chưa hỗ trợ đo cao độ trong app.');
    } finally {
      if (mounted) setState(() => _checkingMic = false);
    }
  }

  void _onPitch(dynamic value) {
    if (!mounted || !_micActive) return;
    final hz = value is num && value > 0 ? value.toDouble() : null;
    setState(() {
      _heard = hz;
      if (_reading &&
          _tab == 1 &&
          hz != null &&
          !_correctCurrent &&
          musicPitchCents(hz, _fluteMidi[_readNote]).abs() <= 35) {
        _correctCurrent = true;
        _correct++;
      }
      if (_longTone) {
        final inTune =
            hz != null && musicPitchCents(hz, _fluteTarget).abs() <= 35;
        if (inTune) {
          _offTune.stop();
          _offTune.reset();
          _heldNote.start();
          _longSeconds = math.max(_longSeconds, _heldNote.elapsed.inSeconds);
        } else if (_heldNote.isRunning) {
          // A beginner's tone wavers for a frame or two; only a break longer
          // than the grace period ends the held note.
          _offTune.start();
          if (_offTune.elapsedMilliseconds > _longToneGraceMs) {
            _heldNote.stop();
            _heldNote.reset();
            _offTune.stop();
            _offTune.reset();
          }
        }
      }
    });
  }

  void _finishLongTone() {
    setState(() {
      _stopMic();
      if (_longSeconds >= _longTarget) {
        _longTarget = math.min(30, _longTarget + 1);
        _consecutiveMisses = 0;
      } else if (++_consecutiveMisses >= 2) {
        _longTarget = math.max(4, _longTarget - 1);
        _consecutiveMisses = 0;
      }
    });
  }

  void _startChallenge() {
    if (_chord == _secondChord) return;
    final clock = Stopwatch()..start();
    setState(() {
      _saved = false;
      _seconds = 60;
      _changes = 0;
      _challenge = Timer.periodic(const Duration(milliseconds: 250), (timer) {
        if (!mounted) return;
        setState(() {
          _seconds = math.max(0, 60 - clock.elapsed.inSeconds);
          if (_seconds == 0) {
            timer.cancel();
            _challenge = null;
          }
        });
      });
    });
  }

  Future<void> _saveChallenge() async {
    if (_saved || _saving || _seconds != 0) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final first = _chords[_chord].name.toLowerCase();
    final second = _chords[_secondChord].name.toLowerCase();
    try {
      await context.read<ApiClient>().post(
        '/music/sessions',
        data: {
          'instrument': 'GUITAR',
          'practicedOn': DateFormat('yyyy-MM-dd')
              .format(DateTime.now().toUtc().add(const Duration(hours: 7))),
          'minutes': 1,
          'exerciseKey': 'guitar-one-minute-$first-$second',
          'bpm': _changes >= 20 && _changes <= 300 ? _changes : null,
          'note': '$_changes lần chuyển sạch trong 1 phút.',
        },
      );
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) setState(() => _error = displayError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Công cụ âm nhạc')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Ghi-ta')),
            ButtonSegment(value: 1, label: Text('Sáo C5')),
            ButtonSegment(value: 2, label: Text('Nhịp')),
          ],
          selected: {_tab},
          onSelectionChanged: (value) => setState(() {
            _stopAll();
            _tab = value.single;
            _tunerTarget = null;
            _error = null;
            _reading = false;
          }),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_tab == 0) ..._guitar(),
        if (_tab == 1) ..._flute(),
        if (_tab == 2) _metronomePanel(),
      ],
    ),
  );

  Widget _card(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(top: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  DropdownButtonFormField<int> _choose(
    int initial,
    String label,
    List<String> options,
    ValueChanged<int>? onChanged,
  ) => DropdownButtonFormField<int>(
    key: ValueKey((label, initial)),
    initialValue: initial,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: List.generate(
      options.length,
      (i) => DropdownMenuItem(value: i, child: Text(options[i])),
    ),
    onChanged: onChanged == null
        ? null
        : (i) {
            if (i != null) onChanged(i);
          },
  );

  List<Widget> _guitar() {
    final chord = _chords[_chord];
    final editable = _challenge == null && !_saving;
    return [
      _card('Thế bấm hợp âm', [
        _choose(
          _chord,
          'Hợp âm',
          _chords.map((item) => item.name).toList(),
          editable
              ? (i) => setState(() {
                  _chord = i;
                  _seconds = 60;
                })
              : null,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 6; i++)
          Text(
            'Dây ${6 - i} · ${switch (chord.frets[i]) {
              -1 => 'Bỏ qua',
              0 => 'Buông',
              final fret => 'Ngăn $fret, ngón ${chord.fingers[i]}',
            }}',
          ),
        if (chord.name == 'F')
          const Text('Ngón trỏ chặn hai dây cao ở ngăn 1.'),
        if (_nativeAudio)
          OutlinedButton.icon(
            onPressed: () => _play([
              for (var i = 0; i < 6; i++)
                if (chord.frets[i] >= 0)
                  musicPitchHz(_strings[i] + chord.frets[i]),
            ]),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Nghe hợp âm'),
          ),
      ]),
      _card('Đổi hợp âm trong 1 phút', [
        Text('Hợp âm đầu ${chord.name}'),
        _choose(
          _secondChord,
          'Hợp âm tiếp theo',
          _chords.map((item) => item.name).toList(),
          editable
              ? (i) => setState(() {
                  _secondChord = i;
                  _seconds = 60;
                })
              : null,
        ),
        Text('Còn $_seconds giây · $_changes lần chuyển sạch'),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: editable && _chord != _secondChord
                  ? _startChallenge
                  : null,
              child: const Text('Bắt đầu 60 giây'),
            ),
            OutlinedButton(
              onPressed: _challenge == null
                  ? null
                  : () => setState(() => _changes++),
              child: const Text('+1 lần chuyển'),
            ),
            if (_seconds == 0)
              OutlinedButton(
                onPressed: _saved || _saving ? null : _saveChallenge,
                child: Text(_saved ? 'Đã lưu' : 'Lưu buổi tập'),
              ),
          ],
        ),
      ]),
      _card('Luyện ngón', [
        const Text(
          'Spider: bấm ngăn 5–6–7–8 theo ngón 1–2–3–4 trên từng dây từ dây 6 đến dây 1, rồi đi ngược.',
        ),
        const Text(
          'Độc lập ngón: thử thứ tự 1–3–2–4. Bắt đầu 50–60 BPM, tập chậm để từng dây kêu rõ.',
        ),
      ]),
      _card('Tiết tấu quạt dây', [
        _choose(
          _pattern,
          'Mẫu tiết tấu',
          _patterns.map((item) => item.$1).toList(),
          (i) => setState(() {
            _stopMetronome();
            _pattern = i;
          }),
        ),
        const Text('↓ quạt xuống · ↑ quạt lên · · lướt tay, không chạm dây'),
        _metronomeControls(strumming: true),
      ]),
      _tuner(_strings),
    ];
  }

  List<Widget> _flute() => [
    _card('Thế bấm sáo Đô sáu lỗ', [
      _choose(
        _fluteNote,
        'Nốt',
        _solfege,
        _longTone
            ? null
            : (i) => setState(() {
                _fluteNote = i;
                _longSeconds = 0;
              }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Quãng cao'),
        value: _upper,
        onChanged: _longTone
            ? null
            : (value) => setState(() {
                _upper = value;
                _longSeconds = 0;
              }),
      ),
      Text(
        '${_pitchLabel(_fluteTarget)} · ${musicPitchHz(_fluteTarget).toStringAsFixed(1)} Hz',
      ),
      const Text('Lỗ 1 gần miệng thổi. Lỗ tô đậm cần bịt kín.'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(6, (i) {
          final covered = i < 6 - _fluteNote;
          return Semantics(
            label: 'Lỗ ${i + 1} ${covered ? 'bịt' : 'mở'}',
            child: CircleAvatar(
              backgroundColor: covered
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text('${i + 1}'),
            ),
          );
        }),
      ),
      if (_nativeAudio)
        OutlinedButton.icon(
          onPressed: () => _play([musicPitchHz(_fluteTarget)]),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Nghe nốt mẫu'),
        ),
      const Text(
        'Thế bấm có thể khác nhẹ tùy cây sáo. Quãng cao dùng luồng hơi nhanh và khe môi hẹp hơn.',
      ),
    ]),
    _card('Ngân dài', [
      Text(
        'Thổi nốt ${_pitchLabel(_fluteTarget)} đều hơi. Mục tiêu $_longTarget giây · tốt nhất lần này $_longSeconds giây.',
      ),
      if (_nativeAudio)
        FilledButton(
          onPressed: _checkingMic || (_micActive && !_longTone)
              ? null
              : _longTone
              ? _finishLongTone
              : () {
                  _reading = false;
                  unawaited(_startMic(longTone: true));
                },
          child: Text(_longTone ? 'Kết thúc đo' : 'Đo bằng micrô'),
        ),
      const Text('Dừng và nghỉ nếu thấy choáng hoặc khó chịu.'),
    ]),
    _card('Đọc nốt', [
      Text(
        'Nốt cần thổi: ${_solfege[_readNote]} (${_pitchLabel(_fluteMidi[_readNote])}) · đúng $_correct nốt',
      ),
      if (_correctCurrent) const Text('Đúng cao độ.'),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => setState(() {
              _readNote = (_readNote + 1 + math.Random().nextInt(6)) % 7;
              _correctCurrent = false;
            }),
            child: const Text('Nốt khác'),
          ),
          if (_nativeAudio)
            FilledButton(
              onPressed: _checkingMic || _longTone || (_micActive && !_reading)
                  ? null
                  : () {
                      _reading = true;
                      unawaited(_startMic());
                    },
              child: Text(
                _micActive && _reading
                    ? 'Dừng kiểm tra'
                    : 'Kiểm tra bằng micrô',
              ),
            ),
        ],
      ),
    ]),
    _card('Thang âm và bài tập', [
      const Text(
        'Đô – Rê – Mi – Fa – Sol – La – Si – Đô cao, rồi đi ngược. Một nốt mỗi phách.',
      ),
      const SizedBox(height: 8),
      const Text('Ngôi sao lấp lánh'),
      const Text(
        'Đô Đô Sol Sol La La Sol —\nFa Fa Mi Mi Rê Rê Đô —\nSol Sol Fa Fa Mi Mi Rê —\nSol Sol Fa Fa Mi Mi Rê —\nĐô Đô Sol Sol La La Sol —\nFa Fa Mi Mi Rê Rê Đô —',
      ),
    ]),
    _tuner([
      for (final midi in _fluteMidi) midi,
      for (final midi in _fluteMidi) midi + 12,
    ]),
  ];

  Widget _tuner(List<int> targets) {
    final heard = _heard;
    final midi =
        _tunerTarget ??
        (heard == null
            ? targets.first
            : targets.reduce(
                (a, b) =>
                    musicPitchCents(heard, a).abs() <=
                        musicPitchCents(heard, b).abs()
                    ? a
                    : b,
              ));
    final cents = heard == null ? null : musicPitchCents(heard, midi);
    return _card('Kiểm tra cao độ', [
      _choose(
        _tunerTarget == null ? 0 : targets.indexOf(_tunerTarget!) + 1,
        'Nốt đích',
        ['Tự chọn nốt gần nhất', ...targets.map(_pitchLabel)],
        (i) => setState(() => _tunerTarget = i == 0 ? null : targets[i - 1]),
      ),
      Text(
        'Đích ${_pitchLabel(midi)} · ${musicPitchHz(midi).toStringAsFixed(1)} Hz',
      ),
      if (_nativeAudio)
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: _micActive ? null : () => _play([musicPitchHz(midi)]),
              child: const Text('Nghe âm mẫu'),
            ),
            FilledButton(
              onPressed: _checkingMic || _longTone || (_reading && _micActive)
                  ? null
                  : () {
                      _reading = false;
                      unawaited(_startMic());
                    },
              child: Text(_micActive ? 'Tắt micrô' : 'Bật micrô'),
            ),
          ],
        )
      else
        const Text('Đo bằng micrô hiện có trên bản Android.'),
      if (_micActive)
        Text(
          cents == null
              ? 'Đang nghe. Hãy chơi một nốt rõ.'
              : '${heard!.toStringAsFixed(1)} Hz · ${cents.abs().toStringAsFixed(0)} cents · ${cents.abs() <= 8
                    ? 'Đúng cao độ'
                    : cents < 0
                    ? 'Thấp hơn nốt đích'
                    : 'Cao hơn nốt đích'}',
        ),
    ]);
  }

  Widget _metronomePanel() => _card('Máy đếm nhịp', [
    _choose(
      [2, 3, 4, 6].indexOf(_beats),
      'Số phách',
      ['2', '3', '4', '6'],
      (i) => setState(() {
        _stopMetronome();
        _beats = [2, 3, 4, 6][i];
      }),
    ),
    _metronomeControls(),
    if (!_nativeAudio)
      const Text('Âm bíp phụ thuộc cài đặt âm thanh của thiết bị.'),
  ]);

  Widget _metronomeControls({bool strumming = false}) {
    final running = _metronome != null && _strumming == strumming;
    final slots = strumming ? _patterns[_pattern].$2 : List.filled(_beats, '●');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_bpm BPM'),
        Slider(
          label: '$_bpm BPM',
          value: _bpm.toDouble(),
          min: 30,
          max: 240,
          divisions: 210,
          onChanged: (value) => setState(() => _bpm = value.round()),
          // Restart once the thumb is released, not on every drag frame, so the
          // beat does not stutter back to 1 while the tempo is being chosen.
          onChangeEnd: (_) {
            if (running) {
              _stopMetronome();
              _toggleMetronome(strumming: strumming);
            }
          },
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(
            slots.length,
            (i) => Chip(
              backgroundColor: running && _tick == i
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              label: Text('${i + 1} ${slots[i]}'),
            ),
          ),
        ),
        FilledButton(
          onPressed: () => _toggleMetronome(strumming: strumming),
          child: Text(running ? 'Dừng nhịp' : 'Bắt đầu nhịp'),
        ),
      ],
    );
  }
}
