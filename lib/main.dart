import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(VoiceTrainerApp());
}

class VoiceTrainerApp extends StatelessWidget {
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
  @override
  _PitchDetectionScreenState createState() => _PitchDetectionScreenState();
}

class _PitchDetectionScreenState extends State<PitchDetectionScreen> {
  bool _isDetecting = false;
  double _currentFrequency = 0.0;
  Timer? _simulationTimer;

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

      setState(() {
        _currentFrequency = frequency;
      });
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _currentFrequency = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Trainer Clean - Working!'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isDetecting ? Colors.red : Colors.grey,
              ),
              child: Icon(Icons.mic, size: 50, color: Colors.white),
            ),

            SizedBox(height: 30),

            Text(
              '${_currentFrequency.toStringAsFixed(1)} Hz',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _currentFrequency > 100 ? Colors.green : Colors.grey,
              ),
            ),

            SizedBox(height: 20),

            Text(
              _getNoteName(_currentFrequency),
              style: TextStyle(fontSize: 24, color: Colors.blue),
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: _toggleDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetecting ? Colors.red : Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                _isDetecting ? 'Stop Detection' : 'Start Detection',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

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

  String _getNoteName(double frequency) {
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
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
