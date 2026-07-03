// ignore_for_file: unnecessary_import, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/prayer_log.dart';
import '../models/qaza_log.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iqamah_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = kIsWeb ? '' : await getDatabasesPath();
    final path = kIsWeb ? filePath : join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_logs (
        id TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        prayerName INTEGER NOT NULL,
        prayerDate TEXT NOT NULL,
        isOffered INTEGER NOT NULL,
        waqtStatus INTEGER,
        missedReason INTEGER,
        isJamaah INTEGER NOT NULL,
        isTraveling INTEGER NOT NULL,
        isJummah INTEGER NOT NULL,
        isHome INTEGER NOT NULL,
        quranNotes TEXT,
        hasTasbih INTEGER NOT NULL,
        loggedAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId, prayerDate, prayerName)
      )
    ''');

    await db.execute('''
      CREATE TABLE qaza_logs (
        id TEXT PRIMARY KEY,
        prayerLogId TEXT NOT NULL,
        userId INTEGER NOT NULL,
        prayerName INTEGER NOT NULL,
        originalPrayerDate TEXT NOT NULL,
        state INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        fulfilledAt TEXT,
        timeToResolutionSeconds INTEGER,
        FOREIGN KEY (prayerLogId) REFERENCES prayer_logs (id) ON DELETE CASCADE
      )
    ''');
  }

  // ── PrayerLog Operations ───────────────────────────────────────────────────

  Future<List<PrayerLog>> getPrayerLogs(int userId, String fromDate, String toDate) async {
    final db = await instance.database;
    final result = await db.query(
      'prayer_logs',
      where: 'userId = ? AND prayerDate >= ? AND prayerDate <= ?',
      whereArgs: [userId, fromDate, toDate],
      orderBy: 'prayerDate ASC, prayerName ASC',
    );
    return result.map((json) => PrayerLog.fromMap(json)).toList();
  }

  Future<PrayerLog?> getPrayerLog(int userId, String date, PrayerName name) async {
    final db = await instance.database;
    final result = await db.query(
      'prayer_logs',
      where: 'userId = ? AND prayerDate = ? AND prayerName = ?',
      whereArgs: [userId, date, name.index],
    );
    if (result.isNotEmpty) {
      return PrayerLog.fromMap(result.first);
    }
    return null;
  }

  Future<QazaLog?> getQazaLogForPrayer(String prayerLogId) async {
    final db = await instance.database;
    final result = await db.query(
      'qaza_logs',
      where: 'prayerLogId = ?',
      whereArgs: [prayerLogId],
    );
    if (result.isNotEmpty) {
      return QazaLog.fromMap(result.first);
    }
    return null;
  }

  Future<String> savePrayerLog(PrayerLog log) async {
    final db = await instance.database;
    final existing = await getPrayerLog(log.userId, log.prayerDate, log.prayerName);

    await db.transaction((txn) async {
      if (existing == null) {
        // Insert new log
        await txn.insert('prayer_logs', log.toMap());

        // Create Qaza Log if required
        if (log.requiresQaza) {
          final qaza = QazaLog(
            id: GuidGenerator.generate(),
            prayerLogId: log.id,
            userId: log.userId,
            prayerName: log.prayerName,
            originalPrayerDate: log.prayerDate,
            state: QazaState.Pending,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          );
          await txn.insert('qaza_logs', qaza.toMap());
        }
      } else {
        // Update existing log
        final wasRequiringQaza = existing.requiresQaza;
        final oldQaza = await getQazaLogForPrayer(existing.id);

        // State Transition logic: if Qaza was already fulfilled, we prevent reverting it to Offered
        if (oldQaza != null && oldQaza.isFulfilled && !log.requiresQaza && wasRequiringQaza) {
          throw Exception(
              "Cannot modify the original prayer to 'On-Time' because the associated Qaza has already been fulfilled.");
        }

        final updateMap = log.toMap();
        updateMap['id'] = existing.id; // Force using the existing record ID to preserve referential integrity

        await txn.update(
          'prayer_logs',
          updateMap,
          where: 'id = ?',
          whereArgs: [existing.id],
        );

        final isNowRequiringQaza = log.requiresQaza;

        if (!isNowRequiringQaza && wasRequiringQaza && oldQaza != null) {
          // Delete pending Qaza debt
          await txn.delete(
            'qaza_logs',
            where: 'id = ?',
            whereArgs: [oldQaza.id],
          );
        } else if (isNowRequiringQaza && !wasRequiringQaza) {
          // Incur new Qaza debt
          final qaza = QazaLog(
            id: GuidGenerator.generate(),
            prayerLogId: existing.id,
            userId: log.userId,
            prayerName: log.prayerName,
            originalPrayerDate: log.prayerDate,
            state: QazaState.Pending,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          );
          await txn.insert('qaza_logs', qaza.toMap());
        }
      }
    });

    return existing?.id ?? log.id;
  }

  /// Deletes a prayer log and its associated Qaza (via cascade).
  /// Throws if the Qaza has already been fulfilled (irreversible).
  Future<void> deletePrayerLog(String logId) async {
    final db = await instance.database;
    // Guard: don't allow delete if Qaza was already fulfilled
    final qazaResult = await db.query(
      'qaza_logs',
      where: 'prayerLogId = ?',
      whereArgs: [logId],
    );
    if (qazaResult.isNotEmpty) {
      final qaza = QazaLog.fromMap(qazaResult.first);
      if (qaza.isFulfilled) {
        throw Exception(
            'এই সালাতের কাজা ইতোমধ্যে আদায় করা হয়েছে। এটি মুছে ফেলা যাবে না।');
      }
    }
    await db.delete('prayer_logs', where: 'id = ?', whereArgs: [logId]);
  }

  // ── Qaza Operations ────────────────────────────────────────────────────────

  Future<List<QazaLog>> getPendingQazas(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'qaza_logs',
      where: 'userId = ? AND state = ?',
      whereArgs: [userId, QazaState.Pending.index],
      orderBy: 'originalPrayerDate ASC, prayerName ASC',
    );
    return result.map((json) => QazaLog.fromMap(json)).toList();
  }

  Future<void> fulfillQaza(String qazaId) async {
    final db = await instance.database;
    final result = await db.query('qaza_logs', where: 'id = ?', whereArgs: [qazaId]);
    if (result.isEmpty) return;

    final qaza = QazaLog.fromMap(result.first);
    if (qaza.isFulfilled) return;

    final fulfilledAt = DateTime.now().toUtc();
    final createdAt = DateTime.parse(qaza.createdAt);
    final diffSeconds = fulfilledAt.difference(createdAt).inSeconds;

    await db.update(
      'qaza_logs',
      {
        'state': QazaState.Offered.index,
        'fulfilledAt': fulfilledAt.toIso8601String(),
        'timeToResolutionSeconds': diffSeconds,
      },
      where: 'id = ?',
      whereArgs: [qazaId],
    );
  }

  Future<int> getActiveStreak(int userId) async {
    final db = await instance.database;
    final toDate = DateTime.now();
    final fromDate = toDate.subtract(const Duration(days: 30));
    final formatter = DateFormat('yyyy-MM-dd');

    final result = await db.query(
      'prayer_logs',
      where: 'userId = ? AND prayerDate >= ? AND prayerDate <= ? AND isOffered = 1',
      whereArgs: [userId, formatter.format(fromDate), formatter.format(toDate)],
    );

    final Set<String> offeredDates = result.map((row) => row['prayerDate'] as String).toSet();

    int streak = 0;
    DateTime checkDate = DateTime.now();
    String checkStr = formatter.format(checkDate);

    if (offeredDates.contains(checkStr)) {
      streak++;
    } else {
      checkDate = checkDate.subtract(const Duration(days: 1));
      final prevStr = formatter.format(checkDate);
      if (offeredDates.contains(prevStr)) {
        streak++;
        checkStr = prevStr;
      }
    }

    if (streak > 0) {
      while (true) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        final nextStr = formatter.format(checkDate);
        if (offeredDates.contains(nextStr)) {
          streak++;
        } else {
          break;
        }
      }
    }

    return streak > 0 ? streak : 1; // Default to 1 for motivation if there's any prayer or default placeholder
  }

  // ── Analytics Queries ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics(int userId, String fromDate, String toDate) async {
    final db = await instance.database;

    final totalLoggedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ?',
      [userId, fromDate, toDate],
    );
    final totalLogged = totalLoggedResult.first['count'] as int;

    // Total Obligated: total logs minus Excused Impurity logs
    final impurityIndex = MissedReason.ExcusedImpurity.index;
    final excusedImpurityResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, impurityIndex],
    );
    final excusedImpurityCount = excusedImpurityResult.first['count'] as int;
    final totalObligated = totalLogged - excusedImpurityCount;

    final totalOfferedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND isOffered = 1',
      [userId, fromDate, toDate],
    );
    final totalOffered = totalOfferedResult.first['count'] as int;
    final totalMissed = totalObligated - totalOffered;

    final offeredPercentage = totalObligated > 0 ? (totalOffered / totalObligated) * 100 : 0.0;

    // Punctuality counts
    final awwalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND waqtStatus = ?',
      [userId, fromDate, toDate, WaqtStatus.AwwalAlWaqt.index],
    );
    final wastResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND waqtStatus = ?',
      [userId, fromDate, toDate, WaqtStatus.WastAlWaqt.index],
    );
    final akhirResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND waqtStatus = ?',
      [userId, fromDate, toDate, WaqtStatus.AkhirAlWaqt.index],
    );

    final awwalCount = awwalResult.first['count'] as int;
    final wastCount = wastResult.first['count'] as int;
    final akhirCount = akhirResult.first['count'] as int;

    // Missed reason counts
    final sleepResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, MissedReason.ExcusedSleep.index],
    );
    final forgetResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, MissedReason.ExcusedForgetfulness.index],
    );
    final situationalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, MissedReason.UnexcusedSituational.index],
    );
    final lazinessResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, MissedReason.UnexcusedLaziness.index],
    );
    final distractionResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_logs WHERE userId = ? AND prayerDate >= ? AND prayerDate <= ? AND missedReason = ?',
      [userId, fromDate, toDate, MissedReason.UnexcusedDistraction.index],
    );

    final sleepCount = sleepResult.first['count'] as int;
    final forgetCount = forgetResult.first['count'] as int;
    final situationalCount = situationalResult.first['count'] as int;
    final lazinessCount = lazinessResult.first['count'] as int;
    final distractionCount = distractionResult.first['count'] as int;

    final totalExcused = excusedImpurityCount + sleepCount + forgetCount;
    final totalUnexcused = situationalCount + lazinessCount + distractionCount;

    // Qaza summary
    final pendingQazaResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM qaza_logs WHERE userId = ? AND state = ?',
      [userId, QazaState.Pending.index],
    );
    final fulfilledQazaResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM qaza_logs WHERE userId = ? AND state = ?',
      [userId, QazaState.Offered.index],
    );
    final avgResolutionResult = await db.rawQuery(
      'SELECT AVG(timeToResolutionSeconds) as avg FROM qaza_logs WHERE userId = ? AND state = ? AND timeToResolutionSeconds IS NOT NULL',
      [userId, QazaState.Offered.index],
    );

    final totalPendingQazas = pendingQazaResult.first['count'] as int;
    final totalFulfilledQazas = fulfilledQazaResult.first['count'] as int;
    final avgResolutionSec = avgResolutionResult.first['avg'] as double?;

    return {
      'totalLogged': totalLogged,
      'totalObligated': totalObligated,
      'totalOffered': totalOffered,
      'totalMissed': totalMissed,
      'offeredPercentage': offeredPercentage,
      'punctuality': {
        'awwalAlWaqtCount': awwalCount,
        'wastAlWaqtCount': wastCount,
        'akhirAlWaqtCount': akhirCount,
      },
      'missedReasons': {
        'excusedImpurityCount': excusedImpurityCount,
        'excusedSleepCount': sleepCount,
        'excusedForgetfulnessCount': forgetCount,
        'unexcusedSituationalCount': situationalCount,
        'unexcusedLazinessCount': lazinessCount,
        'unexcusedDistractionCount': distractionCount,
        'totalExcused': totalExcused,
        'totalUnexcused': totalUnexcused,
      },
      'qazaSummary': {
        'totalPending': totalPendingQazas,
        'totalFulfilled': totalFulfilledQazas,
        'totalIncurred': totalPendingQazas + totalFulfilledQazas,
        'averageResolutionTimeHours': avgResolutionSec != null ? (avgResolutionSec / 3600.0) : 0.0,
      }
    };
  }

  // ── Backup & Restore Operations ────────────────────────────────────────────

  Future<void> exportBackup() async {
    final db = await instance.database;
    final prayerLogs = await db.query('prayer_logs');
    final qazaLogs = await db.query('qaza_logs');

    final backupData = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'prayer_logs': prayerLogs,
      'qaza_logs': qazaLogs,
    };

    final jsonString = jsonEncode(backupData);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode(jsonString);

    final xFile = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: 'iqamah_backup_$timestamp.json',
    );

    // Share backup file
    await Share.shareXFiles(
      [xFile],
      subject: 'Iqamah Backup Export',
      text: 'Here is your Iqamah prayer log backup file.',
    );
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return false;
    }

    final file = result.files.single;
    String jsonString;
    if (kIsWeb) {
      if (file.bytes == null) return false;
      jsonString = utf8.decode(file.bytes!);
    } else {
      if (file.path == null) return false;
      jsonString = await File(file.path!).readAsString();
    }

    try {
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData['version'] != 1) {
        throw Exception('Unsupported backup version.');
      }

      final prayerLogsList = backupData['prayer_logs'] as List<dynamic>;
      final qazaLogsList = backupData['qaza_logs'] as List<dynamic>;

      final db = await instance.database;

      await db.transaction((txn) async {
        // Clear existing database records
        await txn.delete('qaza_logs');
        await txn.delete('prayer_logs');

        // Insert restored records
        for (final item in prayerLogsList) {
          await txn.insert('prayer_logs', Map<String, dynamic>.from(item));
        }

        for (final item in qazaLogsList) {
          await txn.insert('qaza_logs', Map<String, dynamic>.from(item));
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

// ── Lightweight GUID Generator ──────────────────────────────────────────────
class GuidGenerator {
  static String generate() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = base64Url.encode(utf8.encode(random)).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'uuid-${hash.substring(0, Math.min(hash.length, 16))}';
  }
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
