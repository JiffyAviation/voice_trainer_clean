import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      final newNoteName = _calculateNoteName(frequency);

      setState(() {
        _currentFrequency = frequency;
        _cachedNoteName = newNoteName;
      });
    }
  }

  // Cache note name calculation to avoid repeated computation
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
    final a4 = 440.0;

    if (frequency < 80 || frequency > 2000) return '--';

    final semitonesFromA4 = (12 * (math.log(frequency / a4) / math.log(2)))
        .round();
    final noteIndex = (9 + semitonesFromA4) % 12;
    final octave = 4 + ((9 + semitonesFromA4) ~/ 12);

    return '${noteNames[noteIndex]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Trainer Clean - Optimized!'),
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
                          color: Colors.red.withOpacity(0.3),
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
