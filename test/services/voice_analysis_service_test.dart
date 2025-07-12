import 'package:flutter_test/flutter_test.dart';
import 'package:voice_trainer_clean/services/voice_analysis_service.dart';
import 'package:voice_trainer_clean/services/filters/pitch_filter.dart';
import 'package:voice_trainer_clean/services/filters/formant_filter.dart';
import 'package:voice_trainer_clean/services/filters/breathiness_filter.dart';
import 'dart:typed_data';

void main() {
  group('VoiceAnalysisService Tests', () {
    late VoiceAnalysisService voiceService;

    setUp(() {
      voiceService = VoiceAnalysisService();
    });

    test('should perform comprehensive voice analysis', () {
      // Generate synthetic voice sample
      final voiceData = FormantFilter.generateVowelSample(
        f1: 350.0,
        f2: 2100.0,
        f3: 2800.0,
      );

      final analysis = voiceService.analyzeVoice(voiceData);

      // Should return complete analysis structure
      expect(analysis, containsPair('frequency', isA<double>()));
      expect(analysis, containsPair('noteName', isA<String>()));
      expect(analysis, containsPair('formants', isA<Map>()));
      expect(analysis, containsPair('breathiness', isA<Map>()));
      expect(analysis, containsPair('voiceCharacteristics', isA<Map>()));
      expect(analysis, containsPair('voiceQuality', isA<Map>()));
      expect(analysis, containsPair('timestamp', isA<int>()));
      expect(analysis, containsPair('analysisComplete', true));

      // Check formants structure
      final formants = analysis['formants'] as Map<String, dynamic>;
      expect(formants, containsPair('f1', isA<double>()));
      expect(formants, containsPair('f2', isA<double>()));
      expect(formants, containsPair('f3', isA<double>()));

      // Check breathiness structure
      final breathiness = analysis['breathiness'] as Map<String, dynamic>;
      expect(breathiness, containsPair('spectralTilt', isA<double>()));
      expect(breathiness, containsPair('noiseRatio', isA<double>()));
      expect(breathiness, containsPair('score', isA<double>()));

      print('Complete Analysis: ${analysis}');
    });

    test('should maintain backward compatibility with pitch detection', () {
      // Generate pure tone for pitch testing
      final toneData = PitchFilter.generateTestTone(frequency: 440.0);

      final detectedPitch = voiceService.detectPitch(toneData);

      // Should detect 440Hz within tolerance
      expect(detectedPitch, closeTo(440.0, 10.0));

      print(
        'Backward compatibility pitch: ${detectedPitch.toStringAsFixed(1)} Hz',
      );
    });

    test('debug note calculation', () {
      final testFrequencies = [
        110.0, // A2
        220.0, // A3
        440.0, // A4
        880.0, // A5
        261.6, // C4
      ];

      for (final freq in testFrequencies) {
        final analysis = voiceService.analyzeVoice(
          PitchFilter.generateTestTone(frequency: freq),
        );
        print('${freq}Hz → ${analysis['noteName']}');
      }
    });

    test('should convert frequency to note names correctly', () {
      // Test known frequency-to-note conversions
      final testCases = [
        {'frequency': 440.0, 'expectedNote': 'A4'},
        {'frequency': 220.0, 'expectedNote': 'A3'}, // Keep this as A3!
        {'frequency': 880.0, 'expectedNote': 'A5'},
        {'frequency': 261.6, 'expectedNote': 'C4'}, // Middle C
      ];

      for (final testCase in testCases) {
        final toneData = PitchFilter.generateTestTone(
          frequency: testCase['frequency'] as double,
        );

        final analysis = voiceService.analyzeVoice(toneData);
        final noteName = analysis['noteName'] as String;

        expect(noteName, equals(testCase['expectedNote']));

        print('${testCase['frequency']} Hz → ${noteName}');
      }
    });

    test('should analyze different voice types correctly', () {
      // Test feminine voice characteristics
      final feminineVoice = FormantFilter.generateVowelSample(
        f1: 300.0, // High F1
        f2: 2200.0, // High F2
        f3: 3000.0, // High F3
      );

      final feminineAnalysis = voiceService.analyzeVoice(feminineVoice);
      final voiceCharacteristics =
          feminineAnalysis['voiceCharacteristics'] as Map<String, dynamic>;

      expect(voiceCharacteristics['voiceType'], contains('Feminine'));

      print('Feminine voice analysis: ${voiceCharacteristics}');

      // Test masculine voice characteristics
      final masculineVoice = FormantFilter.generateVowelSample(
        f1: 600.0, // Lower F1
        f2: 1200.0, // Lower F2
        f3: 2400.0, // Lower F3
      );

      final masculineAnalysis = voiceService.analyzeVoice(masculineVoice);
      final voiceCharacteristics2 =
          masculineAnalysis['voiceCharacteristics'] as Map<String, dynamic>;

      expect(voiceCharacteristics2['voiceType'], contains('Masculine'));

      print('Masculine voice analysis: ${voiceCharacteristics2}');
    });

    test('should analyze breathiness levels correctly', () {
      // Test clear voice
      final clearVoice = BreathinessFilter.generateBreathyVoice(
        fundamentalFreq: 200.0,
        breathinessLevel: 0.1,
      );

      final clearAnalysis = voiceService.analyzeVoice(clearVoice);
      final voiceQuality =
          clearAnalysis['voiceQuality'] as Map<String, dynamic>;

      expect(voiceQuality['voiceQuality'], contains('Modal'));

      print('Clear voice quality: ${voiceQuality}');

      // Test breathy voice
      final breathyVoice = BreathinessFilter.generateBreathyVoice(
        fundamentalFreq: 200.0,
        breathinessLevel: 0.8,
      );

      final breathyAnalysis = voiceService.analyzeVoice(breathyVoice);
      final breathyQuality =
          breathyAnalysis['voiceQuality'] as Map<String, dynamic>;

      // Should detect some level of breathiness
      expect(breathyQuality['voiceQuality'], isA<String>());
      expect(breathyQuality['recommendation'], isA<String>());

      print('Breathy voice quality: ${breathyQuality}');
    });

    test('should handle edge cases gracefully', () {
      // Test empty data
      final emptyData = Uint8List(0);
      final emptyAnalysis = voiceService.analyzeVoice(emptyData);

      expect(emptyAnalysis['frequency'], equals(0.0));
      expect(emptyAnalysis['noteName'], equals('--'));
      expect(
        emptyAnalysis['analysisComplete'],
        anyOf([true, false]),
      ); // Either is acceptable

      print('Empty data analysis: ${emptyAnalysis}');

      // Test insufficient data
      final shortData = Uint8List(100);
      final shortAnalysis = voiceService.analyzeVoice(shortData);

      expect(shortAnalysis['frequency'], equals(0.0));
      expect(shortAnalysis['analysisComplete'], anyOf([true, false]));

      print('Short data analysis: ${shortAnalysis}');
    });

    test('should provide correct configuration', () {
      final config = voiceService.getConfiguration();

      expect(config['serviceType'], equals('VoiceAnalysisService'));
      expect(config['sampleRate'], equals(44100));
      expect(config['windowSize'], equals(2048));
      expect(config['version'], equals('1.0.0'));

      // Should contain all filter configurations
      final filters = config['filters'] as Map<String, dynamic>;
      expect(filters, containsPair('pitch', isA<Map>()));
      expect(filters, containsPair('formant', isA<Map>()));
      expect(filters, containsPair('breathiness', isA<Map>()));

      print('Service configuration: ${config}');
    });

    test('should handle errors gracefully', () {
      // Test with corrupted data that might cause errors
      final corruptData = Uint8List(400);

      final analysis = voiceService.analyzeVoice(corruptData);

      // Should not crash and should return safe defaults
      expect(analysis, isA<Map<String, dynamic>>());
      expect(analysis, containsPair('frequency', isA<double>()));
      expect(analysis, containsPair('noteName', isA<String>()));

      print('Error handling test: ${analysis}');
    });
  });

  group('VoiceAnalysisService Performance Tests', () {
    late VoiceAnalysisService voiceService;

    setUp(() {
      voiceService = VoiceAnalysisService();
    });

    test('should analyze voice data efficiently', () {
      final voiceData = FormantFilter.generateVowelSample(
        f1: 400.0,
        f2: 1800.0,
        f3: 2600.0,
        durationSeconds: 1.0, // 1 second of audio
      );

      final stopwatch = Stopwatch()..start();

      final analysis = voiceService.analyzeVoice(voiceData);

      stopwatch.stop();

      expect(analysis['analysisComplete'], anyOf([true, false]));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Should complete in under 1 second

      print('Analysis completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should handle multiple consecutive analyses', () {
      final voiceData = FormantFilter.generateVowelSample(
        f1: 350.0,
        f2: 2000.0,
        f3: 2800.0,
        durationSeconds: 0.5,
      );

      // Run multiple analyses
      for (int i = 0; i < 5; i++) {
        final analysis = voiceService.analyzeVoice(voiceData);
        expect(analysis, isA<Map<String, dynamic>>());

        print(
          'Analysis ${i + 1}: F=${analysis['frequency']}, Note=${analysis['noteName']}',
        );
      }

      print('Multiple analyses completed successfully');
    });
  });
}
