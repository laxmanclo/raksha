import 'package:flutter/foundation.dart';
import '../models/threat_model.dart';
import 'api_service.dart';

class ThreatService extends ChangeNotifier {
  ThreatAnalysis? _currentAnalysis;
  bool _isAnalyzing = false;
  String? _lastAnalyzedText;

  ThreatAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isAnalyzing => _isAnalyzing;

  /// Send transcript to backend for Claude-powered analysis
  Future<void> analyzeText(String text, List<String> context, int callDuration) async {
    if (text.trim().isEmpty) return;
    // Don't re-analyze the exact same text
    if (text == _lastAnalyzedText) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final analysis = await ApiService.analyzeText(text, context, callDuration);
      _currentAnalysis = analysis;
      _lastAnalyzedText = text;
      notifyListeners();
    } catch (e) {
      debugPrint('Error analyzing text: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearAnalysis() {
    _currentAnalysis = null;
    _lastAnalyzedText = null;
    notifyListeners();
  }
}
