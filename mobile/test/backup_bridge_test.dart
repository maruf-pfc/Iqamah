import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/backup_bridge.dart';

void main() {
  const asset = 'file:///android_asset/flutter_assets/assets/web/index.html';
  Map<String, Object> request(String action) => {'requestId': 'test-123', 'action': action, 'content': '{}', 'filename': 'iqamah_backup_v2.0.0_2026-10-13.json'};
  Future<Map<String, Object?>> handle(Map<String, Object> data, {String? origin = asset, String? picked, String shared = 'success', bool fail = false}) => BackupBridge.handle(
    message: jsonEncode(data), assetUrl: asset, currentUrl: origin,
    pick: () async { if (fail) throw Exception('I/O'); return picked; },
    share: (content, filename) async {
      expect(filename, data['filename']);
      if (fail) throw Exception('I/O');
      return shared;
    },
  );
  test('shares only from the bundled origin and preserves requested filename', () async {
    expect((await handle(request('shareBackup')))['status'], 'success');
    expect((await handle(request('shareBackup'), origin: '$asset#/settings'))['status'], 'success');
    expect((await handle(request('shareBackup'), origin: 'https://example.com'))['status'], 'error');
  });
  test('rejects unsafe paths and unknown actions', () async {
    expect((await handle({...request('shareBackup'), 'filename': '../private.json'}))['status'], 'error');
    expect((await handle(request('deleteFiles')))['status'], 'error');
  });
  test('reports share cancellation, unavailable and errors honestly', () async {
    expect((await handle(request('shareBackup'), shared: 'cancelled'))['status'], 'cancelled');
    expect((await handle(request('shareBackup'), shared: 'unavailable'))['status'], 'error');
    expect((await handle(request('shareBackup'), fail: true))['status'], 'error');
  });
  test('picker cancellation and Unicode content', () async {
    expect((await handle(request('pickBackup')))['status'], 'cancelled');
    expect((await handle(request('pickBackup'), picked: 'ব্যাকআপ'))['content'], 'ব্যাকআপ');
    expect((await handle(request('pickBackup'), fail: true))['status'], 'error');
  });
  test('malformed JSON does not invoke platform operations', () async {
    final result = await BackupBridge.handle(message: '{broken', assetUrl: asset, currentUrl: asset,
      share: (_, _) async => throw StateError('Must not share'), pick: () async => throw StateError('Must not pick'));
    expect(result['status'], 'error');
  });
  test('allows JSON escape expansion without reducing the content limit', () async {
    final content = List.filled(4 * 1024 * 1024, '\u0000').join();
    final result = await handle({...request('shareBackup'), 'content': content});
    expect(result['status'], 'success');
  });
}
