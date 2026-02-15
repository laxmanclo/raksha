import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/threat_model.dart';

/// Raksha Backend API Service
/// All audio stays on-device — only PII-stripped text is sent.
class ApiService {
  static const String baseUrl = 'https://raksha-backend.replit.app';
  
  // Current session
  static String? _sessionId;
  static String? get sessionId => _sessionId;
  static bool get hasSession => _sessionId != null;
  
  /// Start a new call session. Call when user taps "Start Monitoring".
  static Future<String> startSession() async {
    try {
      debugPrint('🔗 [API] Starting session...');
      final response = await http.post(
        Uri.parse('$baseUrl/api/session/start'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        debugPrint('✅ [API] Session started: $_sessionId');
        return _sessionId!;
      } else {
        debugPrint('❌ [API] Session start failed: ${response.statusCode}');
        throw Exception('Failed to start session: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [API] Session start error (using offline): $e');
      // Generate offline session ID
      _sessionId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      return _sessionId!;
    }
  }
  
  /// Main endpoint — analyze PII-stripped transcript text via Claude.
  static Future<ThreatAnalysis> analyzeText(
    String text,
    List<String> context,
    int callDurationSec,
  ) async {
    if (text.trim().isEmpty) {
      return ThreatAnalysis(
        threatScore: 0,
        threatLevel: 'NONE',
        techniques: [],
        isAlert: false,
        explanation: '',
      );
    }
    
    // Ensure we have a session
    if (_sessionId == null) {
      await startSession();
    }
    
    try {
      debugPrint('🔍 [API] Analyzing: "${text.substring(0, text.length.clamp(0, 50))}..."');
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'session_id': _sessionId,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [API] Threat: ${data['threat_level']} (${data['threat_score']})');
        return ThreatAnalysis.fromJson(data);
      } else {
        debugPrint('❌ [API] Analyze failed: ${response.statusCode}');
        return _offlineAnalysis(text);
      }
    } catch (e) {
      debugPrint('⚠️ [API] Analyze error (offline fallback): $e');
      return _offlineAnalysis(text);
    }
  }
  
  /// Get AI takeover script from backend
  static Future<String> getTakeoverScript(String mode) async {
    if (_sessionId == null) return _offlineTakeover(mode);
    
    try {
      debugPrint('🤖 [API] Takeover request: $mode');
      final response = await http.post(
        Uri.parse('$baseUrl/api/takeover'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _sessionId,
          'mode': mode,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [API] Takeover script received');
        return data['script'] ?? _offlineTakeover(mode);
      }
      return _offlineTakeover(mode);
    } catch (e) {
      debugPrint('⚠️ [API] Takeover error: $e');
      return _offlineTakeover(mode);
    }
  }
  
  /// End the session and get summary
  static Future<void> endSession() async {
    if (_sessionId == null) return;
    
    try {
      await http.post(
        Uri.parse('$baseUrl/api/session/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': _sessionId}),
      ).timeout(const Duration(seconds: 5));
      debugPrint('✅ [API] Session ended');
    } catch (e) {
      debugPrint('⚠️ [API] End session error: $e');
    } finally {
      _sessionId = null;
    }
  }
  
  /// Check backend health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // ── Offline fallback analysis (keyword-based) ──
  
  static ThreatAnalysis _offlineAnalysis(String text) {
    final lower = text.toLowerCase();
    int score = 0;
    final techniques = <String>[];
    
    if (lower.contains('otp') || lower.contains('pin')) {
      score += 30;
      techniques.add('FINANCIAL_DEMAND');
    }
    if (lower.contains('urgent') || lower.contains('immediately') || lower.contains('jaldi')) {
      score += 20;
      techniques.add('URGENCY');
    }
    if (lower.contains('police') || lower.contains('cbi') || lower.contains('court') || lower.contains('officer')) {
      score += 25;
      techniques.add('AUTHORITY');
    }
    if (lower.contains('arrest') || lower.contains('warrant') || lower.contains('case')) {
      score += 25;
      techniques.add('FEAR');
    }
    if (lower.contains('account') || lower.contains('bank') || lower.contains('transfer')) {
      score += 15;
      techniques.add('FINANCIAL_DEMAND');
    }
    
    score = score.clamp(0, 100);
    final techniques_unique = techniques.toSet().toList();
    
    String level = 'NONE';
    if (score >= 71) level = 'CRITICAL';
    else if (score >= 51) level = 'HIGH';
    else if (score >= 31) level = 'MEDIUM';
    else if (score >= 15) level = 'LOW';
    
    String? scamType;
    if (lower.contains('arrest') && (lower.contains('police') || lower.contains('court'))) {
      scamType = 'DIGITAL_ARREST';
    } else if (lower.contains('otp') || lower.contains('pin')) {
      scamType = 'OTP_FRAUD';
    } else if (lower.contains('kyc')) {
      scamType = 'KYC_SCAM';
    }
    
    return ThreatAnalysis(
      threatScore: score,
      threatLevel: level,
      techniques: techniques_unique,
      isAlert: score >= 51,
      scamType: scamType,
      explanation: score > 0 ? 'Offline analysis: suspicious keywords detected' : '',
      takeoverScripts: score >= 51 ? TakeoverScripts(
        shield: 'Main khud verify karunga. Goodbye.',
        interrogate: 'Aapka badge number bataiye. FIR number kya hai?',
        siren: 'Fraud detected! Number trace ho raha hai!',
      ) : null,
    );
  }
  
  static String _offlineTakeover(String mode) {
    switch (mode) {
      case 'shield':
        return 'Main khud bank ki official website se call karunga. Goodbye.';
      case 'interrogate':
        return 'Aapka employee ID bataiye. Main head office se verify karunga.';
      case 'siren':
        return 'Fraud call detect ho gayi hai. Number trace ho raha hai. 1930 pe report ho rahi hai.';
      default:
        return 'Main verify karunga. Goodbye.';
    }
  }
}
