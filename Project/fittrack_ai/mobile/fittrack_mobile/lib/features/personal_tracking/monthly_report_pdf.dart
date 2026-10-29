import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

bool monthlyReportSectionsAllowed(
  Map<String, dynamic> data,
  Set<String> allowed, {
  Set<String>? requested,
}) {
  final raw = data['sections'];
  if (raw is! List || raw.any((value) => value is! String)) return false;
  final sections = raw.cast<String>().toSet();
  return sections.isNotEmpty &&
      sections.length == raw.length &&
      allowed.containsAll(sections) &&
      (requested == null ||
          (sections.length == requested.length &&
              sections.containsAll(requested)));
}

/// Renders only explicitly selected sections. No network access is used.
Future<Uint8List> buildMonthlyReportPdf(Map<String, dynamic> data) async {
  final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final font = pw.Font.ttf(fontData);
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  final sections = (data['sections'] as List).map((e) => e.toString()).toSet();
  String value(dynamic n, [String unit = '']) =>
      n == null ? 'Chưa đủ dữ liệu' : '$n$unit';
  final content = <pw.Widget>[];
  void add(String title, List<String> lines) {
    content.add(pw.SizedBox(height: 14));
    content.add(pw.Text(title, style: const pw.TextStyle(fontSize: 14)));
    for (final line in lines.where((s) => s.isNotEmpty)) {
      content.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 5),
          child: pw.Text(line),
        ),
      );
    }
  }

  final t = data['training'];
  if (sections.contains('TRAINING') && t is Map) {
    add('Luyện tập', [
      '${t['sessions']} buổi · ${t['trainingDays']} ngày · ${t['workingSets']} hiệp chính',
      'Khối lượng: ${value(t['volumeKgReps'], ' kg × lần')}',
    ]);
  }
  final n = data['nutrition'];
  if (sections.contains('NUTRITION') && n is Map) {
    add('Dinh dưỡng', [
      '${n['qualifyingDays']}/${n['observedDays']} ngày đủ điều kiện · bao phủ ${value(n['coveragePercent'], '%')}',
      'Năng lượng: ${value(n['averageCalories'], ' kcal/ngày')}',
      'Chất đạm: ${value(n['averageProtein'], ' g/ngày')}',
      'Tinh bột: ${value(n['averageCarbs'], ' g/ngày')}',
      'Chất béo: ${value(n['averageFat'], ' g/ngày')}',
      'Dữ liệu thiếu không được xem là 0.',
    ]);
  }
  final h = data['habits'];
  if (sections.contains('HABITS') && h is Map) {
    add('Thói quen', [
      '${h['done']}/${h['eligibleDays']} lượt · ${value(h['completionRate'], '%')}',
      if (h['historyVerified'] != true)
        'Lịch cũ chưa xác minh không đưa vào tỷ lệ.',
    ]);
  }
  final finance = data['finance'];
  if (sections.contains('FINANCE') && finance is List) {
    add('Thu chi theo tiền tệ', [
      if (finance.isEmpty) 'Chưa có giao dịch hợp lệ.',
      ...finance.whereType<Map>().map(
        (f) =>
            '${f['currencyCode']}: thu ${f['income']} · chi ${f['expense']} · chênh lệch ${f['net']}',
      ),
    ]);
  }
  final focus = data['focus'];
  if (sections.contains('FOCUS') && focus is List) {
    add('Tập trung', [
      if (focus.isEmpty) 'Chưa có phiên hoàn tất.',
      ...focus.whereType<Map>().map(
        (f) =>
            '${f['category']}: ${f['completedSessions']} phiên · ${((f['focusSeconds'] as num) / 60).toStringAsFixed(1)} phút',
      ),
    ]);
  }
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(
          'Báo cáo tháng ${data['month']} · đến ${data['through']}',
          style: const pw.TextStyle(fontSize: 18),
        ),
        ...content,
        pw.SizedBox(height: 16),
        pw.Text('${data['disclaimer'] ?? ''}'),
      ],
    ),
  );
  return document.save();
}
