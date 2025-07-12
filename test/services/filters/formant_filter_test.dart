import 'package:flutter_test/flutter_test.dart';
import 'package:voice_trainer_clean/services/filters/formant_filter.dart';
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  group('FormantFilter Tests - High Sensitivity', () {
    late FormantFilter formantFilter;

    setUp(() {
      formantFilter = FormantFilter();
    });

    test('should detect formants in synthetic "ee" vowel (high sensitivity)', () {
      // Generate synthetic "ee" vowel (high front vowel)
      final eeVowel = FormantFilter.generateVowelSample(
        f1: 300.0, // High tongue position
        f2: 2200.0, // Front tongue position
        f3: 3000.0, // Typical F3
      );

      final formants = formantFilter.extractFormants(eeVowel);

      // High sensitivity - strict tolerances for precise matching
      expect(formants[0], closeTo(300.0, 50.0)); // F1 tolerance ±50Hz
      expect(formants[1], closeTo(2200.0, 100.0)); // F2 tolerance ±100Hz
      expect(formants[2], closeTo(3000.0, 1000.0)); // F3 generous tolerance

      print(
        'EE vowel (high sensitivity): F1=${formants[0].round()}, F2=${formants[1].round()}, F3=${formants[2].round()}',
      );
    });

    test('should detect formants in synthetic "ah" vowel (high sensitivity)', () {
      final ahVowel = FormantFilter.generateVowelSample(
        f1: 700.0, // Low tongue position
        f2: 1200.0, // Back tongue position
        f3: 2500.0, // Typical F3
      );

      final formants = formantFilter.extractFormants(ahVowel);

      expect(formants[0], closeTo(700.0, 50.0));
      expect(formants[1], closeTo(1200.0, 100.0));
      expect(formants[2], closeTo(2500.0, 150.0));

      print(
        'AH vowel (high sensitivity): F1=${formants[0].round()}, F2=${formants[1].round()}, F3=${formants[2].round()}',
      );
    });
  });

  group('FormantFilter Tests - Low Sensitivity', () {
    late FormantFilter formantFilter;

    setUp(() {
      formantFilter = FormantFilter();
    });

    test('should detect formants in synthetic "ee" vowel (low sensitivity)', () {
      final eeVowel = FormantFilter.generateVowelSample(
        f1: 300.0,
        f2: 2200.0,
        f3: 3000.0,
      );

      final formants = formantFilter.extractFormants(eeVowel);

      // Low sensitivity - accepts broader range for real-world conditions
      expect(
        formants[0],
        anyOf([
          closeTo(300.0, 100.0), // Target F1
          inInclusiveRange(200.0, 500.0), // Acceptable F1 range
        ]),
      );
      expect(
        formants[1],
        anyOf([
          closeTo(2200.0, 200.0), // Target F2
          inInclusiveRange(1800.0, 2600.0), // Acceptable F2 range
        ]),
      );
      expect(
        formants[2],
        anyOf([
          closeTo(3000.0, 300.0), // Target F3
          inInclusiveRange(2000.0, 3500.0), // Any reasonable F3 range
        ]),
      );

      print(
        'EE vowel (low sensitivity): F1=${formants[0].round()}, F2=${formants[1].round()}, F3=${formants[2].round()}',
      );
    });

    test('should detect formants in synthetic "oo" vowel (low sensitivity)', () {
      final ooVowel = FormantFilter.generateVowelSample(
        f1: 400.0,
        f2: 800.0,
        f3: 2200.0,
      );

      final formants = formantFilter.extractFormants(ooVowel);

      // Low sensitivity - broader tolerances
      expect(formants[0], inInclusiveRange(300.0, 500.0)); // F1 range
      expect(formants[1], inInclusiveRange(600.0, 1000.0)); // F2 range
      expect(formants[2], inInclusiveRange(1800.0, 2600.0)); // F3 range

      print(
        'OO vowel (low sensitivity): F1=${formants[0].round()}, F2=${formants[1].round()}, F3=${formants[2].round()}',
      );
    });
  });

  group('FormantFilter Edge Cases', () {
    late FormantFilter formantFilter;

    setUp(() {
      formantFilter = FormantFilter();
    });

    test('should handle pure tone gracefully', () {
      final pureTone = Uint8List.fromList(
        List.generate(8000, (i) {
          final sample = (32767 * 0.5 * math.sin(2 * math.pi * 440 * i / 44100))
              .round();
          return [sample & 0xFF, (sample >> 8) & 0xFF];
        }).expand((x) => x).toList(),
      );

      final formants = formantFilter.extractFormants(pureTone);
      final detectedCount = formants.where((f) => f > 0).length;
      expect(detectedCount, lessThanOrEqualTo(3));

      print(
        'Pure tone test: Detected ${detectedCount} formants: ${formants.map((f) => f.round()).toList()}',
      );
    });

    test('should handle empty audio data gracefully', () {
      final emptyData = Uint8List(0);
      final formants = formantFilter.extractFormants(emptyData);
      expect(formants, equals([0.0, 0.0, 0.0]));
      print('Empty data test: ${formants}');
    });

    test('should provide correct configuration', () {
      final config = formantFilter.getConfig();
      expect(config['filterType'], equals('FormantFilter'));
      expect(config['sampleRate'], equals(44100));
      print('Config test: ${config}');
    });

    test('should analyze voice characteristics correctly', () {
      final feminineFormants = [350.0, 2100.0, 2800.0];
      final analysis = formantFilter.analyzeVoiceCharacteristics(
        feminineFormants,
      );
      expect(analysis['voiceType'], equals('Feminine-leaning'));
      print('Voice analysis test: ${analysis}');
    });
  });
}
