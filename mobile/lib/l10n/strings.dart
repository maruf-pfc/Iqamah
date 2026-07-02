// Iqamah App — Bilingual String Resources (Bengali + English)
// Complies with user specific translations:
// - Dashboard -> আজ
// - Prayer History -> নামাজের রেকর্ড
// - Analytics -> অগ্রগতি
// - Settings -> সেটিংস
// - Profile -> প্রোফাইল
// - Login -> লগইন
// - Register -> অ্যাকাউন্ট তৈরি করুন
// - Email -> Email
// - Password -> পাসওয়ার্ড
// - Dark Mode -> Dark Mode
// - Backup -> Backup
// - Restore -> Restore
// - Offline -> Offline
// - JSON -> JSON
// - Export -> Export
// - Import -> Import
// - Fajr -> ফজর
// - Dhuhr -> যোহর
// - Asr -> আসর
// - Maghrib -> মাগরিব
// - Isha -> ইশা
// - Qaza -> কাযা

class S {
  static bool isBn = true; // Default: Bengali

  static String get appTitle => isBn ? 'ইকামা' : 'Iqamah';

  // ── Bottom Navigation ──────────────────────────────────────────────────────
  static String get navDashboard => isBn ? 'আজ' : 'Today';
  static String get navQaza => isBn ? 'রেকর্ড' : 'Qaza';
  static String get navAnalytics => isBn ? 'অগ্রগতি' : 'Analytics';
  static String get navSettings => isBn ? 'সেটিংস' : 'Settings';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static String get dashTitle => isBn ? 'আসসালামু আলাইকুম 👋' : 'Assalamu Alaikum 👋';
  static String get dashSubtitle => isBn ? 'আজকের সালাত অভ্যাস' : 'Today\'s Salah Habits';
  static String get notLogged => isBn ? 'লিপিবদ্ধ নেই' : 'Not Logged';
  static String get logBtn => isBn ? 'লগ করুন' : 'Log';
  static String get editBtn => isBn ? 'সম্পাদনা' : 'Edit';
  static String get deleteBtn => isBn ? 'মুছুন' : 'Delete';
  static String get todayProgressTitle => isBn ? 'আজকের নামাজ' : 'Today\'s Salah';
  static String get streakTitle => isBn ? 'অবিরাম নামাজ' : 'Active Streak';
  static String streakSuffix(int days) => isBn ? '$days দিন' : '$days Days';

  // Prayer names (Bengali + Arabic always shown together)
  static String prayerBn(String name) {
    const map = {
      'Fajr': 'ফজর',
      'Dhuhr': 'যোহর',
      'Asr': 'আসর',
      'Maghrib': 'মাগরিব',
      'Isha': 'ইশা',
    };
    return map[name] ?? name;
  }

  static String prayerAr(String name) {
    const map = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };
    return map[name] ?? name;
  }

  // Status labels
  static String offeredStatus(String waqt) =>
      isBn ? 'আদায় ($waqt)' : 'Offered ($waqt)';
  static String get periodStatus =>
      isBn ? 'হায়েজ / নিফাস (ক্ষমাযোগ্য)' : 'Hayd/Nifas (Excused)';
  static String missedStatus(String reason) =>
      isBn ? 'ছুটে গেছে ($reason)' : 'Missed ($reason)';

  // Waqt names
  static String waqtLabel(String raw) {
    final map = {
      'Awwal': isBn ? 'আউয়াল' : 'Awwal',
      'Wast': isBn ? 'ওয়াসাত' : 'Wast',
      'Akhir': isBn ? 'আখির' : 'Akhir',
    };
    for (final k in map.keys) {
      if (raw.contains(k)) return map[k]!;
    }
    return raw;
  }

  // Missed reason labels
  static String reasonLabel(String raw) {
    if (!isBn) return raw;
    const map = {
      'ExcusedSleep': 'ঘুম (ক্ষমাযোগ্য)',
      'ExcusedForgetfulness': 'বিস্মৃতি (ক্ষমাযোগ্য)',
      'ExcusedImpurity': 'হায়েজ / নিফাস',
      'UnexcusedLaziness': 'অলসতা (কাসাল)',
      'UnexcusedDistraction': 'উদাসীনতা (গাফলাহ)',
      'UnexcusedSituational': 'ব্যস্ততা / পরিস্থিতিগত',
    };
    return map[raw] ?? raw;
  }

  // ── Logging Bottom Sheet ───────────────────────────────────────────────────
  static String logTitle(String prayer) =>
      isBn ? '$prayer সালাত লিপিবদ্ধ করুন' : 'Log $prayer';
  static String get tabOffered => isBn ? 'আদায়' : 'Offered';
  static String get tabMissed => isBn ? 'ছুটে গেছে' : 'Missed';
  static String get tabHayd => isBn ? 'হায়েজ / নিফাস' : 'Hayd / Nifas';

  static String get genderSettingTitle => isBn ? 'লিঙ্গ নির্ধারণ' : 'Gender Setting';
  static String get genderNote =>
      isBn ? 'হায়েজ / নিফাস অপশন শুধুমাত্র নারী ব্যবহারকারীদের জন্য।'
           : 'Hayd / Nifas option is only shown for female users.';
  static String get male => isBn ? 'পুরুষ' : 'Male';
  static String get female => isBn ? 'নারী' : 'Female';

  static String get waqtStatus => isBn ? 'ওয়াক্তের সময়' : 'Waqt Status';
  static String get congregation => isBn ? 'জামায়াতে আদায় (Jamaah)' : 'Congregation (Jamaah)';
  static String get prayedHome => isBn ? 'বাসায় পড়েছেন' : 'Prayed at Home';
  static String get tasbih => isBn ? 'তাসবীহ আদায় করেছেন' : 'Completed Tasbih';
  static String get jummah => isBn ? 'জুমু\'আহর সালাত' : 'Friday Jumu\'ah';
  static String get traveling => isBn ? 'সফররত (Musafir)' : 'Traveling (Musafir)';
  static String get quranNotes => isBn ? 'কোরআন পাঠের নোট (আয়াত, সূরা)' : 'Quran Reading Notes (Ayat, Surah)';
  static String get reasonMissed => isBn ? 'ছুটে যাওয়ার কারণ' : 'Reason Missed';
  static String get saveLog => isBn ? 'লগ সংরক্ষণ' : 'Save Log';
  static String get cancel => isBn ? 'বাতিল' : 'Cancel';

  static String get haydTitle => isBn ? 'হায়েজ / নিফাস' : 'Hayd / Nifas Period';
  static String get haydDesc =>
      isBn ? 'হায়েজ বা নিফাসের সময় সালাত ফরজ নয় এবং কাযাও লাগবে না।'
           : 'During Hayd or Nifas, prayer obligation is lifted. No Qaza required.';
  static String get janabahWarning =>
      isBn ? '⚠️ জানাবাত (গোসল ফরজ) অবস্থায় নামাজ মাফ হয় না — তখনও ফরজ।'
           : '⚠️ Janabah (Ghusl required) does NOT exempt from prayer — it remains obligatory.';

  // ── Qaza Tab ───────────────────────────────────────────────────────────────
  static String get qazaTitle => isBn ? 'কাযা খতিয়ান (قضاء)' : 'Qaza Ledger';
  static String get qazaSubtitle =>
      isBn ? 'ছুটে যাওয়া সালাতের দায় হিসাব করুন এবং অপেক্ষমান কাযা আদায় করুন।' : 'Track and resolve your missed prayers debt';
  static String get qazaPending => isBn ? 'বকেয়া কাযা' : 'Pending Qaza';
  static String get qazaDischarged => isBn ? 'আদায়কৃত' : 'Fulfilled';
  static String get qazaEmpty =>
      isBn ? 'আলহামদুলিল্লাহ! কোনো কাযা বাকি নেই।'
           : 'Alhamdulillah! No pending Qaza logs.';
  static String missedOn(String date) =>
      isBn ? '$date তারিখে ছুটে গেছে' : 'Missed on $date';
  static String get fulfill => isBn ? 'আদায় করুন' : 'Fulfill';
  static String get fulfillConfirmTitle => isBn ? 'কাযা আদায় করবেন?' : 'Fulfill Qaza?';
  static String fulfillConfirmMsg(String prayer, String date) =>
      isBn ? '$prayer ($date) কাযা আদায় হিসেবে চিহ্নিত করবেন?'
           : 'Mark $prayer ($date) as fulfilled Qaza?';
  static String get confirmYes => isBn ? 'হ্যাঁ, আদায় করুন' : 'Yes, Fulfill';
  static String get confirmNo => isBn ? 'না' : 'Cancel';
  static String get fulfillSuccess => isBn ? 'কাযা আদায় হিসেবে সংরক্ষিত হয়েছে ✓' : 'Qaza marked as fulfilled ✓';

  // ── Delete Confirmation ────────────────────────────────────────────────────
  static String get deleteConfirmTitle => isBn ? 'লগ মুছে ফেলবেন?' : 'Delete this log?';
  static String get deleteConfirmMsg =>
      isBn ? 'এই সালাতের লগ এবং সংযুক্ত কাযা মুছে যাবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।'
           : 'This prayer log and its linked Qaza will be permanently deleted.';
  static String get deleteYes => isBn ? 'হ্যাঁ, মুছুন' : 'Yes, Delete';
  static String get deleteSuccess => isBn ? 'সালাত লগ মুছে ফেলা হয়েছে।' : 'Prayer log deleted.';

  // ── Analytics Tab ──────────────────────────────────────────────────────────
  static String get analyticsTitle => isBn ? 'অগ্রগতি' : 'Analytics';
  static String get analyticsSubtitle =>
      isBn ? 'সালাহ কার্যক্ষমতা ও অভ্যাস' : 'Salah performance & habits';
  static String get offeredRatio => isBn ? 'আদায়ের হার' : 'Offered Ratio';
  static String offeredSummary(int offered, int obligated) =>
      isBn ? '$obligated বাধ্যতামূলকের মধ্যে $offered আদায় করেছেন'
           : 'Offered $offered out of $obligated obligated prayers';
  static String get punctualitySplit => isBn ? 'ওয়াক্ত বিভাজন' : 'Punctuality Split';
  static String get awwal => isBn ? 'আউয়াল ওয়াক্ত' : 'First (Awwal)';
  static String get wast => isBn ? 'ওয়াসাত ওয়াক্ত' : 'Middle (Wast)';
  static String get akhir => isBn ? 'আখির ওয়াক্ত' : 'Late (Akhir)';
  static String get missedReasons => isBn ? 'ছুটে যাওয়ার কারণসমূহ' : 'Missed Reasons';
  static String get sleepLabel => isBn ? 'ঘুম (Excused)' : 'Sleep (Excused)';
  static String get forgetLabel => isBn ? 'বিস্মৃতি (Excused)' : 'Forgetfulness (Excused)';
  static String get impurityLabel => isBn ? 'হায়েজ / নিফাস (Excused)' : 'Hayd/Nifas (Excused)';
  static String get lazinessLabel => isBn ? 'অলসতা (Unexcused)' : 'Laziness (Unexcused)';
  static String get distractionLabel => isBn ? 'উদাসীনতা (Unexcused)' : 'Distraction (Unexcused)';
  static String get situationalLabel => isBn ? 'পরিস্থিতিগত (Unexcused)' : 'Situational (Unexcused)';
  static String get qazaSummaryHeader => isBn ? 'কাযা সারসংক্ষেপ' : 'Qaza Summary';
  static String get pendingLabel => isBn ? 'বকেয়া' : 'Pending';
  static String get fulfilledLabel => isBn ? 'আদায়কৃত' : 'Fulfilled';
  static String resolutionTime(String h) =>
      isBn ? 'গড় আদায়ের সময়: $h ঘণ্টা' : 'Avg Resolution: $h hrs';
  static String get days7 => isBn ? '৭ দিন' : '7 Days';
  static String get days30 => isBn ? '৩০ দিন' : '30 Days';

  // ── Settings / Backup Tab ──────────────────────────────────────────────────
  static String get settingsTitle => isBn ? 'সেটিংস' : 'Settings';
  static String get settingsSubtitle =>
      isBn ? 'ডেটা আমদানি, রপ্তানি ও সুরক্ষা করুন' : 'Import, export, and secure your local data';
  static String get exportTitle => 'Export Backup File';
  static String get exportSubtitle =>
      isBn ? 'JSON ফাইলে ডেটা সংরক্ষণ করুন এবং শেয়ার করুন।'
           : 'Save your database records to a JSON file.';
  static String get importTitle => 'Import Backup File';
  static String get importSubtitle =>
      isBn ? 'পূর্বে রপ্তানি করা JSON ফাইল থেকে ডেটা পুনরুদ্ধার করুন।'
           : 'Restore records from a previously exported JSON backup.';
  static String get importSuccess => isBn ? 'ব্যাকআপ সফলভাবে পুনরুদ্ধার হয়েছে!' : 'Backup restored successfully!';
  static String get importFailed =>
      isBn ? 'পুনরুদ্ধার ব্যর্থ। JSON ফাইলটি সঠিক কিনা যাচাই করুন।'
           : 'Failed to restore backup. Please make sure the JSON file is valid.';
  static String get uninstallNotice =>
      isBn ? 'সতর্কতা: এই অ্যাপ আনইন্সটল করলে সকল সালাহ ডেটা স্থায়ীভাবে মুছে যাবে। নিয়মিত Backup রপ্তানি করুন।'
           : 'Uninstall Notice: All data is stored locally. Uninstalling will permanently delete all logged prayers. Export backups regularly.';
  static String get languageToggleTitle => isBn ? 'ভাষা: বাংলা' : 'Language: English';
  static String get languageToggleSubtitle =>
      isBn ? 'ইংরেজিতে স্যুইচ করতে ট্যাপ করুন' : 'Tap to switch to Bengali';
  static String get versionLabel => 'Iqamah Mobile v1.1.1';

  // ── Salah Time Tab ─────────────────────────────────────────────────────────
  static String get salahTimeTitle => isBn ? 'সালাতের সময়সূচি' : 'Salah Schedule';
  static String get detectBtn => isBn ? 'অনুসন্ধান' : 'Detect';
  static String get currentTime => isBn ? 'বর্তমান সময়' : 'Current Time';
  static String get forbiddenActive => isBn ? 'মাকরূহ সময় চলমান' : 'Makruh Period Active';
  static String get forbiddenBadge => isBn ? 'মাকরূহ' : 'FORBIDDEN';
  static String get activeBadge => isBn ? 'সক্রিয়' : 'ACTIVE';
  static String get forbiddenWindowsTitle =>
      isBn ? 'নিষিদ্ধ (মাকরূহ) সালাহ সময়সমূহ' : 'Forbidden (Makruh) Prayer Windows';
  static String get clickDetect => isBn ? 'অনুসন্ধান করুন' : 'Click Detect to load Salah times.';
  static String nextPrayer(String name, String hms) =>
      isBn ? 'পরবর্তী: $name — $hms' : 'Next: $name in $hms';
  static String get tomorrowFajr => isBn ? 'আগামীকাল ফজর' : 'Fajr (Tomorrow)';

  // Salah time prayer names with Bengali
  static String salahTimeName(String name) {
    const map = {
      'Fajr': 'ফজর',
      'Sunrise': 'সূর্যোদয়',
      'Dhuhr': 'যোহর',
      'Asr': 'আসর',
      'Maghrib': 'মাগরিব',
      'Isha': 'ইশা',
    };
    return map[name] ?? name;
  }
}
