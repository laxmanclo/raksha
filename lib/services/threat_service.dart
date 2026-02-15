import 'package:flutter/foundation.dart';
import '../models/threat_model.dart';
import 'api_service.dart';

class ThreatService extends ChangeNotifier {
  ThreatAnalysis? _currentAnalysis;
  bool _isAnalyzing = false;
  final List<ThreatAnalysis> _analysisHistory = [];

  ThreatAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  List<ThreatAnalysis> get analysisHistory => List.unmodifiable(_analysisHistory);

  Future<void> analyzeText(String text, List<String> context, int callDuration) async {
    if (text.trim().isEmpty) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final analysis = await ApiService.analyzeText(text, context, callDuration);
      _currentAnalysis = analysis;
      _analysisHistory.add(analysis);
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
    notifyListeners();
  }

  void resetHistory() {
    _analysisHistory.clear();
    _currentAnalysis = null;
    notifyListeners();
  }

  int get maxThreatScore {
    if (_analysisHistory.isEmpty) return 0;
    return _analysisHistory
        .map((a) => a.threatScore)
        .reduce((a, b) => a > b ? a : b);
  }
}
