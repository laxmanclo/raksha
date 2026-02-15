import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
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
      
      // Copy models from assets to filesystem first
      final modelPaths = await ModelManager.initializeModels();
      debugPrint('📁 Models loaded to filesystem');
      
      // Initialize Sherpa ONNX native bindings
      sherpa.initBindings();
      debugPrint('✅ Sherpa ONNX native bindings initialized');
      
      // Initialize streaming recognizer with filesystem paths
      final recognizerConfig = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: modelPaths['encoder']!,
            decoder: modelPaths['decoder']!,
            joiner: modelPaths['joiner']!,
          ),
          tokens: modelPaths['tokens']!,
          numThreads: 1,  // Reduced to 1 for stability
          provider: 'cpu',
          debug: false,  // Disable for stability
        ),
        decodingMethod: 'greedy_search',
        enableEndpoint: false,  // Disable endpoint detection for testing
        rule1MinTrailingSilence: 5.0,
        rule2MinTrailingSilence: 3.0,
        rule3MinUtteranceLength: 10.0,
      );
      
      debugPrint('📋 [ASR] Recognizer config: encoder=${modelPaths["encoder"]}');
      
      _recognizer = sherpa.OnlineRecognizer(recognizerConfig);
      _stream = _recognizer!.createStream();
      
      debugPrint('✅ Streaming ASR recognizer initialized');
      
      // Initialize VAD for speech detection with filesystem path
      final vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: modelPaths['vad']!,
          threshold: 0.3,  // Lowered from 0.5 for better detection
          minSilenceDuration: 0.3,  // Lowered from 0.5
          minSpeechDuration: 0.1,  // Lowered from 0.25 for faster detection
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
      
      debugPrint('✅ Silero VAD initialized (threshold: 0.3, min speech: 0.1s)');
      
      _isInitialized = true;
      if (hasListeners) {
        notifyListeners();
      }
      
      debugPrint('🎉 Sherpa ONNX fully initialized — on-device ASR ready');
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
    if (hasListeners) {
      notifyListeners();
    }
    
    debugPrint('🎙️ ASR listening started — ready to process audio chunks');
    debugPrint('✅ ASR listening');
    
    // Note: In production, integrate with microphone:
    // 1. Use a plugin like record, audio_session, or flutter_sound
    // 2. Capture PCM audio at 16kHz sample rate
    // 3. Feed chunks to processAudioChunk() below
    
    // For now, this acts as the processing pipeline ready to receive audio
  }
  
  /// Process audio chunk through VAD and ASR pipeline
  /// This is the core on-device processing - no network calls
  int _processedChunkCount = 0;
  int _audioSampleCount = 0;
  final List<double> _audioBuffer = [];  // Accumulate audio samples
  
  Future<void> processAudioChunk(
    Float32List samples,
    Function(String) onTranscript,
  ) async {
    if (!_isListening || _vad == null || _recognizer == null || _stream == null) {
      debugPrint('⚠️ [ASR] Skipping chunk - not listening or not initialized');
      return;
    }
    
    _processedChunkCount++;
    _audioSampleCount += samples.length;
    
    // Add samples to buffer
    _audioBuffer.addAll(samples);
    
    if (_processedChunkCount % 50 == 0) {
      debugPrint('🔊 [ASR] Buffer size: ${_audioBuffer.length} samples (${(_audioBuffer.length / 16000).toStringAsFixed(2)}s)');
    }
    
    // Process when we have at least 0.2 seconds of audio (3200 samples at 16kHz)
    if (_audioBuffer.length < 3200) {
      return;
    }
    
    try{
      // Validate audio samples
      if (_audioBuffer.isEmpty) {
        debugPrint('⚠️ [ASR] Empty buffer');
        return;
      }
      
      // Check audio range on first chunk
      if (_processedChunkCount == 10) {
        try {
          final minSample = _audioBuffer.reduce((a, b) => a < b ? a : b);
          final maxSample = _audioBuffer.reduce((a, b) => a > b ? a : b);
          debugPrint('🎵 [ASR] Audio range: [$minSample, $maxSample]');
        } catch (e) {
          debugPrint('⚠️ [ASR] Error checking audio range: $e');
        }
      }
      
      final Float32List bufferedSamples = Float32List.fromList(_audioBuffer);
      _audioBuffer.clear();  // Clear buffer after copying
      
      try {
        // Feed buffered audio to ASR
        _stream!.acceptWaveform(
          samples: bufferedSamples,
          sampleRate: 16000,
        );
      } catch (e) {
        debugPrint('❌ [ASR] Error in acceptWaveform: $e');
        _audioBuffer.clear();
        return;
      }
      
      try {
        // Decode the audio - must loop while isReady
        int decodeCount = 0;
        while (_recognizer!.isReady(_stream!)) {
          _recognizer!.decode(_stream!);
          decodeCount++;
        }
        if (_processedChunkCount % 50 == 0) {
          debugPrint('🔄 [ASR] Decoded $decodeCount frames, buffer processed');
        }
      } catch (e) {
        debugPrint('❌ [ASR] Error in decode: $e');
        _audioBuffer.clear();
        return;
      }
      
      // Get current result after decode
      try {
        final result = _recognizer!.getResult(_stream!);
        
        if (result.text.isNotEmpty) {
          debugPrint('✅ [ASR] Transcribed: "${result.text}"');
          onTranscript(result.text);
          
          // Reset stream to get new utterances
          _recognizer!.reset(_stream!);
          _audioSampleCount = 0;
        }
      } catch (e) {
        debugPrint('❌ [ASR] Error getting result: $e');
      }
      
      /* ORIGINAL VAD-BASED APPROACH - Commented out for testing
      // Step 1: VAD - Voice Activity Detection (on-device)
      // Only process if actual speech is detected (saves CPU & battery)
      _vad!.acceptWaveform(samples);
      
      if (_processedChunkCount % 50 == 0) {
        debugPrint('🔍 [VAD] Queue size: ${_vad!.isEmpty() ? "empty" : "has segments"}');
      }
      
      while (!_vad!.isEmpty()) {
        // Speech segment detected by VAD
        final segment = _vad!.front();
        debugPrint('🗣️ [VAD] Speech detected! Segment: ${segment.samples.length} samples');
        
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
          debugPrint('✅ [ASR] Transcribed (on-device): ${result.text}');
          onTranscript(result.text);
          _recognizer!.reset(_stream!);
        } else {
          debugPrint('⚠️ [ASR] Empty transcription result');
        }
        
        _vad!.pop();
      }
      */
    } catch (e) {
      debugPrint('❌ Error processing audio: $e');
    }
  }
  
  void stopListening() {
    _isListening = false;
    _audioBuffer.clear();  // Clear audio buffer
    _processedChunkCount = 0;
    _audioSampleCount = 0;
    debugPrint('🛑 Stopped ASR listening');
    if (hasListeners) {
      notifyListeners();
    }
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
