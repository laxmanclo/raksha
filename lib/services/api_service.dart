import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/threat_model.dart';

class ApiService {
  // Update this with your Replit backend URL
  static const String baseUrl = 'https://your-replit-project.repl.co';

  static Future<ThreatAnalysis> analyzeText(
    String text,
    List<String> context,
    int callDurationSec,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'context': context,
          'call_duration_sec': callDurationSec,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ThreatAnalysis.fromJson(data);
      } else {
        throw Exception('Failed to analyze: ${response.statusCode}');
      }
    } catch (e) {
      // Return a mock analysis for demo/testing
      return ThreatAnalysis(
        threatScore: _calculateMockScore(text),
        threatLevel: _getMockThreatLevel(text),
        techniques: _getMockTechniques(text),
        isAlert: _isMockAlert(text),
        scamType: _getMockScamType(text),
        explanation: 'Demo mode: Analysis based on keywords',
        takeoverScripts: TakeoverScripts(
          shield: 'Main khud bank ki official website se call karunga. Goodbye.',
          interrogate: 'Aapka employee ID bataiye. Main head office se verify karunga.',
          siren: 'Fraud call detect ho gayi hai. Number trace ho raha hai. 1930 pe report ho rahi hai.',
        ),
      );
    }
  }

  static int _calculateMockScore(String text) {
    final lower = text.toLowerCase();
    int score = 0;
    
    if (lower.contains('otp') || lower.contains('pin')) score += 30;
    if (lower.contains('urgent') || lower.contains('immediately')) score += 20;
    if (lower.contains('police') || lower.contains('cbi') || lower.contains('court')) score += 25;
    if (lower.contains('arrest') || lower.contains('summons')) score += 25;
    if (lower.contains('account') || lower.contains('bank')) score += 15;
    if (lower.contains('suspicious') || lower.contains('fraud')) score += 20;
    
    return score.clamp(0, 100);
  }

  static String _getMockThreatLevel(String text) {
    final score = _calculateMockScore(text);
    if (score >= 71) return 'CRITICAL';
    if (score >= 51) return 'HIGH';
    if (score >= 31) return 'MEDIUM';
    if (score >= 15) return 'LOW';
    return 'NONE';
  }

  static List<String> _getMockTechniques(String text) {
    final lower = text.toLowerCase();
    final techniques = <String>[];
    
    if (lower.contains('police') || lower.contains('bank') || lower.contains('officer')) {
      techniques.add('AUTHORITY');
    }
    if (lower.contains('urgent') || lower.contains('immediately') || lower.contains('now')) {
      techniques.add('URGENCY');
    }
    if (lower.contains('arrest') || lower.contains('legal') || lower.contains('case')) {
      techniques.add('FEAR');
    }
    if (lower.contains('otp') || lower.contains('pay') || lower.contains('transfer')) {
      techniques.add('FINANCIAL_DEMAND');
    }
    
    return techniques;
  }

  static bool _isMockAlert(String text) {
    return _calculateMockScore(text) >= 51;
  }

  static String? _getMockScamType(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('arrest') && (lower.contains('police') || lower.contains('court'))) {
      return 'DIGITAL_ARREST';
    }
    if (lower.contains('otp') || lower.contains('pin')) {
      return 'OTP_FRAUD';
    }
    if (lower.contains('kyc') || lower.contains('update')) {
      return 'KYC_SCAM';
    }
    if (lower.contains('prize') || lower.contains('winner')) {
      return 'PRIZE_SCAM';
    }
    
    return null;
  }
}
