import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

String encodeCsv(List<String> headers, Iterable<List<Object?>> rows) {
  String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (value is String && RegExp(r'^\s*[=+@-]|^[\t\r\n]').hasMatch(text)) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  return '\uFEFF${[headers, ...rows].map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
}

Future<Uri?> exportCsv({
  required String filename,
  required List<String> headers,
  required Iterable<List<Object?>> rows,
}) => FilePicker.saveFile(
  dialogTitle: 'Lưu CSV',
  fileName: filename.endsWith('.csv') ? filename : '$filename.csv',
  bytes: Uint8List.fromList(utf8.encode(encodeCsv(headers, rows))),
);
