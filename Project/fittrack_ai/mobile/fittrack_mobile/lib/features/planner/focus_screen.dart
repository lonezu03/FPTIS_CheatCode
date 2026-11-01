import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/notifications/native_notification_service.dart';
import '../../core/widgets/common_widgets.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final title = TextEditingController(),
      minutes = TextEditingController(text: '25');
  Map<String, dynamic>? active;
  List<Map<String, dynamic>> history = [], todos = [];
  String mode = 'FOCUS', todoId = '', pendingFingerprint = '', pendingId = '';
  Object? error;
  Object? activeError, historyError, todosError;
  bool loading = true, busy = false;
  bool activeKnown = false, historyLoaded = false;
  bool uncertainWrite = false;
  String? uncertainPath;
  Map<String, dynamic>? uncertainBody;
  final Map<String, Future<void>> requests = {};
  bool notifyWhenDone = false;
  final Set<String> notifiedSessions = {};
  int loadGeneration = 0;
  DateTime fetchedAt = DateTime.now();
  Timer? tick, refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        notifyIfComplete();
      }
    });
    refresh = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !busy) load(silent: true);
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    refresh?.cancel();
    title.dispose();
    minutes.dispose();
    super.dispose();
  }

  String get today =>
      DateFormat('yyyy-MM-dd')
          .format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  Future<void> runRequest(
    String key,
    Future<void> Function() work, {
    bool force = false,
  }) async {
    final previous = requests[key];
    if (previous != null) {
      await previous;
      if (!force || !mounted) return;
    }
    final operation = work();
    requests[key] = operation;
    try {
      await operation;
    } finally {
      if (identical(requests[key], operation)) requests.remove(key);
    }
  }

  Future<void> load({bool silent = false}) async {
    if (silent && busy) return;
    await Future.wait([refreshActive(), refreshHistory(), refreshTodos()]);
  }

  Future<void> refreshActive({bool force = false}) =>
      runRequest('active', () async {
        final generation = loadGeneration;
        if (!activeKnown && mounted)
          setState(() {
            loading = true;
            activeError = null;
          });
        try {
          final value = await context.read<ApiClient>().get(
            '/todos/focus/active',
          );
          if (!mounted || generation != loadGeneration) return;
          setState(() {
            active = value is Map ? Map<String, dynamic>.from(value) : null;
            fetchedAt = DateTime.now();
            activeKnown = true;
            activeError = null;
            loading = false;
          });
        } catch (e) {
          if (!mounted || generation != loadGeneration) return;
          setState(() {
            // A stale empty result must not permit starting another session.
            activeKnown = false;
            activeError = e;
            loading = false;
          });
        }
      }, force: force);

  Future<void> refreshHistory({bool force = false}) =>
      runRequest('history', () async {
        try {
          final value = await context.read<ApiClient>().get(
            '/todos/focus',
            queryParameters: {
              'from': '${today.substring(0, 7)}-01',
              'to': today,
              'page': 0,
              'size': 15,
            },
          );
          final items = ((value as Map)['content'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (!mounted) return;
          setState(() {
            history = items;
            historyLoaded = true;
            historyError = null;
          });
        } catch (e) {
          if (mounted) setState(() => historyError = e);
        }
      }, force: force);

  Future<void> refreshTodos() => runRequest('todos', () async {
    try {
      final value = await context.read<ApiClient>().get(
        '/todos/page',
        queryParameters: {'page': 0, 'size': 50},
      );
      final items = ((value as Map)['content'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => e['status'] == 'OPEN' || e['status'] == 'IN_PROGRESS')
          .toList();
      if (!mounted) return;
      setState(() {
        todos = items;
        todosError = null;
        if (todoId.isNotEmpty &&
            !todos.any((todo) => todo['id'].toString() == todoId))
          todoId = '';
      });
    } catch (e) {
      if (mounted)
        setState(() {
          todosError = e;
          todoId = '';
        });
    }
  });

  String newId() {
    final r = Random.secure();
    return List.generate(
      20,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> submit(String path, Map<String, dynamic> body) async {
    if (busy) return;
    final fingerprint = '$path:${jsonEncode(body)}';
    if (uncertainWrite && fingerprint != pendingFingerprint) return;
    loadGeneration++;
    if (fingerprint != pendingFingerprint) {
      pendingFingerprint = fingerprint;
      pendingId = newId();
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await context.read<ApiClient>().post(
        path,
        data: {...body, 'operationId': pendingId},
      );
      pendingFingerprint = '';
      pendingId = '';
      loadGeneration++;
      if (!mounted) return;
      final value = response is Map
          ? Map<String, dynamic>.from(response)
          : null;
      final state = value?['state'];
      final running =
          (state == 'RUNNING' || state == 'PAUSED') &&
          value?['id'] != null &&
          value?['elapsedSeconds'] is num &&
          value?['plannedSeconds'] is num &&
          value?['version'] != null;
      final ended = state == 'COMPLETED' || state == 'CANCELLED';
      setState(() {
        uncertainWrite = false;
        uncertainPath = null;
        uncertainBody = null;
        activeKnown = running || ended;
        loading = !activeKnown;
        if (running) active = value;
        if (ended) active = null;
        if (running || ended) {
          fetchedAt = DateTime.now();
          activeError = null;
        }
      });
      unawaited(refreshHistory(force: true));
      unawaited(refreshActive(force: true));
    } catch (e) {
      if (mounted)
        setState(() {
          error = e;
          final status = e is ApiException ? e.statusCode : null;
        uncertainWrite = status == null || status == 408 || status >= 500;
          if (uncertainWrite) {
            uncertainPath = path;
            uncertainBody = Map<String, dynamic>.from(body);
          } else {
            pendingFingerprint = '';
            pendingId = '';
            uncertainPath = null;
            uncertainBody = null;
          }
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String clock(int seconds) {
    final s = seconds.clamp(0, 28800);
    return '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void notifyIfComplete() {
    final session = active;
    if (!notifyWhenDone || session == null || session['state'] != 'RUNNING')
      return;
    final elapsed =
        (session['elapsedSeconds'] as num).toInt() +
        DateTime.now().difference(fetchedAt).inSeconds.clamp(0, 28800);
    final id = session['id'].toString();
    if (elapsed < (session['plannedSeconds'] as num).toInt() ||
        !notifiedSessions.add(id))
      return;
    unawaited(
      NativeNotificationService.show({
        'id': 'focus-$id',
        'type': 'REMINDER',
        'title': session['mode'] == 'FOCUS'
            ? 'Đã hết giờ tập trung'
            : 'Đã hết giờ nghỉ',
        'message': 'Mở FitTrack để xác nhận kết thúc phiên. Công việc chưa tự hoàn thành.',
      }).catchError((_) => false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = active;
    final elapsed = a == null
        ? 0
        : ((a['elapsedSeconds'] as num).toInt() +
                  (a['state'] == 'RUNNING'
                      ? DateTime.now()
                            .difference(fetchedAt)
                            .inSeconds
                            .clamp(0, 28800)
                      : 0))
              .clamp(0, 28800);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Phiên tập trung được lưu trên máy chủ. Kết thúc phiên không tự hoàn thành công việc.',
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(
              displayError(error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (uncertainWrite)
            ListTile(
              title: const Text('Chưa xác nhận được thao tác tập trung'),
              subtitle: const Text(
                'Thử lại cùng yêu cầu để tránh tạo phiên trùng.',
              ),
              trailing: TextButton(
                onPressed: busy
                    ? null
                    : () => submit(uncertainPath!, uncertainBody!),
                child: const Text('Thử lại thao tác'),
              ),
            ),
          if (activeError != null)
            ListTile(
              title: const Text('Không kiểm tra được phiên tập trung'),
              subtitle: Text(displayError(activeError!)),
              trailing: TextButton(
                onPressed: busy ? null : () => refreshActive(),
                child: const Text('Thử lại'),
              ),
            ),
          if (todosError != null)
            ListTile(
              title: const Text('Không tải được danh sách công việc'),
              subtitle: const Text('Bạn vẫn có thể nhập tên phiên riêng.'),
              trailing: TextButton(
                onPressed: busy ? null : () => refreshTodos(),
                child: const Text('Thử lại'),
              ),
            ),
          if (a != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['title']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      a['state'] == 'PAUSED' ? 'Đang tạm dừng' : 'Đang chạy',
                    ),
                    Text(
                      clock((a['plannedSeconds'] as num).toInt() - elapsed),
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text('Đã chạy ${clock(elapsed)}'),
                    if (a['reviewRequired'] == true)
                      const Text(
                        'Phiên quá 8 giờ: hãy kết thúc hoặc hủy để xem lại.',
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed:
                              busy ||
                                  uncertainWrite ||
                                  !activeKnown ||
                                  a['reviewRequired'] == true
                              ? null
                              : () =>
                                    submit('/todos/focus/${a['id']}/actions', {
                                      'version': a['version'],
                                      'action': a['state'] == 'RUNNING'
                                          ? 'PAUSE'
                                          : 'RESUME',
                                    }),
                          child: Text(
                            a['state'] == 'RUNNING' ? 'Tạm dừng' : 'Tiếp tục',
                          ),
                        ),
                        FilledButton(
                          onPressed: busy || uncertainWrite || !activeKnown
                              ? null
                              : () => confirm(a, 'FINISH'),
                          child: const Text('Kết thúc'),
                        ),
                        TextButton(
                          onPressed: busy || uncertainWrite || !activeKnown
                              ? null
                              : () => confirm(a, 'CANCEL'),
                          child: const Text('Hủy phiên'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (!loading && activeKnown)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(todoId),
                      initialValue: todoId,
                      decoration: const InputDecoration(
                        labelText: 'Công việc liên kết',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tên riêng'),
                        ),
                        ...todos.map(
                          (t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text(
                              t['title'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => todoId = v ?? ''),
                    ),
                    if (todoId.isEmpty)
                      TextField(
                        controller: title,
                        maxLength: 180,
                        decoration: const InputDecoration(
                          labelText: 'Tên phiên',
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: 'Chế độ'),
                      items: const [
                        DropdownMenuItem(
                          value: 'FOCUS',
                          child: Text('Tập trung'),
                        ),
                        DropdownMenuItem(value: 'BREAK', child: Text('Nghỉ')),
                      ],
                      onChanged: busy ? null : (v) => setState(() => mode = v!),
                    ),
                    TextField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thời lượng (1–180 phút)',
                      ),
                    ),
                    FilledButton(
                      onPressed: busy || uncertainWrite
                          ? null
                          : () {
                              final n = int.tryParse(minutes.text);
                              if (n == null ||
                                  n < 1 ||
                                  n > 180 ||
                                  (todoId.isEmpty &&
                                      title.text.trim().isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nhập tên và thời lượng hợp lệ.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              submit('/todos/focus', {
                                'mode': mode,
                                'minutes': n,
                                if (todoId.isEmpty)
                                  'title': title.text.trim()
                                else
                                  'todoId': todoId,
                              });
                            },
                      child: const Text('Bắt đầu'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Lịch sử tháng này',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (historyError != null)
            ListTile(
              title: const Text('Không tải được lịch sử phiên'),
              subtitle: Text(displayError(historyError!)),
              trailing: TextButton(
                onPressed: busy ? null : () => refreshHistory(),
                child: const Text('Thử lại'),
              ),
            )
          else if (!historyLoaded)
            const Text('Đang tải lịch sử...')
          else if (history.isEmpty)
            const Text('Chưa có phiên trong khoảng này.'),
          ...history.map(
            (s) => ListTile(
              title: Text('${s['title']}'),
              subtitle: Text(
                '${s['createdAt']} · ${s['state']} · ${clock((s['elapsedSeconds'] as num).toInt())}',
              ),
            ),
          ),
          const Text(
            'Đồng hồ tối đa 8 giờ; thời gian không chứng minh mức độ tập trung.',
          ),
          SwitchListTile(
            title: const Text('Nhắc khi hết giờ'),
            subtitle: const Text(
              'Chỉ theo dõi khi màn hình này đang mở; không đảm bảo khi app bị dừng.',
            ),
            value: notifyWhenDone,
            onChanged: (enabled) async {
              if (!enabled) {
                setState(() => notifyWhenDone = false);
                return;
              }
              try {
                final granted =
                    await NativeNotificationService.requestPermission();
                if (!mounted) return;
                setState(() => notifyWhenDone = granted);
                if (!granted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chưa được cấp quyền thông báo điện thoại.',
                      ),
                    ),
                  );
              } catch (_) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Không bật được thông báo trên thiết bị này.',
                      ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> confirm(Map<String, dynamic> a, String action) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(action == 'FINISH' ? 'Kết thúc phiên?' : 'Hủy phiên?'),
        content: const Text('Trạng thái công việc không thay đổi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (yes == true && mounted)
      await submit('/todos/focus/${a['id']}/actions', {
        'version': a['version'],
        'action': action,
      });
  }
}
