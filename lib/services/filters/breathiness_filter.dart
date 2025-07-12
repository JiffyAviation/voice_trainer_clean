import 'dart:typed_data';
import 'dart:math' as math;

/// Isolated breathiness detection filter - air flow and spectral tilt analysis
class BreathinessFilter {
  final int sampleRate;
  final int windowSize;
  final int fftSize;

  // Frequency bands for breathiness analysis
  static const double lowFreqBand = 1000.0; // Hz - fundamental range
  static const double highFreqBand = 4000.0; // Hz - noise range
  static const double maxFreqBand = 8000.0; // Hz - upper limit

  BreathinessFilter({
    this.sampleRate = 44100,
    this.windowSize = 2048,
    this.fftSize = 4096,
  });

  /// Extract breathiness metrics from audio sample
  /// Returns [spectralTilt, noiseToHarmonicsRatio, breathinessScore]
  List<double> extractBreathiness(Uint8List audioData) {
    try {
      // Convert bytes to audio samples
      final samples = _bytesToSamples(audioData);

      if (samples.length < windowSize) {
        return [0.0, 0.0, 0.0]; // Not enough data
      }

      // Compute power spectrum
      final spectrum = _computeSpectrum(samples);

      // Calculate breathiness metrics
      final spectralTilt = _calculateSpectralTilt(spectrum);
      final noiseRatio = _calculateNoiseToHarmonicsRatio(spectrum);
      final breathinessScore = _calculateBreathinessScore(
        spectralTilt,
        noiseRatio,
      );

      return [spectralTilt, noiseRatio, breathinessScore];
    } catch (e) {
      // Filter fails gracefully
      return [0.0, 0.0, 0.0];
    }
  }

  /// Convert raw bytes to normalized audio samples
  List<double> _bytesToSamples(Uint8List bytes) {
    final samples = <double>[];

    for (int i = 0; i < bytes.length - 1; i += 2) {
      int sample = bytes[i] | (bytes[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      samples.add(sample / 32768.0);
    }

    return samples;
  }

  /// Compute power spectrum
  List<double> _computeSpectrum(List<double> samples) {
    final length = math.min(samples.length, windowSize);
    final windowed = List<double>.filled(fftSize, 0.0);

    // Apply Hamming window
    for (int i = 0; i < length; i++) {
      final window = 0.54 - 0.46 * math.cos(2 * math.pi * i / (length - 1));
      windowed[i] = samples[i] * window;
    }

    // Simplified power spectrum
    final spectrum = List<double>.filled(fftSize ~/ 2, 0.0);

    for (int k = 0; k < spectrum.length; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int n = 0; n < windowed.length; n++) {
        final angle = -2 * math.pi * k * n / fftSize;
        real += windowed[n] * math.cos(angle);
        imag += windowed[n] * math.sin(angle);
      }

      spectrum[k] = real * real + imag * imag;
    }

    return spectrum;
  }

  /// Calculate spectral tilt (high vs low frequency energy)
  double _calculateSpectralTilt(List<double> spectrum) {
    double lowBandEnergy = 0.0;
    double highBandEnergy = 0.0;

    final nyquist = sampleRate / 2;
    final binSize = nyquist / spectrum.length;

    for (int i = 0; i < spectrum.length; i++) {
      final frequency = i * binSize;

      if (frequency <= lowFreqBand) {
        lowBandEnergy += spectrum[i];
      } else if (frequency >= highFreqBand && frequency <= maxFreqBand) {
        highBandEnergy += spectrum[i];
      }
    }

    // Spectral tilt: ratio of high to low frequency energy
    if (lowBandEnergy > 0) {
      return highBandEnergy / lowBandEnergy;
    }
    return 0.0;
  }

  /// Calculate noise-to-harmonics ratio
  double _calculateNoiseToHarmonicsRatio(List<double> spectrum) {
    // Find fundamental frequency (strongest peak in low range)
    double maxPower = 0.0;
    int fundamentalBin = 0;

    final nyquist = sampleRate / 2;
    final binSize = nyquist / spectrum.length;
    final maxSearchBin = (500 / binSize).round(); // Search up to 500Hz

    for (int i = 10; i < math.min(maxSearchBin, spectrum.length); i++) {
      if (spectrum[i] > maxPower) {
        maxPower = spectrum[i];
        fundamentalBin = i;
      }
    }

    if (fundamentalBin == 0) return 1.0; // No clear fundamental

    // Calculate harmonic and noise energy
    double harmonicEnergy = 0.0;
    double noiseEnergy = 0.0;
    int harmonicCount = 0;

    // Check harmonics (2f, 3f, 4f, etc.)
    for (int harmonic = 1; harmonic <= 8; harmonic++) {
      final harmonicBin = fundamentalBin * harmonic;
      if (harmonicBin >= spectrum.length) break;

      // Harmonic energy (peak ± 2 bins)
      double peakEnergy = 0.0;
      for (int offset = -2; offset <= 2; offset++) {
        final bin = harmonicBin + offset;
        if (bin >= 0 && bin < spectrum.length) {
          peakEnergy = math.max(peakEnergy, spectrum[bin]);
        }
      }
      harmonicEnergy += peakEnergy;
      harmonicCount++;

      // Noise energy (between harmonics)
      if (harmonic < 8) {
        final nextHarmonicBin = fundamentalBin * (harmonic + 1);
        final midPoint = (harmonicBin + nextHarmonicBin) ~/ 2;
        if (midPoint < spectrum.length) {
          noiseEnergy += spectrum[midPoint];
        }
      }
    }

    // Normalize and calculate ratio
    if (harmonicEnergy > 0 && harmonicCount > 0) {
      final avgHarmonicEnergy = harmonicEnergy / harmonicCount;
      final avgNoiseEnergy = noiseEnergy / math.max(1, harmonicCount - 1);
      return avgNoiseEnergy / avgHarmonicEnergy;
    }

    return 1.0; // High noise if can't determine
  }

  /// Calculate overall breathiness score (0.0 = modal, 1.0 = very breathy)
  double _calculateBreathinessScore(double spectralTilt, double noiseRatio) {
    // Combine spectral tilt and noise ratio into single score
    final tiltScore = math.min(spectralTilt * 0.5, 1.0); // Weight spectral tilt
    final noiseScore = math.min(noiseRatio, 1.0); // Noise ratio contribution

    // Weighted combination
    final breathiness = (tiltScore * 0.6 + noiseScore * 0.4).clamp(0.0, 1.0);

    return breathiness;
  }

  /// Analyze voice quality from breathiness metrics
  Map<String, dynamic> analyzeVoiceQuality(List<double> breathiness) {
    final spectralTilt = breathiness[0];
    final noiseRatio = breathiness[1];
    final breathinessScore = breathiness[2];

    String voiceQuality = 'Unknown';
    String recommendation = 'No data';

    if (breathinessScore < 0.3) {
      voiceQuality = 'Modal (clear)';
      recommendation = 'Strong, clear voice. Good vocal cord closure.';
    } else if (breathinessScore < 0.6) {
      voiceQuality = 'Slightly breathy';
      recommendation = 'Some air leakage. Practice breath support exercises.';
    } else if (breathinessScore < 0.8) {
      voiceQuality = 'Moderately breathy';
      recommendation =
          'Noticeable breathiness. Work on vocal cord coordination.';
    } else {
      voiceQuality = 'Very breathy';
      recommendation =
          'Significant air flow. Consider vocal therapy consultation.';
    }

    return {
      'voiceQuality': voiceQuality,
      'breathinessScore': (breathinessScore * 100).round(),
      'spectralTilt': spectralTilt.toStringAsFixed(3),
      'noiseRatio': noiseRatio.toStringAsFixed(3),
      'recommendation': recommendation,
    };
  }

  /// Get filter configuration info
  Map<String, dynamic> getConfig() {
    return {
      'filterType': 'BreathinessFilter',
      'sampleRate': sampleRate,
      'windowSize': windowSize,
      'fftSize': fftSize,
      'lowFreqBand': lowFreqBand,
      'highFreqBand': highFreqBand,
      'maxFreqBand': maxFreqBand,
      'algorithm': 'Spectral Tilt + Noise Analysis',
    };
  }

  /// Generate synthetic breathy voice for testing
  static Uint8List generateBreathyVoice({
    required double fundamentalFreq,
    required double breathinessLevel, // 0.0 = modal, 1.0 = very breathy
    int sampleRate = 44100,
    double durationSeconds = 1.0,
    double amplitude = 0.3,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final bytes = <int>[];
    final random = math.Random();

    for (int i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;

      // Pure harmonic voice component
      double harmonicSignal = 0.0;
      for (int harmonic = 1; harmonic <= 5; harmonic++) {
        final harmonicAmp = amplitude / harmonic;
        harmonicSignal +=
            harmonicAmp *
            math.sin(2 * math.pi * fundamentalFreq * harmonic * time);
      }

      // Noise component (breathiness)
      final noiseSignal =
          (random.nextDouble() - 0.5) * amplitude * breathinessLevel;

      // High-frequency noise (aspiration)
      final aspirationNoise =
          (random.nextDouble() - 0.5) * amplitude * breathinessLevel * 0.5;

      // Combine signals
      final modalVoice = harmonicSignal * (1.0 - breathinessLevel);
      final breathyVoice =
          (harmonicSignal + noiseSignal + aspirationNoise) * breathinessLevel;
      final finalSignal = modalVoice + breathyVoice;

      final intSample = (finalSignal * 32767).round().clamp(-32768, 32767);

      // Convert to little-endian bytes
      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return Uint8List.fromList(bytes);
  }
}
