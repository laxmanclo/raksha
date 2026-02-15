import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;
  static Completer<void>? _speakCompleter;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('en-IN'); // English-India accent
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakCompleter?.complete();
      _speakCompleter = null;
    });

    _isInitialized = true;
  }

  /// Speak text and return a Future that completes when done speaking
  static Future<void> speak(String text) async {
    await initialize();
    _isSpeaking = true;
    _speakCompleter = Completer<void>();
    await _flutterTts.speak(text);
    return _speakCompleter?.future ?? Future.value();
  }
  
  /// Speak text without waiting for completion
  static Future<void> speakAsync(String text) async {
    await initialize();
    _isSpeaking = true;
    _speakCompleter = Completer<void>();
    await _flutterTts.speak(text);
  }

  static bool get isSpeaking => _isSpeaking;

  static Future<void> stop() async {
    _isSpeaking = false;
    _speakCompleter?.complete();
    _speakCompleter = null;
    await _flutterTts.stop();
  }

  /// Set language (e.g. 'en-IN', 'hi-IN')
  static Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }
}
