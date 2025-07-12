import 'dart:typed_data';
import 'dart:math' as math;

/// Isolated pitch detection filter - single responsibility only
class PitchFilter {
  final int sampleRate;
  final int windowSize;

  // Configuration
  static const double minFrequency = 80.0; // Hz - lowest detectable
  static const double maxFrequency = 1000.0; // Hz - highest detectable

  PitchFilter({this.sampleRate = 44100, this.windowSize = 2048});

  /// Extract fundamental frequency from audio sample
  /// Returns frequency in Hz, or 0.0 if no pitch detected
  double extractPitch(Uint8List audioData) {
    try {
      // Convert bytes to audio samples
      final samples = _bytesToSamples(audioData);

      if (samples.length < windowSize) {
        return 0.0; // Not enough data
      }

      // Apply autocorrelation for pitch detection
      final frequency = _autocorrelationPitch(samples);

      // Validate frequency range
      if (frequency < minFrequency || frequency > maxFrequency) {
        return 0.0;
      }

      return frequency;
    } catch (e) {
      // Filter fails gracefully - doesn't crash app
      return 0.0;
    }
  }

  /// Convert raw bytes to normalized audio samples
  List<double> _bytesToSamples(Uint8List bytes) {
    final samples = <double>[];

    // Convert 16-bit PCM to normalized doubles
    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Combine two bytes into 16-bit sample (little endian)
      int sample = bytes[i] | (bytes[i + 1] << 8);

      // Convert to signed 16-bit
      if (sample > 32767) sample -= 65536;

      // Normalize to [-1.0, 1.0]
      samples.add(sample / 32768.0);
    }

    return samples;
  }

  /// Autocorrelation-based pitch detection
  double _autocorrelationPitch(List<double> samples) {
    final length = math.min(samples.length, windowSize);
    final autocorr = List<double>.filled(length ~/ 2, 0.0);

    // Calculate autocorrelation
    for (int lag = 0; lag < autocorr.length; lag++) {
      double sum = 0.0;
      for (int i = 0; i < length - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      autocorr[lag] = sum;
    }

    // Find peak (excluding lag 0)
    double maxValue = 0.0;
    int maxIndex = 0;

    final minLag = (sampleRate / maxFrequency).round();
    final maxLag = (sampleRate / minFrequency).round();

    for (int i = minLag; i < math.min(maxLag, autocorr.length); i++) {
      if (autocorr[i] > maxValue) {
        maxValue = autocorr[i];
        maxIndex = i;
      }
    }

    // Convert lag to frequency
    if (maxIndex > 0 && maxValue > 0.3) {
      // Threshold for valid pitch
      return sampleRate / maxIndex;
    }

    return 0.0;
  }

  /// Get filter configuration info
  Map<String, dynamic> getConfig() {
    return {
      'filterType': 'PitchFilter',
      'sampleRate': sampleRate,
      'windowSize': windowSize,
      'minFrequency': minFrequency,
      'maxFrequency': maxFrequency,
      'algorithm': 'Autocorrelation',
    };
  }

  /// Generate test tone for validation
  static Uint8List generateTestTone({
    required double frequency,
    int sampleRate = 44100,
    double durationSeconds = 1.0,
    double amplitude = 0.5,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final bytes = <int>[];

    for (int i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;
      final sample = amplitude * math.sin(2 * math.pi * frequency * time);
      final intSample = (sample * 32767).round().clamp(-32768, 32767);

      // Convert to little-endian bytes
      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return Uint8List.fromList(bytes);
  }
}
