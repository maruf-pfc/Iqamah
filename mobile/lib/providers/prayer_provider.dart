import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_log.dart';
import '../models/qaza_log.dart';
import '../services/database_helper.dart';

class PrayerProvider extends ChangeNotifier {
  final int currentUserId = 1; // Default single-user id for local app
  DateTime _selectedDate = DateTime.now();
  Map<PrayerName, PrayerLog?> _dailyLogs = {};
  List<QazaLog> _pendingQazas = [];
  Map<String, dynamic>? _analytics;
  bool _loading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  Map<PrayerName, PrayerLog?> get dailyLogs => _dailyLogs;
  List<QazaLog> get pendingQazas => _pendingQazas;
  Map<String, dynamic>? get analytics => _analytics;
  bool get loading => _loading;
  String? get error => _error;

  String get formattedSelectedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void changeSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchDailyLogs();
  }

  Future<void> fetchDailyLogs() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr = formattedSelectedDate;
      final logs = await DatabaseHelper.instance.getPrayerLogs(currentUserId, dateStr, dateStr);

      _dailyLogs = {
        for (var name in PrayerName.values) name: null,
      };

      for (final log in logs) {
        _dailyLogs[log.prayerName] = log;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingQazas() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingQazas = await DatabaseHelper.instance.getPendingQazas(currentUserId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalytics(String fromDate, String toDate) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await DatabaseHelper.instance.getAnalytics(currentUserId, fromDate, toDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logPrayer({
    required PrayerName prayerName,
    required bool isOffered,
    WaqtStatus? waqtStatus,
    MissedReason? missedReason,
    bool isJamaah = false,
    bool isTraveling = false,
    bool isJummah = false,
    bool isHome = false,
    String? quranNotes,
    bool hasTasbih = false,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr = formattedSelectedDate;
      final existing = _dailyLogs[prayerName];

      final log = PrayerLog(
        id: existing?.id ?? GuidGenerator.generate(),
        userId: currentUserId,
        prayerName: prayerName,
        prayerDate: dateStr,
        isOffered: isOffered,
        waqtStatus: waqtStatus,
        missedReason: missedReason,
        isJamaah: isJamaah,
        isTraveling: isTraveling,
        isJummah: isJummah,
        isHome: isHome,
        quranNotes: quranNotes,
        hasTasbih: hasTasbih,
        loggedAt: existing?.loggedAt ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await DatabaseHelper.instance.savePrayerLog(log);
      await fetchDailyLogs();
      await fetchPendingQazas();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fulfillQaza(String qazaId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await DatabaseHelper.instance.fulfillQaza(qazaId);
      await fetchPendingQazas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> exportBackup() async {
    try {
      await DatabaseHelper.instance.exportBackup();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> importBackup() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await DatabaseHelper.instance.importBackup();
      if (success) {
        await fetchDailyLogs();
        await fetchPendingQazas();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
