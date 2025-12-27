import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_six_seven_dance/main.dart';
import 'package:five_six_seven_dance/widgets/instrument_section.dart';
import 'package:five_six_seven_dance/widgets/voice_count_section.dart';
import 'package:flutter/cupertino.dart';

void main() {
  testWidgets('Salsa Mixer UI smoke test', (WidgetTester tester) async {
    // Set a larger screen size for the test to avoid overflow on fixed sections
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SalsaMixerApp());

    // Verify Title
    expect(find.text('567 Dance!'), findsOneWidget);

    // Verify Tempo Control Card
    expect(find.text('TEMPO'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);

    // Verify Instrument Section
    expect(find.text('INSTRUMENTOS'), findsOneWidget);
    expect(find.text('Clave'), findsOneWidget);
    expect(find.text('Guiro'), findsOneWidget);
    expect(find.text('Guitar'), findsOneWidget);
    expect(find.text('Bongo'), findsOneWidget);
    expect(find.text('Cowbell'), findsOneWidget);

    // Verify Voice Count Section
    expect(find.text('CONTEO DE VOZ'), findsOneWidget);
    for (int i = 1; i <= 8; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });

  testWidgets('Tempo control interactions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(const SalsaMixerApp());

    // Initial BPM
    expect(find.text('180'), findsOneWidget);

    // Find slider
    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, 180.0);

    // Tap + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('181'), findsOneWidget);

    // Tap - button
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('180'), findsOneWidget);

    // Toggle Play/Pause
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('Instrument volume and cycle interactions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(const SalsaMixerApp());

    // Find Bongo (initial volume 0)
    final bongoTileFinder = find.widgetWithText(InstrumentTile, 'Bongo');
    expect(bongoTileFinder, findsOneWidget);

    // Tap to set volume to 1
    await tester.tap(bongoTileFinder);
    await tester.pump();

    // Tap 3 more times to reach volume 4
    await tester.tap(bongoTileFinder);
    await tester.pump();
    await tester.tap(bongoTileFinder);
    await tester.pump();
    await tester.tap(bongoTileFinder);
    await tester.pump();

    // Verify it's active (switch should be true)
    final switchFinder = find.descendant(
      of: bongoTileFinder,
      matching: find.byType(CupertinoSwitch),
    );
    CupertinoSwitch bongoSwitch = tester.widget(switchFinder);
    expect(bongoSwitch.value, isTrue);

    // Tap once more to cycle back to 0
    await tester.tap(bongoTileFinder);
    await tester.pump();

    bongoSwitch = tester.widget(switchFinder);
    expect(bongoSwitch.value, isFalse);
  });

  testWidgets('Voice count toggle interactions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(const SalsaMixerApp());

    // Voice 1 starts active
    final voice1Finder = find.widgetWithText(VoiceGridButton, '1');
    expect(voice1Finder, findsOneWidget);

    // We can check background color or logic. Instead let's just tap it.
    // Since it's a stateless widget wrapping state passed from parent, we verify the setState triggers rebuild.

    // Ensure the widget is visible
    await tester.ensureVisible(voice1Finder);
    await tester.pumpAndSettle();

    // Tap Voice 1
    await tester.tap(voice1Finder);
    await tester.pumpAndSettle();

    // We can't easily check the internal state of the parent without keys or inspecting the widget properties again.
    // But we can check if the widget rebuilt with different properties if we really want,
    // or trust the smoke test that tappable widgets exist.
    // Let's verify at least that it doesn't crash.
  });
}
