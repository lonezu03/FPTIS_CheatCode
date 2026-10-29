import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
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
  bool loading = true, busy = false;
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
  Future<void> load({bool silent = false}) async {
    if (silent && (loading || busy)) return;
    final generation = ++loadGeneration;
    if (!silent && mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final api = context.read<ApiClient>();
      final values = await Future.wait([
        api.get('/todos/focus/active'),
        api.get(
          '/todos/focus',
          queryParameters: {
            'from': '${today.substring(0, 7)}-01',
            'to': today,
            'page': 0,
            'size': 15,
          },
        ),
        api.get('/todos/page', queryParameters: {'page': 0, 'size': 50}),
      ]);
      if (!mounted || generation != loadGeneration) return;
      setState(() {
        active = values[0] is Map
            ? Map<String, dynamic>.from(values[0] as Map)
            : null;
        fetchedAt = DateTime.now();
        history = ((values[1] as Map)['content'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        todos = ((values[2] as Map)['content'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((e) => e['status'] == 'OPEN' || e['status'] == 'IN_PROGRESS')
            .toList();
        if (todoId.isNotEmpty &&
            !todos.any((todo) => todo['id'].toString() == todoId)) {
          todoId = '';
        }
        error = null;
      });
    } catch (e) {
      if (mounted && !silent && generation == loadGeneration)
        setState(() => error = e);
    } finally {
      if (mounted && !silent && generation == loadGeneration)
        setState(() => loading = false);
    }
  }

  String newId() {
    final r = Random.secure();
    return List.generate(
      20,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> submit(String path, Map<String, dynamic> body) async {
    if (busy) return;
    loadGeneration++;
    final fingerprint = '$path:${jsonEncode(body)}';
    if (fingerprint != pendingFingerprint) {
      pendingFingerprint = fingerprint;
      pendingId = newId();
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<ApiClient>().post(
        path,
        data: {...body, 'operationId': pendingId},
      );
      pendingFingerprint = '';
      pendingId = '';
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e);
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
                          onPressed: busy || a['reviewRequired'] == true
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
                          onPressed: busy ? null : () => confirm(a, 'FINISH'),
                          child: const Text('Kết thúc'),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => confirm(a, 'CANCEL'),
                          child: const Text('Hủy phiên'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (!loading && error == null)
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
                      onPressed: busy
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
          if (history.isEmpty) const Text('Chưa có phiên trong khoảng này.'),
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
