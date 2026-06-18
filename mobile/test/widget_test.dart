import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/prayer_provider.dart';
import 'package:mobile/providers/salah_time_provider.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Build our app with all required providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PrayerProvider()),
          ChangeNotifierProvider(create: (_) => SalahTimeProvider()),
        ],
        child: const IqamahApp(),
      ),
    );

    // Allow any async initialisation to settle
    await tester.pump();

    // Verify that the title "Establish Salah" is visible.
    expect(find.text('Establish Salah'), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);
  });
}
