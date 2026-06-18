import 'prayer_log.dart';

enum QazaState { Pending, Offered }

class QazaLog {
  final String id;
  final String prayerLogId;
  final int userId;
  final PrayerName prayerName;
  final String originalPrayerDate; // yyyy-MM-dd
  final QazaState state;
  final String createdAt;
  final String? fulfilledAt;
  final int? timeToResolutionSeconds;

  QazaLog({
    required this.id,
    required this.prayerLogId,
    required this.userId,
    required this.prayerName,
    required this.originalPrayerDate,
    required this.state,
    required this.createdAt,
    this.fulfilledAt,
    this.timeToResolutionSeconds,
  });

  bool get isPending => state == QazaState.Pending;
  bool get isFulfilled => state == QazaState.Offered;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prayerLogId': prayerLogId,
      'userId': userId,
      'prayerName': prayerName.index,
      'originalPrayerDate': originalPrayerDate,
      'state': state.index,
      'createdAt': createdAt,
      'fulfilledAt': fulfilledAt,
      'timeToResolutionSeconds': timeToResolutionSeconds,
    };
  }

  factory QazaLog.fromMap(Map<String, dynamic> map) {
    return QazaLog(
      id: map['id'],
      prayerLogId: map['prayerLogId'],
      userId: map['userId'],
      prayerName: PrayerName.values[map['prayerName']],
      originalPrayerDate: map['originalPrayerDate'],
      state: QazaState.values[map['state']],
      createdAt: map['createdAt'],
      fulfilledAt: map['fulfilledAt'],
      timeToResolutionSeconds: map['timeToResolutionSeconds'],
    );
  }
}
