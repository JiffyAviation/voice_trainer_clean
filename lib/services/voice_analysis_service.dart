import 'dart:async';
import 'dart:typed_data';
import 'filters/pitch_filter.dart';
import 'filters/formant_filter.dart';
import 'filters/breathiness_filter.dart';
import 'dart:math' as math;

/// Orchestrates all voice analysis filters - unified API
class VoiceAnalysisService {
  // Individual filter instances
  final PitchFilter _pitchFilter;
  final FormantFilter _formantFilter;
  final BreathinessFilter _breathinessFilter;

  // Configuration
  final int sampleRate;
  final int windowSize;

  VoiceAnalysisService({this.sampleRate = 44100, this.windowSize = 2048})
    : _pitchFilter = PitchFilter(
        sampleRate: sampleRate,
        windowSize: windowSize,
      ),
      _formantFilter = FormantFilter(
        sampleRate: sampleRate,
        windowSize: windowSize,
      ),
      _breathinessFilter = BreathinessFilter(
        sampleRate: sampleRate,
        windowSize: windowSize,
      );

  /// Comprehensive voice analysis - returns all metrics
  Map<String, dynamic> analyzeVoice(Uint8List audioData) {
    try {
      // Run all filters on the same audio data
      final pitch = _pitchFilter.extractPitch(audioData);
      final formants = _formantFilter.extractFormants(audioData);
      final breathiness = _breathinessFilter.extractBreathiness(audioData);

      // Convert pitch to note name (like old service)
      final noteName = _calculateNoteName(pitch);

      // Get voice characteristics analysis
      final voiceCharacteristics = _formantFilter.analyzeVoiceCharacteristics(
        formants,
      );
      final voiceQuality = _breathinessFilter.analyzeVoiceQuality(breathiness);

      return {
        // Basic pitch info (compatible with old service)
        'frequency': pitch,
        'noteName': noteName,

        // Formant analysis
        'formants': {'f1': formants[0], 'f2': formants[1], 'f3': formants[2]},

        // Breathiness analysis
        'breathiness': {
          'spectralTilt': breathiness[0],
          'noiseRatio': breathiness[1],
          'score': breathiness[2],
        },

        // Voice analysis
        'voiceCharacteristics': voiceCharacteristics,
        'voiceQuality': voiceQuality,

        // Metadata
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'analysisComplete': true,
      };
    } catch (e) {
      // Graceful failure - return safe defaults
      return {
        'frequency': 0.0,
        'noteName': '--',
        'formants': {'f1': 0.0, 'f2': 0.0, 'f3': 0.0},
        'breathiness': {'spectralTilt': 0.0, 'noiseRatio': 0.0, 'score': 0.0},
        'voiceCharacteristics': {'voiceType': 'Unknown'},
        'voiceQuality': {'voiceQuality': 'Unknown'},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'analysisComplete': false,
        'error': e.toString(),
      };
    }
  }

  /// Simple pitch detection (backward compatibility with old service)
  double detectPitch(Uint8List audioData) {
    return _pitchFilter.extractPitch(audioData);
  }

  /// Convert frequency to note name (simple, correct algorithm)
  String _calculateNoteName(double frequency) {
    if (frequency < 80 || frequency > 2000) return '--';

    final noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    // Use C0 as reference (16.35 Hz)
    final c0 = 16.351597831287414;

    // Calculate the note number from C0 using natural log
    final noteNumber = (12 * (math.log(frequency / c0) / math.log(2))).round();

    // Get note name and octave
    final noteIndex = noteNumber % 12;
    final octave = noteNumber ~/ 12;

    // Handle edge cases
    if (octave < 0 || octave > 9) return '--';

    return '${noteNames[noteIndex]}$octave';
  }

  /// Get configuration info for all filters
  Map<String, dynamic> getConfiguration() {
    return {
      'serviceType': 'VoiceAnalysisService',
      'sampleRate': sampleRate,
      'windowSize': windowSize,
      'filters': {
        'pitch': _pitchFilter.getConfig(),
        'formant': _formantFilter.getConfig(),
        'breathiness': _breathinessFilter.getConfig(),
      },
      'version': '1.0.0',
    };
  }
}
