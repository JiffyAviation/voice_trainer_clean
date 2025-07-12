import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'services/voice_analysis_service.dart';
import 'services/filters/formant_filter.dart';

void main() {
  runApp(VoiceTrainerApp());
}

class VoiceTrainerApp extends StatelessWidget {
  const VoiceTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Trainer MTF Pro',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VoiceAnalysisScreen(),
    );
  }
}

class VoiceAnalysisScreen extends StatefulWidget {
  const VoiceAnalysisScreen({super.key});

  @override
  State<VoiceAnalysisScreen> createState() => _VoiceAnalysisScreenState();
}

class _VoiceAnalysisScreenState extends State<VoiceAnalysisScreen>
    with WidgetsBindingObserver {
  bool _isAnalyzing = false;
  Timer? _analysisTimer;

  // Voice analysis service
  late VoiceAnalysisService _voiceService;

  // Analysis results
  Map<String, dynamic> _currentAnalysis = {
    'frequency': 0.0,
    'noteName': '--',
    'formants': {'f1': 0.0, 'f2': 0.0, 'f3': 0.0},
    'voiceCharacteristics': {'voiceType': 'Unknown', 'vowelHint': 'Unknown'},
    'voiceQuality': {
      'voiceQuality': 'Unknown',
      'breathinessScore': 0,
      'recommendation': 'No data',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceService = VoiceAnalysisService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isAnalyzing) {
      _pauseAnalysis();
    } else if (state == AppLifecycleState.resumed && _isAnalyzing) {
      _resumeAnalysis();
    }
  }

  Future<void> _toggleAnalysis() async {
    setState(() {
      _isAnalyzing = !_isAnalyzing;
    });

    if (_isAnalyzing) {
      _startAnalysis();
    } else {
      _stopAnalysis();
    }
  }

  void _startAnalysis() {
    _analysisTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (!_isAnalyzing) {
        timer.cancel();
        return;
      }
      _performVoiceAnalysis();
    });
  }

  void _pauseAnalysis() {
    _analysisTimer?.cancel();
  }

  void _resumeAnalysis() {
    if (_isAnalyzing) {
      _startAnalysis();
    }
  }

  void _stopAnalysis() {
    _analysisTimer?.cancel();
    setState(() {
      _currentAnalysis = {
        'frequency': 0.0,
        'noteName': '--',
        'formants': {'f1': 0.0, 'f2': 0.0, 'f3': 0.0},
        'voiceCharacteristics': {
          'voiceType': 'Unknown',
          'vowelHint': 'Unknown',
        },
        'voiceQuality': {
          'voiceQuality': 'Unknown',
          'breathinessScore': 0,
          'recommendation': 'Ready for analysis',
        },
      };
    });
  }

  void _performVoiceAnalysis() {
    // Generate realistic synthetic voice data for demo
    final baseF1 =
        300.0 + 50.0 * math.sin(DateTime.now().millisecondsSinceEpoch / 2000.0);
    final baseF2 =
        2100.0 +
        200.0 * math.cos(DateTime.now().millisecondsSinceEpoch / 3000.0);
    final baseF3 =
        2800.0 +
        100.0 * math.sin(DateTime.now().millisecondsSinceEpoch / 4000.0);

    // Generate synthetic voice sample
    final voiceData = FormantFilter.generateVowelSample(
      f1: baseF1,
      f2: baseF2,
      f3: baseF3,
      durationSeconds: 0.1,
    );

    // Perform full voice analysis
    final analysis = _voiceService.analyzeVoice(voiceData);

    setState(() {
      _currentAnalysis = analysis;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frequency = _currentAnalysis['frequency'] as double;
    final noteName = _currentAnalysis['noteName'] as String;
    final formants = _currentAnalysis['formants'] as Map<String, dynamic>;
    final voiceChar =
        _currentAnalysis['voiceCharacteristics'] as Map<String, dynamic>;
    final voiceQuality =
        _currentAnalysis['voiceQuality'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('🎤 Voice Trainer MTF Pro'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Microphone indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAnalyzing ? Colors.red : Colors.grey,
                boxShadow: _isAnalyzing
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(Icons.mic, size: 60, color: Colors.white),
            ),

            SizedBox(height: 20),

            // Pitch Analysis Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '🎵 Pitch Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${frequency.toStringAsFixed(1)} Hz',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: frequency > 100 ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      noteName,
                      style: TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Formant Analysis Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Formant Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFormantDisplay(
                          'F1',
                          formants['f1'] as double,
                          Colors.red,
                        ),
                        _buildFormantDisplay(
                          'F2',
                          formants['f2'] as double,
                          Colors.green,
                        ),
                        _buildFormantDisplay(
                          'F3',
                          formants['f3'] as double,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Voice Characteristics Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🗣️ Voice Characteristics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.purple),
                      title: Text('Voice Type'),
                      subtitle: Text(voiceChar['voiceType'].toString()),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.record_voice_over,
                        color: Colors.orange,
                      ),
                      title: Text('Vowel Character'),
                      subtitle: Text(voiceChar['vowelHint'].toString()),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Voice Quality Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💨 Voice Quality',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.air, color: Colors.lightBlue),
                      title: Text('Quality'),
                      subtitle: Text(voiceQuality['voiceQuality'].toString()),
                    ),
                    ListTile(
                      leading: Icon(Icons.trending_up, color: Colors.teal),
                      title: Text('Breathiness Score'),
                      subtitle: Text('${voiceQuality['breathinessScore']}%'),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              voiceQuality['recommendation'].toString(),
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Control button
            ElevatedButton(
              onPressed: _toggleAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAnalyzing
                    ? Colors.red
                    : Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                elevation: _isAnalyzing ? 8 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _isAnalyzing ? '⏹️ Stop Analysis' : '▶️ Start Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 20),

            // Status text
            Text(
              _isAnalyzing
                  ? '🔍 Analyzing voice patterns...'
                  : '📱 Ready for voice analysis',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormantDisplay(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value > 0 ? '${value.round()} Hz' : '--',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
