// This is a basic Flutter widget test for the Voice Trainer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_trainer_clean/main.dart';

void main() {
  testWidgets('Voice Trainer app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceTrainerApp());

    // Verify that our app title appears
    expect(find.text('🎤 Voice Trainer MTF Pro'), findsOneWidget);

    // Verify that the analysis cards are present
    expect(find.text('🎵 Pitch Analysis'), findsOneWidget);
    expect(find.text('📊 Formant Analysis'), findsOneWidget);
    expect(find.text('🗣️ Voice Characteristics'), findsOneWidget);
    expect(find.text('💨 Voice Quality'), findsOneWidget);

    // Verify that the start button exists
    expect(find.text('▶️ Start Analysis'), findsOneWidget);

    // Verify the microphone icon exists
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('Analysis button toggles correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceTrainerApp());

    // Scroll to make sure button is visible
    await tester.scrollUntilVisible(find.text('▶️ Start Analysis'), 500.0);

    // Tap the analysis button
    await tester.tap(find.text('▶️ Start Analysis'));
    await tester.pump();

    // Verify button text changed
    expect(find.text('⏹️ Stop Analysis'), findsOneWidget);
    expect(find.text('▶️ Start Analysis'), findsNothing);
  });
}
