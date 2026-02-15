import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'dart:async';

/// Service for Sherpa ONNX ASR with Silero VAD
/// Fully on-device speech recognition - no data leaves the device
class AsrService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isListening = false;
  
  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  sherpa.VoiceActivityDetector? _vad;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  /// Initialize Sherpa ONNX with streaming ASR and VAD
  /// All processing happens on-device for maximum privacy
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🎙️ Initializing Sherpa ONNX ASR...');
      
      // Initialize streaming recognizer
      const recognizerConfig = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: 'assets/models/encoder.int8.onnx',
            decoder: 'assets/models/decoder.int8.onnx',
            joiner: 'assets/models/joiner.int8.onnx',
          ),
          tokens: 'assets/models/tokens.txt',
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
        decodingMethod: 'greedy_search',
        enableEndpoint: true,
        rule1MinTrailingSilence: 2.4,
        rule2MinTrailingSilence: 1.2,
        rule3MinUtteranceLength: 20.0,
      );
      
      _recognizer = sherpa.OnlineRecognizer(recognizerConfig);
      _stream = _recognizer!.createStream();
      
      debugPrint('✅ Recognizer initialized');
      
      // Initialize VAD for speech detection
      final vadConfig = sherpa.VadModelConfig(
        sileroVad: const sherpa.SileroVadModelConfig(
          model: 'assets/models/silero_vad.onnx',
          threshold: 0.5,
          minSilenceDuration: 0.5,
          minSpeechDuration: 0.25,
          windowSize: 512,
        ),
        sampleRate: 16000,
        numThreads: 1,
        provider: 'cpu',
        debug: false,
      );
      
      _vad = sherpa.VoiceActivityDetector(
        config: vadConfig,
        bufferSizeInSeconds: 60,
      );
      
      debugPrint('✅ VAD initialized');
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('🎉 Sherpa ONNX fully initialized - Ready for on-device ASR');
    } catch (e) {
      debugPrint('❌ Error initializing ASR: $e');
      debugPrint('💡 Make sure models are in assets/models/ directory');
      rethrow;
    }
  }
  
  /// Start listening and processing audio through VAD and ASR
  /// All processing is on-device - audio never leaves the phone
  Future<void> startListening(Function(String) onTranscript) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_recognizer == null || _vad == null || _stream == null) {
      throw Exception('ASR not properly initialized');
    }
    
    _isListening = true;
    notifyListeners();
    
    debugPrint('🎙️ Starting on-device ASR listening...');
    
    // Note: In production, integrate with microphone:
    // 1. Use a plugin like record, audio_session, or flutter_sound
    // 2. Capture PCM audio at 16kHz sample rate
    // 3. Feed chunks to processAudioChunk() below
    
    // For now, this acts as the processing pipeline ready to receive audio
  }
  
  /// Process audio chunk through VAD and ASR pipeline
  /// This is the core on-device processing - no network calls
  Future<void> processAudioChunk(
    Float32List samples,
    Function(String) onTranscript,
  ) async {
    if (!_isListening || _vad == null || _recognizer == null || _stream == null) {
      return;
    }
    
    try{
      // Step 1: VAD - Voice Activity Detection (on-device)
      // Only process if actual speech is detected (saves CPU & battery)
      _vad!.acceptWaveform(samples);
      
      while (!_vad!.isEmpty()) {
        // Speech segment detected by VAD
        final segment = _vad!.front();
        
        // Step 2: ASR - Speech Recognition (on-device)
        _stream!.acceptWaveform(
          samples: segment.samples,
          sampleRate: 16000,
        );
        
        // Decode the speech
        while (_recognizer!.isReady(_stream!)) {
          _recognizer!.decode(_stream!);
        }
        
        // Get result
        final result = _recognizer!.getResult(_stream!);
        
        if (result.text.isNotEmpty) {
          debugPrint('🎤 Transcribed (on-device): ${result.text}');
          onTranscript(result.text);
          _recognizer!.reset(_stream!);
        }
        
        _vad!.pop();
      }
    } catch (e) {
      debugPrint('❌ Error processing audio: $e');
    }
  }
  
  void stopListening() {
    _isListening = false;
    debugPrint('🛑 Stopped ASR listening');
    notifyListeners();
  }
  
  /// Get remaining partial result
  String getFinalResult() {
    if (_recognizer == null || _stream == null) return '';
    
    try {
      final result = _recognizer!.getResult(_stream!);
      return result.text;
    } catch (e) {
      debugPrint('Error getting final result: $e');
      return '';
    }
  }
  
  @override
  void dispose() {
    stopListening();
    
    // Clean up resources
    _stream?.free();
    _recognizer?.free();
    _vad?.free();
    
    debugPrint('🧹 ASR resources cleaned up');
    super.dispose();
  }
}
