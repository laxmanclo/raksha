import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;
  static Completer<void>? _speakCompleter;
  
  /// Timestamp when TTS last finished — used for echo buffer
  static DateTime? _lastSpeakEnd;
  
  /// How long to ignore mic input after TTS stops (echo tail)
  static const _echoBufferMs = 600;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('en-IN'); // English-India accent
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _lastSpeakEnd = DateTime.now();
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
  
  /// Speak as the scammer — deeper male voice
  static Future<void> speakAsScammer(String text) async {
    await initialize();
    await _flutterTts.setPitch(0.7);      // low pitch → male
    await _flutterTts.setSpeechRate(0.48); // slightly faster, pushy
    _isSpeaking = true;
    _speakCompleter = Completer<void>();
    await _flutterTts.speak(text);
    return _speakCompleter?.future ?? Future.value();
  }
  
  /// Speak as the AI agent — higher-pitched female voice
  static Future<void> speakAsAgent(String text) async {
    await initialize();
    await _flutterTts.setPitch(1.4);      // high pitch → female
    await _flutterTts.setSpeechRate(0.42); // calm, measured
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
  
  /// True while TTS is playing OR within [_echoBufferMs] of finishing.
  /// Use this to gate mic input — prevents speaker echo from being transcribed.
  static bool get isSpeakingOrEcho {
    if (_isSpeaking) return true;
    if (_lastSpeakEnd == null) return false;
    return DateTime.now().difference(_lastSpeakEnd!).inMilliseconds < _echoBufferMs;
  }

  static Future<void> stop() async {
    _isSpeaking = false;
    _lastSpeakEnd = DateTime.now();
    _speakCompleter?.complete();
    _speakCompleter = null;
    await _flutterTts.stop();
  }

  /// Set language (e.g. 'en-IN', 'hi-IN')
  static Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }
}
