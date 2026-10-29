import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import '../home/mobile_menu_controller.dart';
import 'monthly_report_pdf.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final month = TextEditingController(
    text: DateFormat('yyyy-MM')
        .format(DateTime.now().toUtc().add(const Duration(hours: 7))),
  );
  final selected = <String>{};
  Map<String, dynamic>? report;
  bool loading = false;
  bool exporting = false;
  Object? error;
  static const labels = {
    'TRAINING': 'Luyện tập',
    'NUTRITION': 'Dinh dưỡng',
    'HABITS': 'Thói quen',
    'FINANCE': 'Thu chi cá nhân',
    'FOCUS': 'Tập trung',
  };
  @override
  void dispose() {
    month.dispose();
    super.dispose();
  }

  Set<String> allowed(AuthUser? u, MobileMenuController menu) => u == null
      ? {}
      : {
          if (menu.allows('fitness', u)) 'TRAINING',
          if (menu.allows('nutrition', u)) 'NUTRITION',
          if (menu.allows('planner', u) && (u.isAdmin || u.todoEnabled)) ...[
            'HABITS',
            'FOCUS',
          ],
          if (menu.allows('finance', u)) 'FINANCE',
        };
  Future<void> load(Set<String> permitted) async {
    final parts = selected.intersection(permitted).toList()..sort();
    if (parts.isEmpty || !RegExp(r'^\d{4}-\d{2}$').hasMatch(month.text)) {
      setState(() => error = 'Hãy chọn nội dung và tháng hợp lệ (yyyy-MM).');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      report = null;
    });
    try {
      final data = await context.read<ApiClient>().get(
        '/personal-reports/monthly',
        queryParameters: {
          'month': '${month.text}-01',
          'sections': parts.join(','),
        },
      );
      if (mounted) {
        final current = allowed(
          context.read<AuthSession>().user,
          context.read<MobileMenuController>(),
        );
        final received = Map<String, dynamic>.from(data as Map);
        setState(() {
          if (monthlyReportSectionsAllowed(
            received,
            current,
            requested: parts.toSet(),
          )) {
            report = received;
          } else {
            error = 'Quyền truy cập hoặc nội dung báo cáo đã thay đổi. Vui lòng tải lại.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String value(dynamic n, [String unit = '']) =>
      n == null ? 'Chưa đủ dữ liệu' : '$n$unit';

  Future<void> exportPdf(Map<String, dynamic> data) async {
    setState(() {
      exporting = true;
      error = null;
    });
    bool stillAllowed() {
      if (!mounted || !identical(report, data)) return false;
      final permitted = allowed(
        context.read<AuthSession>().user,
        context.read<MobileMenuController>(),
      );
      return monthlyReportSectionsAllowed(data, permitted);
    }

    try {
      final bytes = await buildMonthlyReportPdf(data);
      if (!stillAllowed()) throw StateError('Quyền truy cập đã thay đổi.');
      await Printing.layoutPdf(
        name: 'fittrack-bao-cao-${data['month']}.pdf',
        onLayout: (_) async {
          if (!stillAllowed()) throw StateError('Quyền truy cập đã thay đổi.');
          return bytes;
        },
      );
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Không thể in hoặc lưu PDF. Hãy kiểm tra quyền truy cập và thử lại.',
        );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permitted = allowed(
      context.watch<AuthSession>().user,
      context.watch<MobileMenuController>(),
    );
    final data = report;
    final safe = data != null && monthlyReportSectionsAllowed(data, permitted);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Chọn nội dung để xem dữ liệu cá nhân. Nhật ký riêng không được đưa vào báo cáo.',
        ),
        TextField(
          controller: month,
          enabled: !loading && !exporting,
          decoration: const InputDecoration(labelText: 'Tháng (yyyy-MM)'),
          onChanged: (_) => setState(() => report = null),
        ),
        ...permitted.map(
          (s) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(labels[s]!),
            value: selected.contains(s),
            onChanged: loading || exporting
                ? null
                : (v) => setState(() {
                    if (v == true) {
                      selected.add(s);
                    } else {
                      selected.remove(s);
                    }
                    report = null;
                  }),
          ),
        ),
        FilledButton(
          onPressed: loading || exporting ? null : () => load(permitted),
          child: const Text('Xem báo cáo'),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Text(error is String ? error.toString() : displayError(error!)),
        if (safe) ...[
          Text(
            'Báo cáo tháng ${data['month']} · đến ${data['through']}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (data['training'] is Map)
            section('Luyện tập', [
              '${data['training']['sessions']} buổi · ${data['training']['trainingDays']} ngày · ${data['training']['workingSets']} hiệp chính',
              'Khối lượng: ${value(data['training']['volumeKgReps'], ' kg × lần')}',
            ]),
          if (data['nutrition'] is Map)
            section('Dinh dưỡng', [
              '${data['nutrition']['qualifyingDays']}/${data['nutrition']['observedDays']} ngày đủ điều kiện · bao phủ ${value(data['nutrition']['coveragePercent'], '%')}',
              'Năng lượng: ${value(data['nutrition']['averageCalories'], ' kcal/ngày')}',
              'Chất đạm: ${value(data['nutrition']['averageProtein'], ' g/ngày')}',
              'Tinh bột: ${value(data['nutrition']['averageCarbs'], ' g/ngày')}',
              'Chất béo: ${value(data['nutrition']['averageFat'], ' g/ngày')}',
              'Dữ liệu thiếu không được xem là 0.',
            ]),
          if (data['habits'] is Map)
            section('Thói quen', [
              '${data['habits']['done']}/${data['habits']['eligibleDays']} lượt · ${value(data['habits']['completionRate'], '%')}',
              if (data['habits']['historyVerified'] != true)
                'Lịch cũ chưa xác minh không đưa vào tỷ lệ.',
            ]),
          if (data['finance'] is List)
            section('Thu chi theo tiền tệ', [
              (data['finance'] as List).isEmpty
                  ? 'Chưa có giao dịch hợp lệ.'
                  : '',
              ...(data['finance'] as List).map(
                (f) =>
                    '${f['currencyCode']}: thu ${f['income']} · chi ${f['expense']} · chênh lệch ${f['net']}',
              ),
            ]),
          if (data['focus'] is List)
            section('Tập trung', [
              (data['focus'] as List).isEmpty ? 'Chưa có phiên hoàn tất.' : '',
              ...(data['focus'] as List).map(
                (f) =>
                    '${f['category']}: ${f['completedSessions']} phiên · ${((f['focusSeconds'] as num) / 60).toStringAsFixed(1)} phút',
              ),
            ]),
          Text('${data['disclaimer'] ?? ''}'),
          OutlinedButton.icon(
            onPressed: exporting ? null : () => exportPdf(data),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(exporting ? 'Đang chuẩn bị PDF...' : 'In hoặc lưu PDF'),
          ),
        ],
      ],
    );
  }

  Widget section(String title, List<String> lines) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...lines.where((s) => s.isNotEmpty).map(Text.new),
        ],
      ),
    ),
  );
}
