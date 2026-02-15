import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('hi-IN'); // Hindi
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    await initialize();
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<void> speakShield(String script) async {
    await speak(script);
  }

  static Future<void> speakInterrogate(String script) async {
    await speak(script);
  }

  static Future<void> speakSiren(String script) async {
    await speak(script);
  }
}
