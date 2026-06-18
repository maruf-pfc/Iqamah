import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerEntry {
  final String name;
  final String emoji;
  final DateTime start;
  final DateTime end;

  PrayerEntry(this.name, this.start, this.end, this.emoji);

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  String get startFmt => DateFormat.jm().format(start);
  String get endFmt => DateFormat.jm().format(end);
}

class ForbiddenZone {
  final String label;
  final DateTime start;
  final DateTime end;

  ForbiddenZone(this.label, this.start, this.end);

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  String get fmt => "${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}";
}

class PrayerSchedule {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime midnight;
  late final List<ForbiddenZone> forbiddenZones;

  PrayerSchedule({required PrayerTimes t, required SunnahTimes s})
      : fajr = t.fajr,
        sunrise = t.sunrise,
        dhuhr = t.dhuhr,
        asr = t.asr,
        maghrib = t.maghrib,
        isha = t.isha,
        midnight = s.middleOfTheNight {
    forbiddenZones = [
      ForbiddenZone("Sunrise (Shuruq)", sunrise, sunrise.add(const Duration(minutes: 15))),
      ForbiddenZone("Solar Noon (Zawaal)", dhuhr.subtract(const Duration(minutes: 5)), dhuhr),
      ForbiddenZone("Sunset (Ghurub)", maghrib.subtract(const Duration(minutes: 15)), maghrib),
    ];
  }

  bool get isForbiddenNow => forbiddenZones.any((z) => z.isActive);

  List<PrayerEntry> get allPrayers => [
        PrayerEntry("Fajr", fajr, sunrise, "🌙"),
        PrayerEntry("Dhuhr", dhuhr, asr, "☀️"),
        PrayerEntry("Asr", asr, maghrib, "🌤️"),
        PrayerEntry("Maghrib", maghrib, isha, "🌅"),
        PrayerEntry("Isha", isha, midnight.isBefore(isha) ? midnight.add(const Duration(days: 1)) : midnight, "🌃"),
      ];

  PrayerEntry get currentOrNext {
    final now = DateTime.now();
    final all = allPrayers;
    return all.firstWhere((p) => p.end.isAfter(now), orElse: () => all.first);
  }
}

class SalahTimeProvider extends ChangeNotifier {
  PrayerSchedule? _schedule;
  bool _loading = false;
  double _latitude = 23.7639; // Default Dhaka
  double _longitude = 90.3889;
  String _locationName = "Dhaka, Bangladesh (Default)";
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  PrayerSchedule? get schedule => _schedule;
  bool get loading => _loading;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get locationName => _locationName;

  SalahTimeProvider() {
    _initTimezones();
    _initNotifications();
    _loadCachedLocation();
  }

  void _initTimezones() {
    tz.initializeTimeZones();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _latitude = prefs.getDouble('salah_lat') ?? 23.7639;
    _longitude = prefs.getDouble('salah_lng') ?? 90.3889;
    _locationName = prefs.getString('salah_loc') ?? "Dhaka, Bangladesh (Cached)";
    calculateSchedule();
  }

  Future<void> _saveCachedLocation(double lat, double lng, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('salah_lat', lat);
    await prefs.setDouble('salah_lng', lng);
    await prefs.setString('salah_loc', name);
  }

  Future<void> calculateSchedule() async {
    _loading = true;
    notifyListeners();

    try {
      final coords = Coordinates(_latitude, _longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      final now = DateTime.now();
      final dateComponents = DateComponents(now.year, now.month, now.day);
      
      final times = PrayerTimes(coords, dateComponents, params);
      final sunnah = SunnahTimes(times);

      _schedule = PrayerSchedule(t: times, s: sunnah);
      _scheduleNotifications();
    } catch (e) {
      debugPrint("Error calculating salah times: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> detectLocationAndCalculate() async {
    _loading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5)
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationName = "Detected Location";

      await _saveCachedLocation(_latitude, _longitude, _locationName);
      await calculateSchedule();
    } catch (e) {
      debugPrint("Error detecting location: $e");
      // Fallback to cached or default
      await calculateSchedule();
    }
  }

  Future<void> _scheduleNotifications() async {
    if (_schedule == null) return;
    
    try {
      // Clear pending to avoid overlapping schedules
      await _notificationsPlugin.cancelAll();

      int id = 0;

      // Schedule for each prayer start time
      for (final prayer in _schedule!.allPrayers) {
        if (prayer.start.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id++,
            "🌙 ${prayer.name} Azan",
            "It is time for ${prayer.name} prayer.",
            prayer.start,
          );
        }
      }

      // Schedule warnings for forbidden zones (10 minutes before zone start)
      for (final zone in _schedule!.forbiddenZones) {
        final warningTime = zone.start.subtract(const Duration(minutes: 10));
        if (warningTime.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id++,
            "⚠️ Forbidden Salah Zone Soon",
            "${zone.label} begins in 10 minutes. Avoid starting prayers.",
            warningTime,
          );
        }
      }
    } catch (e) {
      debugPrint("Error scheduling notifications: $e");
    }
  }

  Future<void> _scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    final location = tz.local;
    final tzScheduled = tz.TZDateTime.from(scheduledTime, location);

    const androidDetails = AndroidNotificationDetails(
      'salah_channel_id',
      'Salah Notifications',
      channelDescription: 'Azan alerts and forbidden prayer zone notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
