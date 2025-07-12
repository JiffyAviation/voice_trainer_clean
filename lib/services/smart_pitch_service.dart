import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SmartPitchService {
  bool _isDetecting = false;
  double _currentFrequency = 0.0;
  StreamController<double>? _frequencyController;
  Timer? _simulationTimer;

  bool get isDetecting => _isDetecting;
  double get currentFrequency => _currentFrequency;
  Stream<double>? get frequencyStream => _frequencyController?.stream;

  SmartPitchService() {
    _frequencyController = StreamController<double>.broadcast();
  }

  Future<bool> initialize() async {
    try {
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
      _simulateFrequencyDetection();

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
    _simulationTimer?.cancel();
    _updateFrequency(0.0);

    if (kDebugMode) {
      print('SmartPitchService: Detection stopped');
    }
  }

  void _updateFrequency(double frequency) {
    _currentFrequency = frequency;
    _frequencyController?.add(frequency);
  }

  void _simulateFrequencyDetection() {
    _simulationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
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
    _simulationTimer?.cancel();
    _frequencyController?.close();
  }
}
