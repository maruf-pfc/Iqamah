import 'dart:convert';

/// Narrow file-only protocol. Platform callbacks are injected for deterministic tests.
class BackupBridge {
  static const maxBytes = 20 * 1024 * 1024;

  static Future<Map<String, Object?>> handle({
    required String message,
    required String? assetUrl,
    required String? currentUrl,
    required Future<String> Function(String content, String filename) share,
    required Future<String?> Function() pick,
  }) async {
    String? requestId;
    try {
      // JSON can expand a single content byte into six bytes (e.g. \u0000).
      // Bound the envelope independently; the decoded content still has a 20 MiB cap.
      if (message.length > maxBytes * 6 + 4096) throw const FormatException('Request too large');
      final data = jsonDecode(message) as Map<String, dynamic>;
      requestId = data['requestId'] as String?;
      if (assetUrl == null || Uri.tryParse(assetUrl)?.scheme != 'file' ||
          currentUrl?.split('#').first != assetUrl || requestId == null ||
          !RegExp(r'^[a-zA-Z0-9-]{1,64}$').hasMatch(requestId)) {
        throw const FormatException('Untrusted backup request');
      }
      if (data['action'] == 'pickBackup') {
        final content = await pick();
        if (content != null && utf8.encode(content).length > maxBytes) throw const FormatException('File too large');
        return {'requestId': requestId, 'status': content == null ? 'cancelled' : 'success', if (content != null) 'content': content};
      }
      if (data['action'] == 'shareBackup') {
        final content = data['content'] as String;
        final filename = data['filename'] as String;
        if (utf8.encode(content).length > maxBytes ||
            !RegExp(r'^iqamah_backup_[a-zA-Z0-9_.-]+\.json$').hasMatch(filename)) {
          throw const FormatException('Invalid backup file');
        }
        final status = await share(content, filename);
        return {'requestId': requestId, 'status': ['success', 'cancelled'].contains(status) ? status : 'error'};
      }
    } catch (_) {
      // Do not log sensitive file contents. The caller only receives an error status.
    }
    return {'requestId': requestId, 'status': 'error'};
  }
}
