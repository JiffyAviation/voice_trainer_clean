// This is a basic Flutter widget test for the Voice Trainer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/services/main.dart';

void main() {
  testWidgets('Voice Trainer app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(VoiceTrainerApp());

    // Verify that our app title appears
    expect(find.text('Voice Trainer Clean - Working!'), findsOneWidget);

    // Verify that the frequency display starts at 0.0
    expect(find.text('0.0 Hz'), findsOneWidget);

    // Verify that the start button exists
    expect(find.text('Start Detection'), findsOneWidget);

    // Verify the microphone icon exists
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('Detection button toggles correctly', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(VoiceTrainerApp());

    // Tap the detection button
    await tester.tap(find.text('Start Detection'));
    await tester.pump();

    // Verify button text changed
    expect(find.text('Stop Detection'), findsOneWidget);
    expect(find.text('Start Detection'), findsNothing);
  });
}
