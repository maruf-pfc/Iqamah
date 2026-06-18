import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/prayer_log.dart';

void main() {
  group('PrayerLog Invariant Rules & State Machine Tests', () {
    test('Should require Qaza when prayer is missed for unexcused reason', () {
      final log = PrayerLog(
        id: '1',
        userId: 1,
        prayerName: PrayerName.Fajr,
        prayerDate: '2026-06-19',
        isOffered: false,
        missedReason: MissedReason.UnexcusedLaziness,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
        loggedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(log.requiresQaza, isTrue);
      expect(log.isExcusedAbsence, isFalse);
    });

    test('Should NOT require Qaza when prayer is missed due to ExcusedImpurity', () {
      final log = PrayerLog(
        id: '2',
        userId: 1,
        prayerName: PrayerName.Dhuhr,
        prayerDate: '2026-06-19',
        isOffered: false,
        missedReason: MissedReason.ExcusedImpurity,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
        loggedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(log.requiresQaza, isFalse);
      expect(log.isExcusedAbsence, isTrue);
    });

    test('Should be excused (but still require Qaza) when missed due to Sleep or Forgetfulness', () {
      final sleepLog = PrayerLog(
        id: '3',
        userId: 1,
        prayerName: PrayerName.Asr,
        prayerDate: '2026-06-19',
        isOffered: false,
        missedReason: MissedReason.ExcusedSleep,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
        loggedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final forgetLog = PrayerLog(
        id: '4',
        userId: 1,
        prayerName: PrayerName.Maghrib,
        prayerDate: '2026-06-19',
        isOffered: false,
        missedReason: MissedReason.ExcusedForgetfulness,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
        loggedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(sleepLog.requiresQaza, isTrue);
      expect(sleepLog.isExcusedAbsence, isTrue);

      expect(forgetLog.requiresQaza, isTrue);
      expect(forgetLog.isExcusedAbsence, isTrue);
    });
  });
}
