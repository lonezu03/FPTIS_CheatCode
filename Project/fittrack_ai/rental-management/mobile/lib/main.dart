import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment('API_BASE_URL');
const storage = FlutterSecureStorage();
void main() => runApp(const RentalApp());

class Api {
  String? cookie;
  final activeWrites = <String>{};
  final activeReads = ValueNotifier<int>(0);
  final writeCount = ValueNotifier<int>(0);
  Uri url(String path) {
    if (apiBase.isEmpty) throw Exception('Chưa cấu hình API_BASE_URL.');
    final base = Uri.parse(apiBase);
    if (!base.hasAuthority ||
        (base.scheme != 'https' && !(kDebugMode && base.scheme == 'http'))) {
      throw Exception('API_BASE_URL phải dùng HTTPS (HTTP chỉ cho bản debug).');
    }
    return Uri.parse('${apiBase.replaceAll(RegExp(r'/$'), '')}/$path');
  }

  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final write = method != 'GET';
    final key = '$method:$path:${jsonEncode(body)}';
    if (write && !activeWrites.add(key)) {
      throw Exception('Yeu cau dang duoc xu ly.');
    }
    if (write) {
      writeCount.value++;
    } else {
      activeReads.value++;
    }
    try {
      final request = http.Request(method, url(path));
      request.headers['Content-Type'] = 'application/json';
      if (cookie != null) request.headers['Cookie'] = cookie!;
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(await request.send())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 401 && path != 'auth/login') {
        cookie = null;
        await storage.delete(key: 'session');
      }
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          decoded is Map
              ? (decoded['error'] ?? decoded['message'] ?? 'Lỗi máy chủ')
              : 'Không thể kết nối (${response.statusCode})',
        );
      }
      final setCookie = response.headers['set-cookie'];
      if (path == 'auth/login' && setCookie != null) {
        final match = RegExp(r'(rental_session=[a-f0-9]{64})')
            .firstMatch(setCookie);
        if (match == null) {
          throw Exception('Máy chủ không trả phiên đăng nhập hợp lệ.');
        }
        cookie = match.group(1);
        await storage.write(key: 'session', value: cookie);
      }
      return decoded;
    } finally {
      if (write) {
        activeWrites.remove(key);
        writeCount.value--;
      } else {
        activeReads.value--;
      }
    }
  }

  Future<void> logout() async {
    try {
      await tokenSubscription?.cancel();
      tokenSubscription = null;
      await call('auth/logout', method: 'POST', body: {});
    } finally {
      cookie = null;
      await storage.delete(key: 'session');
    }
  }
}

final api = Api();
StreamSubscription<String>? tokenSubscription;
Future<void> setupPush() async {
  const key = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const sender = String.fromEnvironment('FIREBASE_SENDER_ID');
  const iosBundle = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  if (key.isEmpty || appId.isEmpty || project.isEmpty || sender.isEmpty) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: key,
          appId: appId,
          messagingSenderId: sender,
          projectId: project,
          iosBundleId: iosBundle,
        ),
      );
    }
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) return;
    Future<void> register(String token) async {
      await api.call(
        'push/devices',
        method: 'POST',
        body: {'token': token, 'platform': Platform.isIOS ? 'IOS' : 'ANDROID'},
      );
    }

    // FCM HTTP v1 currently expects a registration token.
    // ignore: deprecated_member_use
    final token = await messaging.getToken();
    if (token != null) await register(token);
    await tokenSubscription?.cancel();
    // ignore: deprecated_member_use
    tokenSubscription = messaging.onTokenRefresh.listen((token) {
      register(token).catchError((Object _) {});
    });
  } catch (_) {
    /* In-app notifications remain available without push setup. */
  }
}

String money(dynamic value) {
  final n = (num.tryParse('$value') ?? 0).round().toString();
  return '${n.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';
}

String label(dynamic s) =>
    const {
      'PENDING': 'Chờ xác nhận',
      'APPROVED': 'Đã duyệt',
      'REJECTED': 'Đã từ chối',
      'PAID': 'Đã thanh toán',
      'PARTIAL': 'Thanh toán một phần',
      'UNPAID': 'Chưa thanh toán',
      'ACTIVE': 'Đang hiệu lực',
      'ENDED': 'Đã kết thúc',
      'RENT': 'Tiền phòng',
      'ELECTRIC': 'Điện',
      'WATER': 'Nước',
      'SERVICE': 'Dịch vụ',
    }[s] ??
    (s == null ? 'Chưa phân bổ' : '$s');
String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

class RentalApp extends StatelessWidget {
  const RentalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nhà Mây',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff315e43),
      useMaterial3: true,
    ),
    builder: (context, child) => ValueListenableBuilder<int>(
      valueListenable: api.writeCount,
      builder: (context, writes, _) => Stack(
        children: [
          AbsorbPointer(absorbing: writes > 0, child: child),
          if (writes > 0)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ValueListenableBuilder<int>(
            valueListenable: api.activeReads,
            builder: (context, reads, _) => reads > 0
                ? const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
    home: const Gate(),
  );
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool loading = true, logged = false;
  String? error;
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      api.cookie = await storage.read(key: 'session');
      if (api.cookie != null) {
        final u = await api.call('auth/me');
        if (u['role'] != 'TENANT') {
          throw Exception('Ứng dụng này dành cho người thuê.');
        }
        logged = true;
        unawaited(setupPush());
      }
    } catch (e) {
      error = cleanError(e);
      api.cookie = null;
      await storage.delete(key: 'session');
    }
    if (mounted) setState(() => loading = false);
  }

  void done() {
    setState(() {
      logged = true;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return logged
        ? Home(
            onLogout: () {
              setState(() => logged = false);
            },
          )
        : Login(onLogin: done, initialError: error);
  }
}

class Login extends StatefulWidget {
  final VoidCallback onLogin;
  final String? initialError;
  const Login({super.key, required this.onLogin, this.initialError});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final username = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    error = widget.initialError;
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await api.call(
        'auth/login',
        method: 'POST',
        body: {'username': username.text.trim(), 'password': password.text},
      );
      final user = await api.call('auth/me');
      if (user['role'] != 'TENANT') {
        await api.logout();
        throw Exception('Ứng dụng này dành cho người thuê.');
      }
      widget.onLogin();
      unawaited(setupPush());
    } catch (e) {
      if (mounted) setState(() => error = cleanError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nhà Mây', style: Theme.of(c).textTheme.headlineMedium),
              const Text('Không gian dành cho người thuê'),
              const SizedBox(height: 24),
              TextField(
                controller: username,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : submit,
                child: Text(busy ? 'Đang đăng nhập…' : 'Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Home extends StatefulWidget {
  final VoidCallback onLogout;
  const Home({super.key, required this.onLogout});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<RemoteMessage>? pushSubscription;
  int index = 0;
  bool busy = false;
  String? error;
  Map<String, dynamic> data = {};
  static const paths = [
    'rooms',
    'contracts',
    'invoices',
    'payments',
    'payment-requests',
    'payment-settings',
    'notifications',
  ];
  @override
  void initState() {
    super.initState();
    load();
    pushSubscription = FirebaseMessaging.onMessage.listen((_) {
      load();
    });
  }

  @override
  void dispose() {
    pushSubscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = await Future.wait(paths.map((p) => api.call(p)));
      if (mounted) setState(() => data = Map.fromIterables(paths, values));
    } catch (e) {
      if (mounted) setState(() => error = cleanError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<dynamic> rows(String key) => data[key] is List ? data[key] : [];
  String invoiceMonth(dynamic id) {
    for (final invoice in rows('invoices')) {
      if (invoice['id'] == id) return '${invoice['month']}';
    }
    return '-';
  }

  Map<String, dynamic>? room(dynamic id) {
    for (final r in rows('rooms')) {
      if (r['id'] == id) return Map<String, dynamic>.from(r);
    }
    return null;
  }

  Future<void> sendRequest(Map invoice) async {
    final amount = TextEditingController(
      text: '${(invoice['total'] as num) - (invoice['paid'] as num)}',
    );
    final note = TextEditingController();
    String component = '';
    DateTime paid = DateTime.now();
    bool sending = false;
    String? formError;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Báo đã chuyển khoản'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền (đ)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: '',
                  decoration: const InputDecoration(
                    labelText: 'Khoản thanh toán',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Thanh toán chung'),
                    ),
                    if ((invoice['discount'] ?? 0) == 0)
                      ...['RENT', 'ELECTRIC', 'WATER', 'SERVICE'].map(
                        (v) =>
                            DropdownMenuItem(value: v, child: Text(label(v))),
                      ),
                  ],
                  onChanged: (v) => component = v ?? '',
                ),
                ListTile(
                  title: Text(
                    'Ngày chuyển: ${paid.toIso8601String().substring(0, 10)}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: paid,
                    );
                    if (date != null) setDialog(() => paid = date);
                  },
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                if (formError != null)
                  Text(formError!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialog),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final parsed = int.tryParse(amount.text);
                      if (parsed == null || parsed <= 0) {
                        setDialog(() => formError = 'Nhập số tiền hợp lệ.');
                        return;
                      }
                      setDialog(() => sending = true);
                      try {
                        await api.call(
                          'payment-requests',
                          method: 'POST',
                          body: {
                            'invoiceId': invoice['id'],
                            'amount': parsed,
                            'paidAt': paid.toIso8601String().substring(0, 10),
                            'note': note.text,
                            'component': component.isEmpty ? null : component,
                          },
                        );
                        if (dialog.mounted) Navigator.pop(dialog);
                        await load();
                      } catch (e) {
                        setDialog(() {
                          sending = false;
                          formError = cleanError(e);
                        });
                      }
                    },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    note.dispose();
  }

  Widget invoices() => ListView(
    children: [
      const ListTile(
        title: Text(
          'Hóa đơn',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      if (rows('invoices').isEmpty)
        const ListTile(title: Text('Chưa có hóa đơn.')),
      for (final i in rows('invoices'))
        Card(
          child: ExpansionTile(
            title: Text(
              'Tháng ${i['month']} · ${room(i['roomId'])?['name'] ?? 'Phòng'}',
            ),
            subtitle: Text(
              '${label(i['status'])} · Còn ${money(i['total'] - i['paid'])}',
            ),
            children: [
              for (final line in {
                'Tiền phòng': i['rent'],
                'Điện': i['electricAmount'],
                'Nước': i['waterAmount'],
                'Dịch vụ': i['serviceAmount'],
                'Giảm trừ': i['discount'],
                'Tổng cộng': i['total'],
                'Đã thanh toán': i['paid'],
              }.entries)
                ListTile(
                  dense: true,
                  title: Text(line.key),
                  trailing: Text(money(line.value)),
                ),
              if (i['total'] > i['paid']) ...[
                _paymentInfo(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    onPressed: () => sendRequest(i),
                    child: const Text('Báo đã chuyển khoản'),
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
  Widget _paymentInfo() {
    final p = data['payment-settings'];
    if (p is! Map || p['accountNumber'] == null || p['accountNumber'] == '') {
      return const ListTile(
        title: Text('Chủ trọ chưa cấu hình thông tin nhận tiền.'),
      );
    }
    final qr = p['qrUrl']?.toString() ?? '';
    return Column(
      children: [
        ListTile(
          title: Text('${p['bankName']} · ${p['accountNumber']}'),
          subtitle: Text('${p['accountName']}'),
        ),
        if (qr.startsWith('https://'))
          Image.network(
            qr,
            height: 180,
            errorBuilder: (_, _, _) => const Text('Không tải được mã QR.'),
          ),
      ],
    );
  }

  Widget contracts() => ListView(
    children: [
      const ListTile(
        title: Text(
          'Phòng và hợp đồng',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      if (rows('contracts').isEmpty)
        const ListTile(title: Text('Chưa có hợp đồng.')),
      for (final c in rows('contracts'))
        Card(
          child: ListTile(
            title: Text(
              'Phòng ${room(c['roomId'])?['name'] ?? '#${c['roomId']}'}',
            ),
            subtitle: Text(
              'Giá thuê ${money(c['rent'])}/tháng · Cọc ${money(c['deposit'])}\n${c['startDate']} – ${c['endDate'] == '' ? 'Chưa xác định' : c['endDate']} · ${label(c['status'])}',
            ),
            isThreeLine: true,
          ),
        ),
    ],
  );
  Widget history() => ListView(
    children: [
      const ListTile(
        title: Text(
          'Thanh toán và yêu cầu',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      const ListTile(title: Text('Yêu cầu xác nhận')),
      if (rows('payment-requests').isEmpty)
        const ListTile(title: Text('Chưa có yêu cầu.')),
      for (final r in rows('payment-requests'))
        Card(
          child: ListTile(
            title: Text('${money(r['amount'])} · ${label(r['status'])}'),
            subtitle: Text(
              '${r['paidAt']} · ${label(r['component'])}\n${r['reason'] ?? r['note'] ?? ''}',
            ),
          ),
        ),
      const ListTile(title: Text('Lịch sử đã xác nhận')),
      if (rows('payments').isEmpty)
        const ListTile(title: Text('Chưa có thanh toán.')),
      for (final p in rows('payments'))
        Card(
          child: ListTile(
            title: Text(money(p['amount'])),
            subtitle: Text('${p['paidAt']} · ${label(p['component'])}'),
          ),
        ),
    ],
  );
  Widget notifications() => ListView(
    children: [
      const ListTile(
        title: Text(
          'Thông báo',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      if (rows('notifications').isEmpty)
        const ListTile(title: Text('Chưa có thông báo.')),
      for (final n in rows('notifications'))
        Card(
          child: ListTile(
            title: Text(n['title'] ?? ''),
            subtitle: Text('${n['message']}\n${n['createdAt']}'),
            trailing: n['readAt'] == null
                ? TextButton(
                    onPressed: () async {
                      try {
                        await api.call(
                          'notifications/${n['id']}/read',
                          method: 'POST',
                          body: {},
                        );
                        await load();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(cleanError(e))),
                          );
                        }
                      }
                    },
                    child: const Text('Đánh dấu đã đọc'),
                  )
                : null,
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Nhà Mây'),
      actions: [
        IconButton(
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        ),
        IconButton(
          onPressed: () async {
            try {
              await api.logout();
            } catch (_) {}
            widget.onLogout();
          },
          icon: const Icon(Icons.logout),
          tooltip: 'Đăng xuất',
        ),
      ],
    ),
    body: Column(
      children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          MaterialBanner(
            content: Text(error!),
            actions: [
              TextButton(onPressed: load, child: const Text('Thử lại')),
            ],
          ),
        Expanded(
          child: [invoices(), contracts(), history(), notifications()][index],
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Hóa đơn'),
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Phòng'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Thanh toán'),
        NavigationDestination(
          icon: Icon(Icons.notifications_none),
          label: 'Thông báo',
        ),
      ],
    ),
  );
}
