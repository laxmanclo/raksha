import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/threat_model.dart';

class CallService extends ChangeNotifier {
  bool _isListening = false;
  bool _isCallActive = false;
  final List<TranscriptLine> _transcript = [];
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  bool get isListening => _isListening;
  bool get isCallActive => _isCallActive;
  List<TranscriptLine> get transcript => List.unmodifiable(_transcript);
  Duration get callDuration => _callDuration;

  void startCall() {
    _isCallActive = true;
    _isListening = true;
    _callDuration = Duration.zero;
    _transcript.clear();
    
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      notifyListeners();
    });
    
    notifyListeners();
  }

  void endCall() {
    _isCallActive = false;
    _isListening = false;
    _durationTimer?.cancel();
    notifyListeners();
  }

  void addTranscriptLine(String text, {bool isCleaned = false}) {
    _transcript.add(TranscriptLine(
      text: text,
      timestamp: DateTime.now(),
      isCleaned: isCleaned,
    ));
    notifyListeners();
  }

  void toggleListening() {
    _isListening = !_isListening;
    notifyListeners();
  }

  void clearTranscript() {
    _transcript.clear();
    notifyListeners();
  }

  String getTranscriptText() {
    return _transcript.map((line) => line.text).join('\n');
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}
