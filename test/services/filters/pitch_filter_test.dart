import 'package:flutter_test/flutter_test.dart';
import 'package:voice_trainer_clean/services/filters/pitch_filter.dart';
import 'dart:typed_data';

void main() {
  group('PitchFilter Tests', () {
    late PitchFilter pitchFilter;

    setUp(() {
      pitchFilter = PitchFilter();
    });

    test('should detect 440Hz test tone accurately', () {
      // Generate pure 440Hz tone (A4)
      final testTone = PitchFilter.generateTestTone(frequency: 440.0);

      // Extract pitch
      final detectedPitch = pitchFilter.extractPitch(testTone);

      // Should be within 5Hz tolerance
      expect(detectedPitch, closeTo(440.0, 5.0));
      print(
        '440Hz test: Expected 440.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should detect 220Hz test tone accurately', () {
      // Generate 220Hz tone (A3)
      final testTone = PitchFilter.generateTestTone(frequency: 220.0);

      final detectedPitch = pitchFilter.extractPitch(testTone);

      expect(detectedPitch, closeTo(220.0, 5.0));
      print(
        '220Hz test: Expected 220.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should detect 330Hz test tone accurately', () {
      // Generate 330Hz tone (typical female voice range)
      final testTone = PitchFilter.generateTestTone(frequency: 330.0);

      final detectedPitch = pitchFilter.extractPitch(testTone);

      expect(detectedPitch, closeTo(330.0, 10.0));
      print(
        '330Hz test: Expected 330.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should return 0 for frequencies outside range', () {
      // Generate very high frequency (outside vocal range)
      final testTone = PitchFilter.generateTestTone(frequency: 2000.0);

      final detectedPitch = pitchFilter.extractPitch(testTone);

      expect(detectedPitch, equals(0.0));
      print(
        'Out-of-range test: Expected 0.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should handle empty audio data gracefully', () {
      final emptyData = Uint8List(0);

      final detectedPitch = pitchFilter.extractPitch(emptyData);

      expect(detectedPitch, equals(0.0));
      print(
        'Empty data test: Expected 0.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should handle too little data gracefully', () {
      // Generate very short audio sample
      final shortData = Uint8List(100); // Way too small

      final detectedPitch = pitchFilter.extractPitch(shortData);

      expect(detectedPitch, equals(0.0));
      print(
        'Short data test: Expected 0.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });

    test('should provide correct configuration', () {
      final config = pitchFilter.getConfig();

      expect(config['filterType'], equals('PitchFilter'));
      expect(config['sampleRate'], equals(44100));
      expect(config['windowSize'], equals(2048));
      expect(config['algorithm'], equals('Autocorrelation'));
      expect(config['minFrequency'], equals(80.0));
      expect(config['maxFrequency'], equals(1000.0));

      print('Config test: ${config}');
    });

    test('should generate valid test tones', () {
      final testTone = PitchFilter.generateTestTone(
        frequency: 440.0,
        durationSeconds: 0.5,
      );

      // Should generate reasonable amount of data
      expect(testTone.length, greaterThan(40000)); // ~0.5s at 44100Hz * 2 bytes
      expect(testTone.length, lessThan(50000));

      print('Test tone generation: ${testTone.length} bytes generated');
    });
  });

  group('PitchFilter Edge Cases', () {
    late PitchFilter pitchFilter;

    setUp(() {
      pitchFilter = PitchFilter();
    });

    test('should handle noisy audio gracefully', () {
      // Generate random noise
      final random = List.generate(8000, (i) => (i % 256));
      final noisyData = Uint8List.fromList(random);

      final detectedPitch = pitchFilter.extractPitch(noisyData);

      // Should either detect nothing or detect something reasonable
      expect(
        detectedPitch,
        anyOf([equals(0.0), inInclusiveRange(80.0, 1000.0)]),
      );
      print('Noise test: Got ${detectedPitch.toStringAsFixed(1)} Hz');
    });

    test('should work with different sample rates', () {
      final customFilter = PitchFilter(sampleRate: 22050, windowSize: 1024);
      final testTone = PitchFilter.generateTestTone(
        frequency: 440.0,
        sampleRate: 22050,
      );

      final detectedPitch = customFilter.extractPitch(testTone);

      expect(detectedPitch, closeTo(440.0, 10.0));
      print(
        'Custom sample rate test: Expected 440.0, Got ${detectedPitch.toStringAsFixed(1)}',
      );
    });
  });
}
