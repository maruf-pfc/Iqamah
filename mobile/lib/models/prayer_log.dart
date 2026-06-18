enum PrayerName { Fajr, Dhuhr, Asr, Maghrib, Isha }

enum WaqtStatus { AwwalAlWaqt, WastAlWaqt, AkhirAlWaqt }

enum MissedReason {
  ExcusedImpurity,
  ExcusedSleep,
  ExcusedForgetfulness,
  UnexcusedSituational,
  UnexcusedLaziness,
  UnexcusedDistraction
}

class PrayerLog {
  final String id;
  final int userId;
  final PrayerName prayerName;
  final String prayerDate; // yyyy-MM-dd
  final bool isOffered;
  final WaqtStatus? waqtStatus;
  final MissedReason? missedReason;
  final bool isJamaah;
  final bool isTraveling;
  final bool isJummah;
  final bool isHome;
  final String? quranNotes;
  final bool hasTasbih;
  final String loggedAt;
  final String updatedAt;

  PrayerLog({
    required this.id,
    required this.userId,
    required this.prayerName,
    required this.prayerDate,
    required this.isOffered,
    this.waqtStatus,
    this.missedReason,
    required this.isJamaah,
    required this.isTraveling,
    required this.isJummah,
    required this.isHome,
    this.quranNotes,
    required this.hasTasbih,
    required this.loggedAt,
    required this.updatedAt,
  });

  bool get requiresQaza => !isOffered && missedReason != MissedReason.ExcusedImpurity;

  bool get isExcusedAbsence =>
      !isOffered &&
      (missedReason == MissedReason.ExcusedImpurity ||
          missedReason == MissedReason.ExcusedSleep ||
          missedReason == MissedReason.ExcusedForgetfulness);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'prayerName': prayerName.index,
      'prayerDate': prayerDate,
      'isOffered': isOffered ? 1 : 0,
      'waqtStatus': waqtStatus?.index,
      'missedReason': missedReason?.index,
      'isJamaah': isJamaah ? 1 : 0,
      'isTraveling': isTraveling ? 1 : 0,
      'isJummah': isJummah ? 1 : 0,
      'isHome': isHome ? 1 : 0,
      'quranNotes': quranNotes,
      'hasTasbih': hasTasbih ? 1 : 0,
      'loggedAt': loggedAt,
      'updatedAt': updatedAt,
    };
  }

  factory PrayerLog.fromMap(Map<String, dynamic> map) {
    return PrayerLog(
      id: map['id'],
      userId: map['userId'],
      prayerName: PrayerName.values[map['prayerName']],
      prayerDate: map['prayerDate'],
      isOffered: map['isOffered'] == 1,
      waqtStatus: map['waqtStatus'] != null ? WaqtStatus.values[map['waqtStatus']] : null,
      missedReason: map['missedReason'] != null ? MissedReason.values[map['missedReason']] : null,
      isJamaah: map['isJamaah'] == 1,
      isTraveling: map['isTraveling'] == 1,
      isJummah: map['isJummah'] == 1,
      isHome: map['isHome'] == 1,
      quranNotes: map['quranNotes'],
      hasTasbih: map['hasTasbih'] == 1,
      loggedAt: map['loggedAt'],
      updatedAt: map['updatedAt'],
    );
  }
}
