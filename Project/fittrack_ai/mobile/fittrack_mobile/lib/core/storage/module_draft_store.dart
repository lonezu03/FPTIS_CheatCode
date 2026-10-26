import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Non-journal drafts only. Owner scoped, bounded lifetime, no media payloads.
class ModuleDraftStore {
  static const _storage = FlutterSecureStorage();
  static String _prefix(String owner) =>
      'fittrack_draft_${Uri.encodeComponent(owner)}:';
  static String _key(String owner, String slot) => '${_prefix(owner)}$slot';
  static Future<Map<String, dynamic>?> read(String owner, String slot) async {
    if (owner.isEmpty) return null;
    final value = await _storage.read(key: _key(owner, slot));
    if (value == null) return null;
    try {
      final envelope = jsonDecode(value) as Map;
      final expires = DateTime.parse(envelope['expiresAt'] as String);
      if (expires.isAfter(DateTime.now())) {
        return Map<String, dynamic>.from(envelope['data'] as Map);
      }
    } catch (_) {
      /* Corrupt/expired local data is never sent to the API. */
    }
    await remove(owner, slot);
    return null;
  }

  static Future<void> write(
    String owner,
    String slot,
    Map<String, dynamic> data,
  ) async {
    if (owner.isEmpty) return;
    await _storage.write(
      key: _key(owner, slot),
      value: jsonEncode({
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'data': data,
      }),
    );
  }

  static Future<void> remove(String owner, String slot) =>
      _storage.delete(key: _key(owner, slot));
  static Future<void> clearOwner(String owner) async {
    if (owner.isEmpty) return;
    for (final key in (await _storage.readAll()).keys.toList()) {
      if (key.startsWith(_prefix(owner))) {
        await _storage.delete(key: key);
      }
    }
  }
}
