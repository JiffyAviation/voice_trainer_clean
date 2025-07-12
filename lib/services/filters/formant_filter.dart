import 'dart:typed_data';
import 'dart:math' as math;

/// Isolated formant detection filter - vocal tract resonance analysis
class FormantFilter {
  final int sampleRate;
  final int windowSize;
  final int fftSize;

  // Formant frequency ranges (typical human vocal tract)
  static const List<List<double>> formantRanges = [
    [200, 1000], // F1 range (jaw/tongue height)
    [800, 3000], // F2 range (tongue position)
    [1500, 4000], // F3 range (tongue tip/lip rounding)
  ];

  FormantFilter({
    this.sampleRate = 44100,
    this.windowSize = 2048,
    this.fftSize = 4096,
  });

  /// Extract formant frequencies from audio sample
  /// Returns [F1, F2, F3] in Hz, or [0.0, 0.0, 0.0] if not detected
  List<double> extractFormants(Uint8List audioData) {
    try {
      // Convert bytes to audio samples
      final samples = _bytesToSamples(audioData);

      if (samples.length < windowSize) {
        return [0.0, 0.0, 0.0]; // Not enough data
      }

      // Apply window function and compute spectrum
      final spectrum = _computeSpectrum(samples);

      // Find formant peaks
      final formants = _findFormantPeaks(spectrum);

      return formants;
    } catch (e) {
      // Filter fails gracefully - doesn't crash app
      return [0.0, 0.0, 0.0];
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

  /// Compute power spectrum using simplified FFT approach
  List<double> _computeSpectrum(List<double> samples) {
    final length = math.min(samples.length, windowSize);
    final windowed = List<double>.filled(fftSize, 0.0);

    // Apply Hamming window and zero-pad
    for (int i = 0; i < length; i++) {
      final window = 0.54 - 0.46 * math.cos(2 * math.pi * i / (length - 1));
      windowed[i] = samples[i] * window;
    }

    // Simplified power spectrum calculation
    final spectrum = List<double>.filled(fftSize ~/ 2, 0.0);

    for (int k = 0; k < spectrum.length; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int n = 0; n < windowed.length; n++) {
        final angle = -2 * math.pi * k * n / fftSize;
        real += windowed[n] * math.cos(angle);
        imag += windowed[n] * math.sin(angle);
      }

      // Power spectrum
      spectrum[k] = real * real + imag * imag;
    }

    return spectrum;
  }

  /// Find formant peaks in the spectrum
  List<double> _findFormantPeaks(List<double> spectrum) {
    final formants = [0.0, 0.0, 0.0];

    // For each formant range, find the peak
    for (
      int formantIndex = 0;
      formantIndex < formantRanges.length;
      formantIndex++
    ) {
      final minFreq = formantRanges[formantIndex][0];
      final maxFreq = formantRanges[formantIndex][1];

      // Convert frequency range to spectrum indices
      final minBin = (minFreq * fftSize / sampleRate).round();
      final maxBin = (maxFreq * fftSize / sampleRate).round();

      // Find peak in this range
      double maxPower = 0.0;
      int peakBin = 0;

      for (int bin = minBin; bin < math.min(maxBin, spectrum.length); bin++) {
        if (spectrum[bin] > maxPower) {
          maxPower = spectrum[bin];
          peakBin = bin;
        }
      }

      // Convert bin back to frequency
      if (maxPower > _getThreshold(formantIndex)) {
        formants[formantIndex] = peakBin * sampleRate / fftSize;
      }
    }

    return formants;
  }

  /// Get detection threshold for each formant
  double _getThreshold(int formantIndex) {
    // Different thresholds for different formants
    switch (formantIndex) {
      case 0:
        return 0.1; // F1 - usually strongest
      case 1:
        return 0.05; // F2 - moderate strength
      case 2:
        return 0.02; // F3 - weakest
      default:
        return 0.1;
    }
  }

  /// Analyze voice characteristics from formants
  Map<String, dynamic> analyzeVoiceCharacteristics(List<double> formants) {
    final f1 = formants[0];
    final f2 = formants[1];
    final f3 = formants[2];

    // Basic voice analysis
    String voiceType = 'Unknown';
    String vowelHint = 'Unknown';

    if (f1 > 0 && f2 > 0) {
      // Rough voice type classification
      if (f1 < 400 && f2 > 2000) {
        voiceType = 'Feminine-leaning';
      } else if (f1 > 500 && f2 < 1500) {
        voiceType = 'Masculine-leaning';
      } else {
        voiceType = 'Neutral';
      }

      // Basic vowel space analysis
      if (f1 < 400 && f2 > 2000) {
        vowelHint = 'High front vowel (ee/i)';
      } else if (f1 > 600 && f2 < 1200) {
        vowelHint = 'Low back vowel (ah/o)';
      } else if (f1 > 400 && f2 > 1800) {
        vowelHint = 'High front vowel (eh/a)';
      } else {
        vowelHint = 'Mid vowel';
      }
    }

    return {
      'voiceType': voiceType,
      'vowelHint': vowelHint,
      'f1': f1.round(),
      'f2': f2.round(),
      'f3': f3.round(),
      'f1_f2_ratio': f2 > 0 ? (f2 / f1).toStringAsFixed(2) : '0.0',
    };
  }

  /// Get filter configuration info
  Map<String, dynamic> getConfig() {
    return {
      'filterType': 'FormantFilter',
      'sampleRate': sampleRate,
      'windowSize': windowSize,
      'fftSize': fftSize,
      'formantRanges': formantRanges,
      'algorithm': 'FFT + Peak Detection',
    };
  }

  /// Generate synthetic vowel for testing
  static Uint8List generateVowelSample({
    required double f1,
    required double f2,
    required double f3,
    int sampleRate = 44100,
    double durationSeconds = 1.0,
    double amplitude = 0.3,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final bytes = <int>[];

    for (int i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;

      // Create vowel by combining formant frequencies
      final formant1 = amplitude * math.sin(2 * math.pi * f1 * time);
      final formant2 = amplitude * 0.7 * math.sin(2 * math.pi * f2 * time);
      final formant3 = amplitude * 0.5 * math.sin(2 * math.pi * f3 * time);

      final sample = formant1 + formant2 + formant3;
      final intSample = (sample * 32767).round().clamp(-32768, 32767);

      // Convert to little-endian bytes
      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return Uint8List.fromList(bytes);
  }
}
