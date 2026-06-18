import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui';
import 'models/prayer_log.dart';
import 'models/qaza_log.dart';
import 'providers/prayer_provider.dart';
import 'providers/salah_time_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()..fetchDailyLogs()..fetchPendingQazas()),
        ChangeNotifierProvider(create: (_) => SalahTimeProvider()),
      ],
      child: const IqamahApp(),
    ),
  );
}

class IqamahApp extends StatelessWidget {
  const IqamahApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iqamah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030A09),
        primaryColor: const Color(0xFFC5A059),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC5A059),
          secondary: Color(0xFF104035),
          surface: Color(0xFF0A1F1B),
          background: Color(0xFF030A09),
        ),
        // Primary Latin font stays Serif; NotoSansBengali handles all Bengali Unicode automatically
        fontFamily: 'Serif',
        textTheme: const TextTheme().apply(
          fontFamilyFallback: ['NotoSansBengali'],
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

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
    const SalahTimeTab(),
    const AnalyticsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A1F1B),
        selectedItemColor: const Color(0xFFC5A059),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Qaza'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Salah Time'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Backup'),
        ],
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
    final days = List.generate(7, (index) => DateTime.now().subtract(Duration(days: 3 - index)));

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
                  const Text(
                    'Establish Salah',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'إقامة • local dashboard',
                    style: TextStyle(fontSize: 12, color: const Color(0xFFC5A059).withOpacity(0.8)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Color(0xFFC5A059)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    provider.changeSelectedDate(picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal calendar
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = DateFormat('yyyy-MM-dd').format(day) == provider.formattedSelectedDate;
                return GestureDetector(
                  onTap: () => provider.changeSelectedDate(day),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF0A1F1B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFC5A059) : Colors.white12,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 2),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.black87 : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(day),
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
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

class PrayerLogCard extends StatelessWidget {
  final PrayerName prayerName;
  final PrayerLog? log;

  static const Map<PrayerName, String> arabicNames = {
    PrayerName.Fajr: 'الفجر',
    PrayerName.Dhuhr: 'الظهر',
    PrayerName.Asr: 'العصر',
    PrayerName.Maghrib: 'المغرب',
    PrayerName.Isha: 'العشاء',
  };

  const PrayerLogCard({Key? key, required this.prayerName, this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasLog = log != null;
    final isOffered = log?.isOffered ?? false;
    final isPeriod = log?.missedReason == MissedReason.ExcusedImpurity;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOffered
              ? Colors.green.withOpacity(0.3)
              : isPeriod
                  ? const Color(0xFFC5A059).withOpacity(0.3)
                  : hasLog
                      ? Colors.red.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              prayerName.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              arabicNames[prayerName]!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC5A059), fontFamily: 'Courier'),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // Status text
            if (!hasLog)
              const Text('Not Logged', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white38))
            else if (isOffered)
              Text(
                'Offered (${log!.waqtStatus!.name.replaceAll('AlWaqt', '').replaceAll('Wast', 'Wast ').replaceAll('Akhir', 'Akhir ')})',
                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
              )
            else if (isPeriod)
              const Text(
                'Period (Excused)',
                style: TextStyle(fontSize: 12, color: Color(0xFFC5A059), fontWeight: FontWeight.w600),
              )
            else
              Text(
                'Missed (${log!.missedReason!.name.replaceAll('Excused', '').replaceAll('Unexcused', '')})',
                style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
              ),

            // Metadata badges
            if (hasLog) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (log!.isTraveling)
                    _buildBadge('🛫 Traveling', Colors.blue.shade900, Colors.blue.shade300),
                  if (log!.isJamaah)
                    _buildBadge('👥 Jamaah', const Color(0xFF002B16), Colors.green.shade300),
                  if (log!.isJummah)
                    _buildBadge('🕌 Jummah', const Color(0xFF002D24), Colors.teal.shade300),
                  if (log!.isHome)
                    _buildBadge('🏠 Home', const Color(0xFF332200), Colors.amber.shade300),
                  if (log!.hasTasbih)
                    _buildBadge('📿 Tasbih', const Color(0xFF2E0014), Colors.pink.shade300),
                  if (log!.quranNotes != null && log!.quranNotes!.trim().isNotEmpty)
                    _buildBadge('📖 Quran', const Color(0xFF1B002B), Colors.purple.shade300),
                ],
              ),
            ]
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF102E29),
            foregroundColor: const Color(0xFFC5A059),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF0A1F1B),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => LoggingBottomSheet(prayerName: prayerName, existing: log),
            );
          },
          child: Text(hasLog ? 'Edit' : 'Log'),
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
  bool? _isFemale; // null = not set, true = female, false = male
  final TextEditingController _quranNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load gender preference
    SharedPreferences.getInstance().then((prefs) {
      final g = prefs.getString('iqamah_gender');
      if (mounted) setState(() => _isFemale = g == 'female' ? true : g == 'male' ? false : null);
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

  Future<void> _saveGender(bool female) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iqamah_gender', female ? 'female' : 'male');
    if (mounted) setState(() => _isFemale = female);
  }

  @override
  void dispose() {
    _quranNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Log ${widget.prayerName.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Tab Switcher
          Row(
            children: [
              _buildTabButton('Offered', 'offered'),
              const SizedBox(width: 8),
              _buildTabButton('Missed', 'missed'),
              // Hayd / Nifas tab: only for female users
              if (_isFemale == true) ...[
                const SizedBox(width: 8),
                _buildTabButton('Hayd / Nifas', 'period'),
              ],
            ],
          ),

          // Gender not set banner
          if (_isFemale == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender Setting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 4),
                  const Text('Hayd / Nifas option is only shown for female users.', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _saveGender(false),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                        child: const Text('Male', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _saveGender(true),
                        style: OutlinedButton.styleFrom(foregroundColor: Color(0xFFC5A059), side: const BorderSide(color: Color(0xFFC5A059)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                        child: const Text('Female', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          if (_logType == 'offered') ...[
            // Waqt choice
            const Text('Waqt Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              children: WaqtStatus.values.map((status) {
                final isSelected = _waqtStatus == status;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _waqtStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF102E29),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        status.name.replaceAll('AlWaqt', ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Modifiers
            SwitchListTile(
              title: const Text('Congregation (Jamaah)', style: TextStyle(fontSize: 13)),
              value: _isJamaah,
              activeColor: const Color(0xFFC5A059),
              onChanged: _isTraveling ? null : (v) => setState(() => _isJamaah = v),
            ),
            SwitchListTile(
              title: const Text('Prayed at Home', style: TextStyle(fontSize: 13)),
              value: _isHome,
              activeColor: const Color(0xFFC5A059),
              onChanged: (v) => setState(() => _isHome = v),
            ),
            SwitchListTile(
              title: const Text('Completed Tasbih', style: TextStyle(fontSize: 13)),
              value: _hasTasbih,
              activeColor: const Color(0xFFC5A059),
              onChanged: (v) => setState(() => _hasTasbih = v),
            ),
            if (widget.prayerName == PrayerName.Dhuhr)
              SwitchListTile(
                title: const Text('Friday Jummah', style: TextStyle(fontSize: 13)),
                value: _isJummah,
                activeColor: const Color(0xFFC5A059),
                onChanged: (v) => setState(() => _isJummah = v),
              ),
            SwitchListTile(
              title: const Text('Traveling (Musafir)', style: TextStyle(fontSize: 13)),
              value: _isTraveling,
              activeColor: const Color(0xFFC5A059),
              onChanged: (v) {
                setState(() {
                  _isTraveling = v;
                  if (v) _isJamaah = false;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quranNotesController,
              decoration: InputDecoration(
                labelText: 'Quran Reading Notes (Ayat, Surah)',
                labelStyle: const TextStyle(fontSize: 12, color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFC5A059)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ] else if (_logType == 'missed') ...[
            const Text('Reason Missed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF102E29),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<MissedReason>(
                value: _missedReason,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF0A1F1B),
                items: MissedReason.values
                    .where((reason) => reason != MissedReason.ExcusedImpurity)
                    .map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.name.replaceAll('Excused', '[Excused] ').replaceAll('Unexcused', '[Unexcused] '),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _missedReason = val);
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Traveling (Musafir)', style: TextStyle(fontSize: 13)),
              value: _isTraveling,
              activeColor: const Color(0xFFC5A059),
              onChanged: (v) => setState(() => _isTraveling = v),
            ),
          ] else ...[
            // Hayd / Nifas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A059).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.1)),
              ),
              child: Column(
                children: const [
                  Text('🌸', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'Period / Impurity (Hayd)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC5A059)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'During menstruation (Hayd) or post-natal bleeding (Nifas), prayer obligation is fully lifted. No Qaza required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '⚠️ Janabah (requiring Ghusl) does NOT exempt from prayer — prayer remains obligatory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.amber, height: 1.4),
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
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await context.read<PrayerProvider>().logPrayer(
                          prayerName: widget.prayerName,
                          isOffered: _logType == 'offered',
                          waqtStatus: _logType == 'offered' ? _waqtStatus : null,
                          missedReason: _logType == 'period'
                              ? MissedReason.ExcusedImpurity
                              : _logType == 'missed'
                                  ? _missedReason
                                  : null,
                          isJamaah: _logType == 'offered' ? _isJamaah : false,
                          isHome: _logType == 'offered' ? _isHome : false,
                          hasTasbih: _logType == 'offered' ? _hasTasbih : false,
                          isJummah: _logType == 'offered' ? _isJummah : false,
                          isTraveling: _isTraveling,
                          quranNotes: _logType == 'offered' ? _quranNotesController.text : null,
                        );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                },
                child: const Text('Save Log', style: TextStyle(fontWeight: FontWeight.bold)),
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
            color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF0A1F1B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFC5A059) : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black : Colors.white70,
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
          const Text(
            'Qaza Obligations',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Fulfill your missed prayers debt',
            style: TextStyle(fontSize: 12, color: const Color(0xFFC5A059).withOpacity(0.8)),
          ),
          const SizedBox(height: 20),
          // Simple card summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1F1B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Pending', '${provider.pendingQazas.length}', Colors.red),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildSummaryStat('Discharged', 'Auto Calc', const Color(0xFFC5A059)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
                : provider.pendingQazas.isEmpty
                    ? const Center(
                        child: Text(
                          'Alhamdulillah! No pending Qaza logs.',
                          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.pendingQazas.length,
                        itemBuilder: (context, index) {
                          final qaza = provider.pendingQazas[index];
                          return Card(
                            color: const Color(0xFF0A1F1B),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: Text(
                                qaza.prayerName.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                'Missed on ${qaza.originalPrayerDate}',
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF102E29),
                                  foregroundColor: const Color(0xFFC5A059),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => provider.fulfillQaza(qaza.id),
                                child: const Text('Fulfill'),
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
                  const Text(
                    'Analytics',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Salah performance & habits',
                    style: TextStyle(fontSize: 12, color: const Color(0xFFC5A059).withOpacity(0.8)),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: _rangeDays,
                dropdownColor: const Color(0xFF0A1F1B),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 Days', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 30, child: Text('30 Days', style: TextStyle(fontSize: 12))),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
                : ListView(
                    children: [
                      // Offerd Percentage Circle / Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F1B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Offered Ratio',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(stats['offeredPercentage'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Offered ${stats['totalOffered']} out of ${stats['totalObligated']} obligated prayers',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Punctuality Card
                      _buildHeader('Punctuality Split'),
                      _buildDetailRow('First (Awwal)', '${stats['punctuality']['awwalAlWaqtCount']}', Colors.green),
                      _buildDetailRow('Middle (Wast)', '${stats['punctuality']['wastAlWaqtCount']}', const Color(0xFFC5A059)),
                      _buildDetailRow('Late (Akhir)', '${stats['punctuality']['akhirAlWaqtCount']}', Colors.amber),
                      const SizedBox(height: 20),
                      // Excuses Split
                      _buildHeader('Missed Reasons'),
                      _buildDetailRow('Sleep', '${stats['missedReasons']['excusedSleepCount']}', Colors.white70),
                      _buildDetailRow('Forgetfulness', '${stats['missedReasons']['excusedForgetfulnessCount']}', Colors.white70),
                      _buildDetailRow('Impurity (Excused)', '${stats['missedReasons']['excusedImpurityCount']}', Colors.pink.shade300),
                      _buildDetailRow('Laziness', '${stats['missedReasons']['unexcusedLazinessCount']}', Colors.red),
                      _buildDetailRow('Distraction', '${stats['missedReasons']['unexcusedDistractionCount']}', Colors.red),
                      _buildDetailRow('Situational', '${stats['missedReasons']['unexcusedSituationalCount']}', Colors.red),
                      const SizedBox(height: 20),
                      // Qaza Card
                      _buildHeader('Qaza summary'),
                      _buildDetailRow('Pending', '${stats['qazaSummary']['totalPending']}', Colors.red),
                      _buildDetailRow('Fulfilled', '${stats['qazaSummary']['totalFulfilled']}', Colors.green),
                      _buildDetailRow('Resolution Time', '${(stats['qazaSummary']['averageResolutionTimeHours'] as double).toStringAsFixed(1)} hours', Colors.white),
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
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC5A059))),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF0A1F1B), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ── Backup Settings Tab ──────────────────────────────────────────────────────
class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup & Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Import, export, and secure your local data',
            style: TextStyle(fontSize: 12, color: const Color(0xFFC5A059).withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFF0A1F1B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: Color(0xFFC5A059)),
                  title: const Text('Export Backup File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save your database records to a JSON file that you can share or download.', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  onTap: () => provider.exportBackup(),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: Color(0xFFC5A059)),
                  title: const Text('Import Backup File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Restore all records from a previously exported Iqamah JSON backup file.', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  onTap: () async {
                    final success = await provider.importBackup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Backup restored successfully!'
                              : 'Failed to restore backup. Please make sure the JSON file is valid.',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                    'Uninstall Notice: All data is saved strictly on this device. If you uninstall this app, all logged prayers will be permanently deleted. Export backups regularly to preserve your history.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              'Iqamah Mobile v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.white24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class SalahTimeTab extends StatefulWidget {
  const SalahTimeTab({Key? key}) : super(key: key);

  @override
  State<SalahTimeTab> createState() => _SalahTimeTabState();
}

class _SalahTimeTabState extends State<SalahTimeTab> {
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
      {'name': 'Fajr', 'start': schedule.fajr.millisecondsSinceEpoch},
      {'name': 'Dhuhr', 'start': schedule.dhuhr.millisecondsSinceEpoch},
      {'name': 'Asr', 'start': schedule.asr.millisecondsSinceEpoch},
      {'name': 'Maghrib', 'start': schedule.maghrib.millisecondsSinceEpoch},
      {'name': 'Isha', 'start': schedule.isha.millisecondsSinceEpoch},
    ];

    final next = prayers.firstWhere((p) => (p['start'] as int) > nowMs, orElse: () => <String, Object>{});
    String prefix = '';
    int diff = 0;

    if (next.isNotEmpty) {
      prefix = next['name'] as String;
      diff = (next['start'] as int) - nowMs;
    } else {
      prefix = 'Fajr (Tomorrow)';
      final tomorrowFajr = schedule.fajr.add(const Duration(days: 1)).millisecondsSinceEpoch;
      diff = tomorrowFajr - nowMs;
    }

    final secs = diff ~/ 1000;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;

    final pad = (int n) => n.toString().padLeft(2, '0');
    return 'Next: $prefix in ${pad(h)}:${pad(m)}:${pad(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalahTimeProvider>();
    final schedule = provider.schedule;

    // Check active forbidden zone
    ForbiddenZone? activeZone;
    if (schedule != null) {
      for (final zone in schedule.forbiddenZones) {
        if (_now.isAfter(zone.start) && _now.isBefore(zone.end)) {
          activeZone = zone;
          break;
        }
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salah Schedule',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFFC5A059)),
                          const SizedBox(width: 4),
                          Text(
                            provider.locationName,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.detectLocationAndCalculate();
                    },
                    icon: const Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                    label: const Text('Detect', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1F1B),
                      foregroundColor: const Color(0xFFC5A059),
                      side: const BorderSide(color: Color(0xFFC5A059), width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Forbidden Zone Warning Banner
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
                            const Text(
                              'Forbidden Salah Period Active',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeZone.label}: ${activeZone.fmt}',
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
                        child: const Text(
                          'FORBIDDEN',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Clock and Countdown Timer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1F1B),
                  border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.1), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Time',
                          style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.jms().format(_now),
                          style: const TextStyle(fontSize: 20, fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    if (schedule != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A059).withOpacity(0.08),
                          border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.2), width: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getCountdownText(schedule),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
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
                    child: CircularProgressIndicator(color: Color(0xFFC5A059)),
                  ),
                )
              else if (schedule == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text('Click Detect to load Salah times.', style: TextStyle(color: Colors.white30)),
                  ),
                )
              else ...[
                // Prayer Cards
                ...schedule.allPrayers.map((prayer) {
                  final active = prayer.isActive;
                  final showForbiddenBadge = active && activeZone != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF1B6B3A) : const Color(0xFF0A1F1B).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? const Color(0xFFC5A059).withOpacity(0.5) : const Color(0xFFC5A059).withOpacity(0.05),
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
                                prayer.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: active ? Colors.white : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${prayer.startFmt} – ${prayer.endFmt}',
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
                            child: const Text(
                              '⛔ FORBIDDEN',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5A059).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Color(0xFFC5A059), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),

                // Forbidden Times Panel
                const Text(
                  'Forbidden (Makruh) Prayer Windows',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
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
                            : const Color(0xFF0A1F1B).withOpacity(0.2),
                        border: Border.all(
                          color: isZoneActive
                              ? Colors.orange.shade500.withOpacity(0.3)
                              : const Color(0xFFC5A059).withOpacity(0.05),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            zone.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isZoneActive ? Colors.orangeAccent : Colors.white70,
                            ),
                          ),
                          Text(
                            zone.fmt,
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
    );
  }
}
