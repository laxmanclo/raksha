import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import 'dart:async';

/// Service for Sherpa ONNX ASR — fully on-device speech recognition.
/// Accumulates partial results and emits complete sentences via endpoint detection.
class AsrService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isListening = false;
  bool _disposed = false;
  
  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  // Accumulate partial text to build full sentences
  String _currentPartial = '';
  String get currentPartial => _currentPartial;
  
  // Callback for partial updates (live "typing" effect)
  Function(String partial)? _onPartialUpdate;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🎙️ Initializing Sherpa ONNX ASR...');
      
      final modelPaths = await ModelManager.initializeModels();
      debugPrint('📁 Models loaded');
      
      sherpa.initBindings();
      debugPrint('✅ Sherpa ONNX bindings ready');
      
      // Enable endpoint detection so it groups words into sentences
      final recognizerConfig = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: modelPaths['encoder']!,
            decoder: modelPaths['decoder']!,
            joiner: modelPaths['joiner']!,
          ),
          tokens: modelPaths['tokens']!,
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
        decodingMethod: 'greedy_search',
        // ENABLE endpoint detection — this groups words into sentences
        enableEndpoint: true,
        rule1MinTrailingSilence: 2.4,  // 2.4s silence after ANY token → endpoint
        rule2MinTrailingSilence: 1.2,  // 1.2s silence after non-single-char → endpoint
        rule3MinUtteranceLength: 20.0, // force endpoint after 20s
      );
      
      _recognizer = sherpa.OnlineRecognizer(recognizerConfig);
      _stream = _recognizer!.createStream();
      
      _isInitialized = true;
      _safeNotify();
      
      debugPrint('🎉 ASR initialized — endpoint detection ON');
    } catch (e) {
      debugPrint('❌ ASR init error: $e');
      rethrow;
    }
  }
  
  /// Start listening. [onSentence] fires when a complete sentence is ready.
  /// [onPartial] fires with live partial text as user speaks (for UI feedback).
  Future<void> startListening({
    required Function(String) onSentence,
    Function(String)? onPartial,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (_recognizer == null || _stream == null) {
      throw Exception('ASR not initialized');
    }
    
    _onPartialUpdate = onPartial;
    _isListening = true;
    _currentPartial = '';
    _safeNotify();
    
    debugPrint('🎙️ ASR listening — will emit sentences on endpoint');
  }
  
  /// Feed audio into the recognizer. Called directly from mic callback.
  int _chunkCount = 0;
  
  void processAudioChunk(Float32List samples, Function(String) onSentence) {
    if (!_isListening || _recognizer == null || _stream == null) return;
    
    _chunkCount++;
    
    try {
      // Feed audio directly to recognizer stream
      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);
      
      // Decode all available frames
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }
      
      // Check if endpoint detected (= sentence boundary)
      final isEndpoint = _recognizer!.isEndpoint(_stream!);
      
      // Get current result
      final result = _recognizer!.getResult(_stream!);
      final text = result.text.trim();
      
      if (text.isNotEmpty) {
        // Update partial text for live UI
        _currentPartial = text;
        _onPartialUpdate?.call(text);
      }
      
      // Endpoint detected → emit the complete sentence
      if (isEndpoint && text.isNotEmpty) {
        debugPrint('✅ [ASR] Sentence: "$text"');
        onSentence(text);
        
        // Reset for next utterance
        _recognizer!.reset(_stream!);
        _currentPartial = '';
        _onPartialUpdate?.call('');
      } else if (isEndpoint) {
        // Endpoint with no text — just reset
        _recognizer!.reset(_stream!);
        _currentPartial = '';
      }
    } catch (e) {
      if (_chunkCount % 200 == 0) {
        debugPrint('❌ [ASR] Process error: $e');
      }
    }
  }
  
  /// Force-flush any remaining partial text as a sentence
  String flushPartial() {
    if (_recognizer == null || _stream == null) return '';
    try {
      final result = _recognizer!.getResult(_stream!);
      final text = result.text.trim();
      if (text.isNotEmpty) {
        _recognizer!.reset(_stream!);
        _currentPartial = '';
        return text;
      }
    } catch (e) {
      debugPrint('Error flushing: $e');
    }
    return '';
  }
  
  void stopListening() {
    _isListening = false;
    _currentPartial = '';
    _chunkCount = 0;
    _safeNotify();
    debugPrint('🛑 ASR stopped');
  }
  
  /// Safely call notifyListeners only if not disposed
  void _safeNotify() {
    if (!_disposed && hasListeners) {
      try { notifyListeners(); } catch (_) {}
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    _isListening = false;
    _stream?.free();
    _recognizer?.free();
    super.dispose();
  }
}
