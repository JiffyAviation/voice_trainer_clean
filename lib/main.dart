import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'services/voice_analysis_service.dart';

void main() {
  runApp(VoiceTrainerApp());
}

class VoiceTrainerApp extends StatelessWidget {
  const VoiceTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Trainer Clean',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PitchDetectionScreen(),
    );
  }
}

class PitchDetectionScreen extends StatefulWidget {
  const PitchDetectionScreen({super.key});

  @override
  State<PitchDetectionScreen> createState() => _PitchDetectionScreenState();
}

class _PitchDetectionScreenState extends State<PitchDetectionScreen>
    with WidgetsBindingObserver {
  bool _isDetecting = false;
  double _currentFrequency = 0.0;
  String _cachedNoteName = '--';
  Timer? _simulationTimer;

  // Add the new voice analysis service
  late VoiceAnalysisService _voiceService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceService = VoiceAnalysisService(); // Initialize the service
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _simulationTimer?.cancel();
    super.dispose();
  }

  // Pause updates when app is backgrounded
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isDetecting) {
      _pauseSimulation();
    } else if (state == AppLifecycleState.resumed && _isDetecting) {
      _resumeSimulation();
    }
  }

  Future<void> _toggleDetection() async {
    setState(() {
      _isDetecting = !_isDetecting;
    });

    if (_isDetecting) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
  }

  void _startSimulation() {
    // Optimize: 60fps = ~16ms, but we don't need that fast for frequency
    // Use 50ms (20fps) - smooth enough for frequency display
    _simulationTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }
      _updateFrequency();
    });
  }

  void _pauseSimulation() {
    _simulationTimer?.cancel();
  }

  void _resumeSimulation() {
    if (_isDetecting) {
      _startSimulation();
    }
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _updateFrequencyTo(0.0);
  }

  void _updateFrequency() {
    // Simulate voice frequency variations around 200-400 Hz
    final baseFreq = 300.0;
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // More realistic voice-like variation using sine wave
    final variation = 30.0 * math.sin(time * 2.0) + 15.0 * math.sin(time * 5.0);
    final frequency = baseFreq + variation;

    _updateFrequencyTo(frequency);
  }

  void _updateFrequencyTo(double frequency) {
    // Only update if frequency changed significantly (optimization)
    if ((frequency - _currentFrequency).abs() > 0.5) {
      // Use VoiceAnalysisService for note calculation (backward compatibility)
      final newNoteName = _calculateNoteName(frequency);

      setState(() {
        _currentFrequency = frequency;
        _cachedNoteName = newNoteName;
      });
    }
  }

  // Keep the old note calculation for now (we'll replace this next)
  String _calculateNoteName(double frequency) {
    if (frequency < 80) return '--';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Trainer Clean - With Analysis Service!'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microphone indicator
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isDetecting ? Colors.red : Colors.grey,
                boxShadow: _isDetecting
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(Icons.mic, size: 50, color: Colors.white),
            ),

            SizedBox(height: 30),

            // Frequency display
            Text(
              '${_currentFrequency.toStringAsFixed(1)} Hz',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _currentFrequency > 100 ? Colors.green : Colors.grey,
              ),
            ),

            SizedBox(height: 20),

            // Note name (using cached value)
            Text(
              _cachedNoteName,
              style: TextStyle(fontSize: 24, color: Colors.blue),
            ),

            SizedBox(height: 40),

            // Control button
            ElevatedButton(
              onPressed: _toggleDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetecting ? Colors.red : Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                elevation: _isDetecting ? 8 : 4,
              ),
              child: Text(
                _isDetecting ? 'Stop Detection' : 'Start Detection',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

            // Status text
            Text(
              _isDetecting
                  ? 'Simulating pitch detection...'
                  : 'Ready to simulate',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
