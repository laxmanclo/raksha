import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/threat_model.dart';

class CallService extends ChangeNotifier {
  bool _isListening = false;
  bool _isCallActive = false;
  final List<TranscriptLine> _transcript = [];
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  
  // Live partial text from ASR (what the user is currently saying)
  String _livePartial = '';

  bool get isListening => _isListening;
  bool get isCallActive => _isCallActive;
  List<TranscriptLine> get transcript => List.unmodifiable(_transcript);
  Duration get callDuration => _callDuration;
  String get livePartial => _livePartial;

  void startCall() {
    _isCallActive = true;
    _isListening = true;
    _callDuration = Duration.zero;
    _transcript.clear();
    _livePartial = '';
    
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      notifyListeners();
    });
    
    notifyListeners();
  }

  void endCall({bool silent = false}) {
    _isCallActive = false;
    _isListening = false;
    _livePartial = '';
    _durationTimer?.cancel();
    if (!silent) {
      try { notifyListeners(); } catch (_) {}
    }
  }

  void addTranscriptLine(String text, {bool isCleaned = false, bool isScammer = false}) {
    if (text.trim().isEmpty) return;
    _transcript.add(TranscriptLine(
      text: text.trim(),
      timestamp: DateTime.now(),
      isCleaned: isCleaned,
      isScammer: isScammer,
    ));
    _livePartial = '';  // Clear partial when sentence is committed
    try { notifyListeners(); } catch (_) {}
  }
  
  void updateLivePartial(String partial) {
    if (partial != _livePartial) {
      _livePartial = partial;
      notifyListeners();
    }
  }

  void clearTranscript() {
    _transcript.clear();
    _livePartial = '';
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
