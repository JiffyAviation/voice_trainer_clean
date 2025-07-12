import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:pitch_detector_dart/pitch_detector_dart.dart';

class SmartPitchService {
  bool _isDetecting = false;
  double _currentFrequency = 0.0;
  StreamController<double>? _frequencyController;

  // Platform-specific detectors
  FlutterPitchDetection? _androidDetector;
  PitchDetector? _dartDetector;

  bool get isDetecting => _isDetecting;
  double get currentFrequency => _currentFrequency;
  Stream<double>? get frequencyStream => _frequencyController?.stream;

  SmartPitchService() {
    _frequencyController = StreamController<double>.broadcast();
  }

  Future<bool> initialize() async {
    try {
      if (Platform.isAndroid) {
        // Use advanced Android detector
        _androidDetector = FlutterPitchDetection();
        await _androidDetector!.startDetection();
      } else {
        // Use cross-platform Dart detector
        _dartDetector = PitchDetector(44100, 2000);
      }

      if (kDebugMode) {
        print('SmartPitchService: Initialized for ${Platform.operatingSystem}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SmartPitchService: Failed to initialize - $e');
      }
      return false;
    }
  }

  Future<bool> startDetection() async {
    if (_isDetecting) return true;

    try {
      _isDetecting = true;

      if (Platform.isAndroid && _androidDetector != null) {
        // Android: Use real-time stream
        _androidDetector!.onPitchDetected.listen((data) {
          final frequency = data['frequency'] as double? ?? 0.0;
          _updateFrequency(frequency);
        });
      } else {
        // Other platforms: Simulate for now (we'll add real detection later)
        _simulateFrequencyDetection();
      }

      if (kDebugMode) {
        print('SmartPitchService: Detection started');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SmartPitchService: Failed to start detection - $e');
      }
      _isDetecting = false;
      return false;
    }
  }

  Future<void> stopDetection() async {
    _isDetecting = false;

    if (Platform.isAndroid && _androidDetector != null) {
      await _androidDetector!.stopDetection();
    }

    _updateFrequency(0.0);

    if (kDebugMode) {
      print('SmartPitchService: Detection stopped');
    }
  }

  void _updateFrequency(double frequency) {
    _currentFrequency = frequency;
    _frequencyController?.add(frequency);
  }

  // Temporary simulation for non-Android platforms
  void _simulateFrequencyDetection() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }

      // Simulate voice frequency variations around 200-400 Hz
      final baseFreq = 300.0;
      final variation =
          (DateTime.now().millisecondsSinceEpoch % 1000 - 500) / 10;
      final frequency = baseFreq + variation;

      _updateFrequency(frequency);
    });
  }

  void dispose() {
    stopDetection();
    _frequencyController?.close();
  }
}
