import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'models/prayer_log.dart';
import 'models/qaza_log.dart';
import 'providers/prayer_provider.dart';
import 'providers/salah_time_provider.dart';
import 'l10n/strings.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('has_completed_onboarding') ?? false;
  final lang = prefs.getString('iqamah_language') ?? 'bn';
  S.isBn = lang == 'bn';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()..fetchDailyLogs()..fetchPendingQazas()),
        ChangeNotifierProvider(create: (_) => SalahTimeProvider()),
      ],
      child: IqamahApp(hasOnboarded: hasOnboarded),
    ),
  );
}

class IqamahApp extends StatelessWidget {
  final bool hasOnboarded;
  const IqamahApp({Key? key, required this.hasOnboarded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iqamah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFF0F766E), // Teal 700
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5EEAD4), // Teal 300
          secondary: Color(0xFF0F766E), // Teal 700
          surface: Color(0xFF1E293B), // Slate 800
          background: Color(0xFF0F172A), // Slate 900
        ),
        fontFamily: 'NotoSansBengali',
      ),
      home: hasOnboarded ? const MainNavigationScreen() : const OnboardingScreen(),
    );
  }
}

// ── Responsive Layout Wrapper ────────────────────────────────────────────────
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  const ResponsiveLayout({Key? key, required this.child, this.bottomNavigationBar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19), // Dark outer page background
        body: Center(
          child: Container(
            width: 500,
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1E293B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Scaffold(
              body: child,
              bottomNavigationBar: bottomNavigationBar,
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: child,
        bottomNavigationBar: bottomNavigationBar,
      );
    }
  }
}

// Helper to translate digits to Bengali
String toBnDigits(String input) {
  const map = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };
  return input.replaceAllMapped(RegExp(r'[0-9]'), (m) => map[m.group(0)!] ?? m.group(0)!);
}

// Helper to translate weekday short names to Bengali
String toBnWeekday(String dayName) {
  const map = {
    'Sat': 'শনি',
    'Sun': 'রবি',
    'Mon': 'সোম',
    'Tue': 'মঙ্গল',
    'Wed': 'বুধ',
    'Thu': 'বৃহ',
    'Fri': 'শুক্র',
  };
  return map[dayName] ?? dayName.substring(0, 2);
}

// ── Onboarding Screen ────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLang = 'bn';
  String _selectedGender = 'male';

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // Top progress bar indicators
              Row(
                children: List.generate(3, (index) => Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? const Color(0xFF5EEAD4)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              
              // Onboarding Steps PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLanguageStep(),
                    _buildGenderStep(),
                    _buildWelcomeStep(),
                  ],
                ),
              ),
              
              // Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        _selectedLang == 'bn' ? 'আগের ধাপ' : 'Back',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Complete onboarding and navigate
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_completed_onboarding', true);
                        await prefs.setString('iqamah_gender', _selectedGender);
                        await prefs.setString('iqamah_language', _selectedLang);
                        S.isBn = _selectedLang == 'bn';
                        
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                          );
                        }
                      }
                    },
                    child: Text(
                      _currentPage < 2
                          ? (_selectedLang == 'bn' ? 'পরবর্তী' : 'Next')
                          : (_selectedLang == 'bn' ? 'শুরু করুন' : 'Get Started'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.translate_rounded, size: 48, color: Color(0xFF5EEAD4)),
        ),
        const SizedBox(height: 32),
        const Text(
          'ভাষা নির্বাচন করুন\nSelect Language',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
        ),
        const SizedBox(height: 12),
        const Text(
          'অ্যাপ্লিকেশন ইন্টারফেসের ভাষা নির্বাচন করুন। এটি পরবর্তীতে পরিবর্তনযোগ্য।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLang = 'bn';
                    S.isBn = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: _selectedLang == 'bn' ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedLang == 'bn' ? const Color(0xFF5EEAD4) : Colors.white10,
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'বাংলা',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLang = 'en';
                    S.isBn = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: _selectedLang == 'en' ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedLang == 'en' ? const Color(0xFF5EEAD4) : Colors.white10,
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'English',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    final title = _selectedLang == 'bn' ? 'লিঙ্গ নির্ধারণ' : 'Select Gender';
    final desc = _selectedLang == 'bn'
        ? 'হায়েজ ও নিফাস সংক্রান্ত বিশেষ বিধানসমূহ সঠিকভাবে ট্র্যাকিং করতে লিঙ্গ নির্বাচন প্রয়োজন।'
        : 'Selecting your gender configures specific prayer tracking features like menstruation excuses.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.wc_rounded, size: 48, color: Color(0xFF5EEAD4)),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'male';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'male' ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedGender == 'male' ? const Color(0xFF5EEAD4) : Colors.white10,
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.male_rounded, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLang == 'bn' ? 'पुरुष' : 'Male',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'female';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'female' ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedGender == 'female' ? const Color(0xFF5EEAD4) : Colors.white10,
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.female_rounded, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLang == 'bn' ? 'নারী' : 'Female',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    final title = _selectedLang == 'bn' ? 'إقامة | Iqamah' : 'إقامة | Iqamah';
    final desc = _selectedLang == 'bn'
        ? 'সালাহ নিয়মিত করার যাত্রায় আপনাকে স্বাগতম। আপনার সমস্ত নামাজের ডেটা সম্পূর্ণ গোপনীয়তার সাথে আপনার মোবাইল ফোনেই স্থানীয়ভাবে সংরক্ষিত থাকবে।'
        : 'Welcome to your daily habit companion. Establish consistency, track logs, and view progress safely. All data is kept 100% locally on your device.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.mosque_rounded, size: 56, color: Color(0xFF5EEAD4)),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white60, height: 1.5),
        ),
      ],
    );
  }
}

// ── Main Navigation Screen ───────────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const QazaTab(),
    const AnalyticsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          selectedItemColor: const Color(0xFF5EEAD4), // Teal 300
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.today_rounded), label: S.navDashboard),
            BottomNavigationBarItem(icon: const Icon(Icons.book_rounded), label: S.navQaza),
            BottomNavigationBarItem(icon: const Icon(Icons.analytics_rounded), label: S.navAnalytics),
            BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: S.navSettings),
          ],
        ),
      ),
      child: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────
class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final days = List.generate(6, (index) => DateTime.now().subtract(Duration(days: 5 - index)));

    int completedCount = 0;
    for (final name in PrayerName.values) {
      final log = provider.dailyLogs[name];
      if (log != null && log.isOffered) {
        completedCount++;
      }
    }
    double progress = completedCount / 5.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.dashTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    S.dashSubtitle,
                    style: TextStyle(fontSize: 12, color: const Color(0xFF5EEAD4).withOpacity(0.8)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Color(0xFF5EEAD4)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF0F766E),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1E293B),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    provider.changeSelectedDate(picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Circle Progress & Streak Motivation Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5EEAD4)),
                      ),
                    ),
                    Text(
                      S.isBn ? toBnDigits('$completedCount/৫') : '$completedCount/5',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.todayProgressTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.isBn 
                            ? '${toBnDigits((progress * 100).toInt().toString())}% আদায় হয়েছে' 
                            : '${(progress * 100).toInt()}% Completed',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.2),
                    border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        S.streakSuffix(provider.streak),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5EEAD4)),
                      ),
                      Text(
                        S.streakTitle,
                        style: const TextStyle(fontSize: 8, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal calendar list (6 columns matching web)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = DateFormat('yyyy-MM-dd').format(day) == provider.formattedSelectedDate;
              
              final dayName = DateFormat('E').format(day);
              final dayNum = DateFormat('d').format(day);
              
              final displayDayName = S.isBn ? toBnWeekday(dayName) : dayName.substring(0, 2);
              final displayDayNum = S.isBn ? toBnDigits(dayNum) : dayNum;

              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.changeSelectedDate(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5EEAD4) : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayDayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayDayNum,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4)))
                : ListView(
                    children: PrayerName.values.map((name) {
                      final log = provider.dailyLogs[name];
                      return PrayerLogCard(prayerName: name, log: log);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Prayer Log Card ──────────────────────────────────────────────────────────
class PrayerLogCard extends StatelessWidget {
  final PrayerName prayerName;
  final PrayerLog? log;

  const PrayerLogCard({Key? key, required this.prayerName, this.log}) : super(key: key);

  String _getPrayerIcon(PrayerName name) {
    switch (name) {
      case PrayerName.Fajr: return "🌙";
      case PrayerName.Dhuhr: return "☀️";
      case PrayerName.Asr: return "🌤️";
      case PrayerName.Maghrib: return "🌅";
      case PrayerName.Isha: return "🌃";
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final hasLog = log != null;
    final isOffered = log?.isOffered ?? false;
    final isPeriod = log?.missedReason == MissedReason.ExcusedImpurity;

    Color borderColor = Colors.white.withOpacity(0.05);
    Color statusColor = Colors.white24;
    if (isOffered) {
      borderColor = Colors.green.withOpacity(0.4);
      statusColor = const Color(0xFF16A34A);
    } else if (isPeriod) {
      borderColor = const Color(0xFF5EEAD4).withOpacity(0.4);
      statusColor = const Color(0xFF5EEAD4);
    } else if (hasLog) {
      borderColor = Colors.red.withOpacity(0.4);
      statusColor = const Color(0xFFDC2626);
    }

    return Dismissible(
      key: Key('prayer_${prayerName.name}_${log?.id ?? 'none'}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.undo_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              S.isBn ? 'লগ মুছুন (Undo)' : 'Delete Log (Undo)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.orange.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              S.isBn ? 'ছুটে গেছে (কাযা)' : 'Mark Missed (Qaza)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (hasLog) {
            try {
              await provider.deletePrayerLog(log!.id);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.deleteSuccess), backgroundColor: Colors.green),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
              );
            }
          }
        } else if (direction == DismissDirection.endToStart) {
          try {
            await provider.logPrayer(
              prayerName: prayerName,
              isOffered: false,
              missedReason: MissedReason.UnexcusedLaziness,
            );
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.isBn ? 'সালাতটি ছুটে গেছে (কাযা) হিসেবে চিহ্নিত করা হয়েছে।' : 'Prayer marked as Missed (Qaza).'),
                backgroundColor: Colors.orange,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
            );
          }
        }
        return false;
      },
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          if (!hasLog || !isOffered) {
            await provider.logPrayer(
              prayerName: prayerName,
              isOffered: true,
              waqtStatus: WaqtStatus.AwwalAlWaqt,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.isBn ? '${S.prayerBn(prayerName.name)} আদায় হয়েছে!' : '${prayerName.name} Offered!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            await provider.deletePrayerLog(log!.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.isBn ? 'লগ বাতিল করা হয়েছে।' : 'Log removed.'),
                backgroundColor: Colors.blueGrey,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left indicator status strip
                Container(
                  width: 6,
                  color: statusColor,
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getPrayerIcon(prayerName),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          S.prayerBn(prayerName.name),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          S.prayerAr(prayerName.name),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5EEAD4), fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        if (!hasLog)
                          Text(S.notLogged, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white38))
                        else if (isOffered)
                          Text(
                            S.offeredStatus(S.waqtLabel(log!.waqtStatus!.name)),
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                          )
                        else if (isPeriod)
                          Text(
                            S.periodStatus,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5EEAD4), fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            S.missedStatus(S.reasonLabel(log!.missedReason!.name)),
                            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                          ),

                        if (hasLog) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (log!.isTraveling)
                                _buildBadge('🛫 সফর (Traveling)', Colors.blue.shade900, Colors.blue.shade300),
                              if (log!.isJamaah)
                                _buildBadge('👥 জামায়াত (Jamaah)', const Color(0xFF002B16), Colors.green.shade300),
                              if (log!.isJummah)
                                _buildBadge('🕌 জুমু\'আহ (Jummah)', const Color(0xFF002D24), Colors.teal.shade300),
                              if (log!.isHome)
                                _buildBadge('🏠 বাসা (Home)', const Color(0xFF332200), Colors.amber.shade300),
                              if (log!.hasTasbih)
                                _buildBadge('📿 তাসবীহ (Tasbih)', const Color(0xFF2E0014), Colors.pink.shade300),
                              if (log!.quranNotes != null && log!.quranNotes!.trim().isNotEmpty)
                                _buildBadge('📖 কোরআন (Quran)', const Color(0xFF1B002B), Colors.purple.shade300),
                            ],
                          ),
                        ]
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isOffered
                                ? const Color(0xFF16A34A)
                                : (hasLog && !isOffered && !isPeriod
                                    ? const Color(0xFFDC2626)
                                    : (isPeriod
                                        ? const Color(0xFF0F766E).withOpacity(0.2)
                                        : Colors.transparent)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOffered
                                  ? const Color(0xFF16A34A)
                                  : (hasLog && !isOffered && !isPeriod
                                      ? const Color(0xFFDC2626)
                                      : (isPeriod
                                          ? const Color(0xFF5EEAD4)
                                          : Colors.white24)),
                              width: 2.0,
                            ),
                          ),
                          child: isOffered
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : (hasLog && !isOffered && !isPeriod
                                  ? const Icon(Icons.close, size: 18, color: Colors.white)
                                  : (isPeriod
                                      ? const Icon(Icons.spa_outlined, size: 16, color: Color(0xFF5EEAD4))
                                      : null)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFF1E293B),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (_) => LoggingBottomSheet(prayerName: prayerName, existing: log),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Logging Bottom Sheet ─────────────────────────────────────────────────────
class LoggingBottomSheet extends StatefulWidget {
  final PrayerName prayerName;
  final PrayerLog? existing;

  const LoggingBottomSheet({Key? key, required this.prayerName, this.existing}) : super(key: key);

  @override
  State<LoggingBottomSheet> createState() => _LoggingBottomSheetState();
}

class _LoggingBottomSheetState extends State<LoggingBottomSheet> {
  late String _logType; // 'offered', 'missed', 'period'
  WaqtStatus _waqtStatus = WaqtStatus.AwwalAlWaqt;
  MissedReason _missedReason = MissedReason.UnexcusedLaziness;
  bool _isJamaah = false;
  bool _isTraveling = false;
  bool _isJummah = false;
  bool _isHome = false;
  bool _hasTasbih = false;
  bool? _isFemale;
  final TextEditingController _quranNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final g = prefs.getString('iqamah_gender');
      if (mounted) setState(() => _isFemale = g == 'female');
    });
    if (widget.existing != null) {
      final log = widget.existing!;
      if (log.isOffered) {
        _logType = 'offered';
        _waqtStatus = log.waqtStatus ?? WaqtStatus.AwwalAlWaqt;
      } else if (log.missedReason == MissedReason.ExcusedImpurity) {
        _logType = 'period';
      } else {
        _logType = 'missed';
        _missedReason = log.missedReason ?? MissedReason.UnexcusedLaziness;
      }
      _isJamaah = log.isJamaah;
      _isTraveling = log.isTraveling;
      _isJummah = log.isJummah;
      _isHome = log.isHome;
      _hasTasbih = log.hasTasbih;
      _quranNotesController.text = log.quranNotes ?? '';
    } else {
      _logType = 'offered';
    }
  }

  @override
  void dispose() {
    _quranNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPeriodTab = _isFemale == true;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.logTitle(S.prayerBn(widget.prayerName.name)),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildTabButton(S.tabOffered, 'offered'),
              const SizedBox(width: 8),
              _buildTabButton(S.tabMissed, 'missed'),
              if (showPeriodTab) ...[
                const SizedBox(width: 8),
                _buildTabButton(S.tabHayd, 'period'),
              ]
            ],
          ),
          const SizedBox(height: 20),

          if (_logType == 'offered') ...[
            Text(S.waqtStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildWaqtOption(S.waqtLabel('Awwal'), WaqtStatus.AwwalAlWaqt),
                const SizedBox(width: 8),
                _buildWaqtOption(S.waqtLabel('Wast'), WaqtStatus.WastAlWaqt),
                const SizedBox(width: 8),
                _buildWaqtOption(S.waqtLabel('Akhir'), WaqtStatus.AkhirAlWaqt),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(S.congregation, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              value: _isJamaah,
              activeColor: const Color(0xFF5EEAD4),
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _isJamaah = val ?? false),
            ),
            CheckboxListTile(
              title: Text(S.prayedHome, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              value: _isHome,
              activeColor: const Color(0xFF5EEAD4),
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _isHome = val ?? false),
            ),
            CheckboxListTile(
              title: Text(S.tasbih, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              value: _hasTasbih,
              activeColor: const Color(0xFF5EEAD4),
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _hasTasbih = val ?? false),
            ),
            if (widget.prayerName == PrayerName.Dhuhr && DateTime.now().weekday == DateTime.friday)
              CheckboxListTile(
                title: Text(S.jummah, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                value: _isJummah,
                activeColor: const Color(0xFF5EEAD4),
                checkColor: Colors.black,
                onChanged: (val) => setState(() => _isJummah = val ?? false),
              ),
            CheckboxListTile(
              title: Text(S.traveling, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              value: _isTraveling,
              activeColor: const Color(0xFF5EEAD4),
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _isTraveling = val ?? false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quranNotesController,
              decoration: InputDecoration(
                labelText: S.quranNotes,
                labelStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5EEAD4))),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ] else if (_logType == 'missed') ...[
            Text(S.reasonMissed, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MissedReason>(
                  value: _missedReason,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  onChanged: (val) {
                    if (val != null) setState(() => _missedReason = val);
                  },
                  items: MissedReason.values
                      .where((r) => r != MissedReason.ExcusedImpurity)
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(S.reasonLabel(r.name), style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(S.traveling, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              value: _isTraveling,
              activeColor: const Color(0xFF5EEAD4),
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _isTraveling = val ?? false),
            ),
          ] else if (_logType == 'period') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5EEAD4).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.haydTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5EEAD4))),
                  const SizedBox(height: 8),
                  Text(
                    S.haydDesc,
                    style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    S.janabahWarning,
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade300, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.cancel, style: const TextStyle(color: Colors.white60)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  try {
                    final isOffered = _logType == 'offered';
                    final isPeriod = _logType == 'period';
                    await context.read<PrayerProvider>().logPrayer(
                          prayerName: widget.prayerName,
                          isOffered: isOffered,
                          waqtStatus: isOffered ? _waqtStatus : null,
                          missedReason: isPeriod
                              ? MissedReason.ExcusedImpurity
                              : !isOffered
                                  ? _missedReason
                                  : null,
                          isJamaah: isOffered && _isJamaah,
                          isTraveling: _isTraveling,
                          isJummah: isOffered && _isJummah,
                          isHome: isOffered && _isHome,
                          quranNotes: isOffered ? _quranNotesController.text : null,
                          hasTasbih: isOffered && _hasTasbih,
                        );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                },
                child: Text(S.saveLog, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String type) {
    final isSelected = _logType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _logType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF5EEAD4) : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaqtOption(String label, WaqtStatus val) {
    final isSelected = _waqtStatus == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _waqtStatus = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF5EEAD4) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Qaza Tab ─────────────────────────────────────────────────────────────────
class QazaTab extends StatefulWidget {
  const QazaTab({Key? key}) : super(key: key);

  @override
  State<QazaTab> createState() => _QazaTabState();
}

class _QazaTabState extends State<QazaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().fetchPendingQazas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.qazaTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            S.qazaSubtitle,
            style: TextStyle(fontSize: 12, color: const Color(0xFF5EEAD4).withOpacity(0.8)),
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(S.qazaPending, S.isBn ? toBnDigits('${provider.pendingQazas.length}') : '${provider.pendingQazas.length}', Colors.red),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildSummaryStat(S.qazaDischarged, S.isBn ? 'অটো' : 'Auto', const Color(0xFF5EEAD4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4)))
                : provider.pendingQazas.isEmpty
                    ? Center(
                        child: Text(
                          S.qazaEmpty,
                          style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.pendingQazas.length,
                        itemBuilder: (context, index) {
                          final qaza = provider.pendingQazas[index];
                          final formattedDate = S.isBn ? toBnDigits(qaza.originalPrayerDate) : qaza.originalPrayerDate;
                          
                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: Text(
                                S.prayerBn(qaza.prayerName.name),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                S.isBn ? '$formattedDate তারিখে ছুটে গেছে' : 'Missed on $formattedDate',
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: const Color(0xFF5EEAD4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E293B),
                                      title: Text(S.fulfillConfirmTitle, style: const TextStyle(color: Colors.white)),
                                      content: Text(
                                        S.fulfillConfirmMsg(S.prayerBn(qaza.prayerName.name), formattedDate),
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.confirmNo)),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(S.confirmYes),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await provider.fulfillQaza(qaza.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(S.fulfillSuccess), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                                child: Text(S.fulfill),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────────────────────
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({Key? key}) : super(key: key);

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _rangeDays = 7;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final to = DateTime.now();
      final from = to.subtract(Duration(days: _rangeDays));
      final formatter = DateFormat('yyyy-MM-dd');
      context.read<PrayerProvider>().fetchAnalytics(formatter.format(from), formatter.format(to));
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final stats = provider.analytics;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.analyticsTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    S.analyticsSubtitle,
                    style: TextStyle(fontSize: 12, color: const Color(0xFF5EEAD4).withOpacity(0.8)),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: _rangeDays,
                dropdownColor: const Color(0xFF1E293B),
                items: [
                  DropdownMenuItem(value: 7, child: Text(S.days7, style: const TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 30, child: Text(S.days30, style: const TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _rangeDays = val;
                      _loadAnalytics();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.loading || stats == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4)))
                : ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              S.offeredRatio,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              S.isBn 
                                  ? '${toBnDigits((stats['offeredPercentage'] as double).toStringAsFixed(1))}%'
                                  : '${(stats['offeredPercentage'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              S.offeredSummary(stats['totalOffered'] as int, stats['totalObligated'] as int),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHeader(S.punctualitySplit),
                      _buildDetailRow(S.awwal, stats['punctuality']['awwalAlWaqtCount'].toString(), Colors.green),
                      _buildDetailRow(S.wast, stats['punctuality']['wastAlWaqtCount'].toString(), const Color(0xFF5EEAD4)),
                      _buildDetailRow(S.akhir, stats['punctuality']['akhirAlWaqtCount'].toString(), Colors.amber),
                      const SizedBox(height: 20),
                      _buildHeader(S.missedReasons),
                      _buildDetailRow(S.sleepLabel, stats['missedReasons']['excusedSleepCount'].toString(), Colors.white70),
                      _buildDetailRow(S.forgetLabel, stats['missedReasons']['excusedForgetfulnessCount'].toString(), Colors.white70),
                      _buildDetailRow(S.impurityLabel, stats['missedReasons']['excusedImpurityCount'].toString(), Colors.pink.shade300),
                      _buildDetailRow(S.lazinessLabel, stats['missedReasons']['unexcusedLazinessCount'].toString(), Colors.red),
                      _buildDetailRow(S.distractionLabel, stats['missedReasons']['unexcusedDistractionCount'].toString(), Colors.red),
                      _buildDetailRow(S.situationalLabel, stats['missedReasons']['unexcusedSituationalCount'].toString(), Colors.red),
                      const SizedBox(height: 20),
                      _buildHeader(S.qazaSummaryHeader),
                      _buildDetailRow(S.pendingLabel, stats['qazaSummary']['totalPending'].toString(), Colors.red),
                      _buildDetailRow(S.fulfilledLabel, stats['qazaSummary']['totalFulfilled'].toString(), Colors.green),
                      _buildDetailRow(
                        S.resolutionTime(
                          S.isBn 
                              ? toBnDigits((stats['qazaSummary']['averageResolutionTimeHours'] as double).toStringAsFixed(1))
                              : (stats['qazaSummary']['averageResolutionTimeHours'] as double).toStringAsFixed(1)
                        ), 
                        '', 
                        Colors.white
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5EEAD4))),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(
            S.isBn ? toBnDigits(value) : value, 
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }
}

// ── Settings Tab ─────────────────────────────────────────────────────────────
class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool? _isFemale;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final g = prefs.getString('iqamah_gender');
      if (mounted) setState(() => _isFemale = g == 'female');
    });
  }

  Future<void> _setGender(bool female) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iqamah_gender', female ? 'female' : 'male');
    if (mounted) setState(() => _isFemale = female);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.settingsTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            S.settingsSubtitle,
            style: TextStyle(fontSize: 12, color: const Color(0xFF5EEAD4).withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: [
                // Navigation Screen links
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFF5EEAD4)),
                        title: Text(S.salahTimeTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(S.isBn ? 'নিষিদ্ধ ওয়াক্ত ও সালাতের সময়সূচি' : 'Forbidden windows & prayer schedules', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SalahTimeScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.import_contacts_rounded, color: Color(0xFF5EEAD4)),
                        title: Text(S.isBn ? 'সালাহ এবং ওজরের মাসয়ালা' : 'Salah & Excuse Fiqh Rules', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(S.isBn ? 'সালাতের কাযা ও আদায় নীতিমালা' : 'Guide regarding Qaza & excuses', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GuideScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Language Selector
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.translate_rounded, color: Color(0xFF5EEAD4)),
                    title: Text(S.languageToggleTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(S.languageToggleSubtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: Switch(
                      value: S.isBn,
                      activeColor: const Color(0xFF5EEAD4),
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('iqamah_language', val ? 'bn' : 'en');
                        setState(() => S.isBn = val);
                        if (mounted) {
                          context.findAncestorStateOfType<_MainNavigationScreenState>()?.setState(() {});
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Gender Toggle
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wc_rounded, color: Color(0xFF5EEAD4)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.genderSettingTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(S.genderNote, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFemale == false ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _setGender(false),
                                child: Text(S.male, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFemale == true ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _setGender(true),
                                child: Text(S.female, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Backup / Restore
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF5EEAD4)),
                        title: Text(S.exportTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(S.exportSubtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        onTap: () => provider.exportBackup(),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.file_download_outlined, color: Color(0xFF5EEAD4)),
                        title: Text(S.importTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(S.importSubtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        onTap: () async {
                          final success = await provider.importBackup();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? S.importSuccess : S.importFailed),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reset Application
                Card(
                  color: Colors.red.shade900.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade900.withOpacity(0.3), width: 1.5),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: Text(
                      S.isBn ? 'অ্যাপ্লিকেশন রিসেট করুন' : 'Reset Application',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    subtitle: Text(
                      S.isBn
                          ? 'সব ডেটা মুছে অ্যাপ্লিকেশনটি পুনরায় অনবোর্ডিং অবস্থায় নিয়ে যাবে।'
                          : 'Clear all data and restart onboarding.',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: Text(S.isBn ? 'আপনি কি নিশ্চিত?' : 'Are you sure?', style: const TextStyle(color: Colors.white)),
                          content: Text(
                            S.isBn
                                ? 'রিসেট করলে আপনার সমস্ত সেভ করা সালাত লগ চিরতরে মুছে যাবে।'
                                : 'This will permanently delete all your prayer logs and reset onboarding.',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(S.isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                              child: Text(S.isBn ? 'রিসেট' : 'Reset'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        
                        final db = await DatabaseHelper.instance.database;
                        await db.transaction((txn) async {
                          await txn.delete('qaza_logs');
                          await txn.delete('prayer_logs');
                        });
                        
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Local Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          S.uninstallNotice,
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Center(
                  child: Text(
                    S.versionLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.white24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Salah Time Screen ────────────────────────────────────────────────────────
class SalahTimeScreen extends StatefulWidget {
  const SalahTimeScreen({Key? key}) : super(key: key);

  @override
  State<SalahTimeScreen> createState() => _SalahTimeScreenState();
}

class _SalahTimeScreenState extends State<SalahTimeScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getCountdownText(PrayerSchedule schedule) {
    final nowMs = _now.millisecondsSinceEpoch;
    final prayers = [
      {'name': S.isBn ? 'ফজর' : 'Fajr', 'start': schedule.fajr.millisecondsSinceEpoch},
      {'name': S.isBn ? 'যোহর' : 'Dhuhr', 'start': schedule.dhuhr.millisecondsSinceEpoch},
      {'name': S.isBn ? 'আসর' : 'Asr', 'start': schedule.asr.millisecondsSinceEpoch},
      {'name': S.isBn ? 'মাগরিব' : 'Maghrib', 'start': schedule.maghrib.millisecondsSinceEpoch},
      {'name': S.isBn ? 'ইশা' : 'Isha', 'start': schedule.isha.millisecondsSinceEpoch},
    ];

    final next = prayers.firstWhere((p) => (p['start'] as int) > nowMs, orElse: () => <String, Object>{});
    String prefix = '';
    int diff = 0;

    if (next.isNotEmpty) {
      prefix = next['name'] as String;
      diff = (next['start'] as int) - nowMs;
    } else {
      prefix = S.isBn ? 'ফজর (আগামীকাল)' : 'Fajr (Tomorrow)';
      final tomorrowFajr = schedule.fajr.add(const Duration(days: 1)).millisecondsSinceEpoch;
      diff = tomorrowFajr - nowMs;
    }

    final secs = diff ~/ 1000;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;

    final pad = (int n) => n.toString().padLeft(2, '0');
    final countdown = '${pad(h)}:${pad(m)}:${pad(s)}';
    return S.isBn 
        ? S.nextPrayer(prefix, toBnDigits(countdown))
        : S.nextPrayer(prefix, countdown);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalahTimeProvider>();
    final schedule = provider.schedule;

    ForbiddenZone? activeZone;
    if (schedule != null) {
      for (final zone in schedule.forbiddenZones) {
        if (_now.isAfter(zone.start) && _now.isBefore(zone.end)) {
          activeZone = zone;
          break;
        }
      }
    }

    String displayLocation = provider.locationName;
    if (S.isBn && displayLocation.contains("Default")) {
      displayLocation = "ঢাকা, বাংলাদেশ (ডিফল্ট)";
    }

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.salahTimeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFF5EEAD4)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  displayLocation,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.detectLocationAndCalculate();
                      },
                      icon: const Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                      label: Text(S.detectBtn, style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: const Color(0xFF5EEAD4),
                        side: const BorderSide(color: Color(0xFF5EEAD4), width: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (activeZone != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade900.withOpacity(0.25),
                      border: Border.all(color: Colors.orange.shade700, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.forbiddenActive,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${S.isBn ? _translateZoneLabel(activeZone.label) : activeZone.label}: ${S.isBn ? toBnDigits(activeZone.fmt) : activeZone.fmt}',
                                style: TextStyle(color: Colors.orange.shade100, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade500, width: 0.5),
                          ),
                          child: Text(
                            S.forbiddenBadge,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.1), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.currentTime,
                            style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            S.isBn ? toBnDigits(DateFormat.jms().format(_now)) : DateFormat.jms().format(_now),
                            style: const TextStyle(fontSize: 20, fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      if (schedule != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5EEAD4).withOpacity(0.08),
                            border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.2), width: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getCountdownText(schedule),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (provider.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF5EEAD4)),
                    ),
                  )
                else if (schedule == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(S.clickDetect, style: const TextStyle(color: Colors.white30)),
                    ),
                  )
                else ...[
                  ...schedule.allPrayers.map((prayer) {
                    final active = prayer.isActive;
                    final showForbiddenBadge = active && activeZone != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0F766E) : const Color(0xFF1E293B).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? const Color(0xFF5EEAD4).withOpacity(0.5) : const Color(0xFF5EEAD4).withOpacity(0.05),
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(prayer.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.salahTimeName(prayer.name),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: active ? Colors.white : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  S.isBn 
                                      ? '${toBnDigits(prayer.startFmt)} – ${toBnDigits(prayer.endFmt)}'
                                      : '${prayer.startFmt} – ${prayer.endFmt}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: active ? Colors.white70 : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showForbiddenBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade500, width: 0.5),
                              ),
                              child: Text(
                                '⛔ ${S.forbiddenBadge}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (active)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5EEAD4).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                S.activeBadge,
                                style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  Text(
                    S.forbiddenWindowsTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: schedule.forbiddenZones.map((zone) {
                      final isZoneActive = _now.isAfter(zone.start) && _now.isBefore(zone.end);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isZoneActive
                              ? Colors.orange.shade900.withOpacity(0.1)
                              : const Color(0xFF1E293B).withOpacity(0.2),
                          border: Border.all(
                            color: isZoneActive
                                ? Colors.orange.shade500.withOpacity(0.3)
                                : const Color(0xFF5EEAD4).withOpacity(0.05),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              S.isBn ? _translateZoneLabel(zone.label) : zone.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isZoneActive ? Colors.orangeAccent : Colors.white70,
                              ),
                            ),
                            Text(
                              S.isBn ? toBnDigits(zone.fmt) : zone.fmt,
                              style: TextStyle(
                                fontSize: 12,
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: isZoneActive ? Colors.orangeAccent : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateZoneLabel(String label) {
    if (label.contains("Sunrise")) return "সূর্যোদয় (ইশরাক)";
    if (label.contains("Solar Noon")) return "মধ্যাহ্ন (যাওয়াল)";
    if (label.contains("Sunset")) return "সূর্যাস্ত (গুরুব)";
    return label;
  }
}

// ── Guide Screen ─────────────────────────────────────────────────────────────
class GuideScreen extends StatelessWidget {
  const GuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.isBn ? 'সালাহ ও ওজরের মাসয়ালা' : 'Salah & Fiqh Guide', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: const Color(0xFF5EEAD4),
              labelColor: const Color(0xFF5EEAD4),
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: S.isBn ? 'কাযা নীতিমালা' : 'Qaza Rules'),
                Tab(text: S.isBn ? 'সময়ানুবর্তিতা' : 'Punctuality'),
                Tab(text: S.isBn ? 'অ্যাপ ব্যবহার' : 'App Usage'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildQazaRulesTab(),
              _buildPunctualityTab(),
              _buildAppUsageTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQazaRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(S.isBn ? '🟢 ক্ষমাযোগ্য ওজর (Excused Absence)' : '🟢 Excused Absences'),
        _buildRuleCard(
          title: S.isBn ? 'ঘুম (Sleep)' : 'Sleep',
          desc: S.isBn 
              ? 'যদি কেউ অনিচ্ছাকৃতভাবে ঘুমিয়ে থাকার কারণে সালাত মিস করে, তবে জাগ্রত হওয়ামাত্রই তা আদায় করা ফরজ। এটি গুনাহ নয়।'
              : 'If someone misses prayer due to sleep, it is obligatory to pray it as soon as they wake up. This is not considered a sin if unintentional.',
        ),
        _buildRuleCard(
          title: S.isBn ? 'ভুলে যাওয়া (Forgetfulness)' : 'Forgetfulness',
          desc: S.isBn 
              ? 'অসচেতনতা বা অনিচ্ছাকৃত ভুলে সালাত ছুটে গেলে মনে হওয়ামাত্রই তা আদায় করা আবশ্যক।'
              : 'If missed due to genuine forgetfulness, it is obligatory to perform Qaza as soon as it is remembered.',
        ),
        _buildRuleCard(
          title: S.isBn ? 'হায়েজ ও নিফাস (Menstruation / Nifas)' : 'Menstruation / Nifas',
          desc: S.isBn 
              ? 'নারীদের মাসিক বা সন্তান প্রসব পরবর্তী অপবিত্রতার সময়ে সালাত ফরজ নয় এবং এগুলোর কাযাও আদায় করতে হয় না।'
              : 'During menstruation or post-natal impurity, the prayer obligation is lifted completely. No Qaza is required.',
        ),
        const SizedBox(height: 12),
        _buildSectionHeader(S.isBn ? '🔴 সাধারণ অবহেলা (Unexcused Absence)' : '🔴 Unexcused Absences'),
        _buildRuleCard(
          title: S.isBn ? 'অলসতা (Laziness)' : 'Laziness',
          desc: S.isBn 
              ? 'অলসতাবশত সালাত না পড়া একটি অত্যন্ত বড় কবিরা গুনাহ। এর জন্য তাওবাহ করতে হবে এবং অবিলম্বে কাযা আদায় করা আবশ্যক।'
              : 'Intentionally missing a prayer out of laziness is a major sin. Sincere repentance (Tawbah) and immediate Qaza are mandatory.',
        ),
        _buildRuleCard(
          title: S.isBn ? 'উদাসীনতা (Distraction)' : 'Distraction',
          desc: S.isBn 
              ? 'দুনিয়াবি খেলাধুলা, আড্ডা বা বিনোদনে মত্ত হয়ে ওয়াক্ত পার করে দেওয়া অত্যন্ত গর্হিত কাজ।'
              : 'Allowing worldly distractions or entertainment to cause you to miss a prayer is highly prohibited.',
        ),
      ],
    );
  }

  Widget _buildPunctualityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(S.isBn ? 'সালাতের ওয়াক্তের তিনটি স্তর' : 'Three Levels of Prayer Punctuality'),
        _buildRuleCard(
          title: S.isBn ? '১. আউয়াল ওয়াক্ত (প্রথম অংশ)' : '1. First Waqt (Awwal)',
          desc: S.isBn 
              ? 'সালাতের ওয়াক্ত শুরু হওয়ার সাথে সাথে সালাত আদায় করা সর্বোত্তম ও আল্লাহর নিকট সবচেয়ে প্রিয় আমল।'
              : 'Performing prayer immediately after the Waqt starts is the most recommended and beloved deed to Allah.',
        ),
        _buildRuleCard(
          title: S.isBn ? '২. ওয়াসাত ওয়াক্ত (মধ্যবর্তী অংশ)' : '2. Middle Waqt (Wast)',
          desc: S.isBn 
              ? 'ওয়াক্তের মধ্যবর্তী সময়ে সালাত আদায় করা সাধারণ গ্রহণযোগ্য বিষয়।'
              : 'Praying during the middle part of the prayer window is general practice and acceptable.',
        ),
        _buildRuleCard(
          title: S.isBn ? '৩. আখির ওয়াক্ত (শেষ অংশ)' : '3. Late Waqt (Akhir)',
          desc: S.isBn 
              ? 'কোনো ওজর ছাড়া সালাতকে ওয়াক্ত শেষ হওয়ার ঠিক পূর্বে বিলম্বিত করা অপছন্দনীয় (মাকরূহ), তবে সালাত আদায় হয়ে যাবে।'
              : 'Delaying prayer to the absolute end of the window without a valid excuse is disliked (Makruh), though the prayer remains valid.',
        ),
      ],
    );
  }

  Widget _buildAppUsageTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(S.isBn ? 'ড্যাশবোর্ডে সালাত ট্র্যাকিং' : 'Salah Tracking on Dashboard'),
        _buildRuleCard(
          title: S.isBn ? '১ ট্যাপ (Single Tap)' : 'Single Tap',
          desc: S.isBn 
              ? 'সালাতের কার্ডে একবার ট্যাপ করলে তা স্বয়ংক্রিয়ভাবে আউয়াল ওয়াক্তের আদায়কৃত সালাত হিসেবে যুক্ত হবে।'
              : 'A single tap on a prayer card quickly logs it as offered in the Awwal (first) Waqt.',
        ),
        _buildRuleCard(
          title: S.isBn ? 'বামে সোয়াইপ (Swipe Left)' : 'Swipe Left',
          desc: S.isBn 
              ? 'কার্ডটি বামে সোয়াইপ করলে তা অলসতাবশত ছুটে গেছে (কাযা হিসেবে বকেয়া) হিসেবে চিহ্নিত হবে।'
              : 'Swiping a card to the left marks it as missed out of laziness (adds a pending Qaza debt).',
        ),
        _buildRuleCard(
          title: S.isBn ? 'ডানে সোয়াইপ (Swipe Right)' : 'Swipe Right',
          desc: S.isBn 
              ? 'যদি ভুলবশত কোনো লগ করা হয়ে থাকে, তবে কার্ডটি ডানে সোয়াইপ করে লগটি মুছে ফেলতে (Undo) পারবেন।'
              : 'Swiping a card to the right undoes/deletes the logged state (resets it back to unlogged).',
        ),
        _buildRuleCard(
          title: S.isBn ? 'চেপে ধরা (Long Press)' : 'Long Press',
          desc: S.isBn 
              ? 'কার্ডটিতে দীর্ঘক্ষণ চেপে ধরলে বিস্তারিত এডিটিং অপশন সহ একটি শীট আসবে। সেখানে জামায়াত, সফর, তসবীহ, এবং কোরআনের নোট যুক্ত করতে পারবেন।'
              : 'Long pressing a card opens the detailed log sheet to record Jamaah, Traveling, Tasbih, or Quran notes.',
        ),
        const SizedBox(height: 12),
        _buildSectionHeader(S.isBn ? 'বকেয়া কাযা আদায়' : 'Resolving Missed Prayers'),
        _buildRuleCard(
          title: S.isBn ? 'রেকর্ড ট্যাব' : 'Record Tab',
          desc: S.isBn 
              ? '\'রেকর্ড\' ট্যাবে আপনার সমস্ত বকেয়া কাযা নামাজের হিসাব থাকবে। আপনি যখনই কাযা সালাত আদায় করবেন, পাশে থাকা \'আদায় করুন\' বাটনে ক্লিক করে তা খতিয়ান থেকে খালাস করতে পারেন।'
              : 'The \'Record\' tab displays all your accumulated Qaza debts. Whenever you pray a Qaza, click \'Fulfill\' to clear it.',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5EEAD4), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildRuleCard({required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }
}
