import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Microphone capture service for real-time audio streaming
/// Captures PCM audio at 16kHz for Sherpa ONNX processing
class MicrophoneService extends ChangeNotifier {
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _recordingSubscription;
  
  bool get isRecording => _isRecording;
  
  /// Start capturing audio from microphone with a direct callback.
  /// [onAudioData] is called for every audio chunk as Float32List,
  /// piped directly — no intermediate stream.
  Future<bool> startRecording({
    required void Function(Float32List) onAudioData,
  }) async {
    debugPrint('🎤 [MIC] startRecording() called');
    
    if (_isRecording) {
      debugPrint('⚠️ [MIC] Already recording, returning true');
      return true;
    }
    
    try {
      // Use record package's own permission check — avoids conflict
      // with permission_handler requesting the same permission
      debugPrint('🔐 [MIC] Checking recorder permission...');
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        debugPrint('❌ [MIC] Recorder permission denied');
        return false;
      }
      debugPrint('✅ [MIC] Recorder permission granted');
      
      // Start recording with streaming
      debugPrint('🎙️ [MIC] Starting recorder stream...');
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
      );
      debugPrint('✅ [MIC] Recorder stream started');
      
      // Listen to audio stream, convert, and call back directly
      int chunkCount = 0;
      _recordingSubscription = stream.listen(
        (Uint8List chunk) {
          try {
            if (chunk.isEmpty) return;
            chunkCount++;
            
            // Copy to a fresh buffer to ensure proper byte alignment
            final alignedBytes = Uint8List.fromList(chunk);
            
            // Make sure we have an even number of bytes for Int16
            final usableLength = alignedBytes.length - (alignedBytes.length % 2);
            if (usableLength < 2) return;
            
            // Convert Uint8List (raw bytes) to Int16List (PCM16)
            final int16Data = Int16List.view(
              alignedBytes.buffer,
              0,
              usableLength ~/ 2,
            );
            
            // Convert Int16 to Float32 for Sherpa ONNX
            final float32Data = _convertInt16ToFloat32(int16Data);
            
            // Direct callback — no broadcast stream intermediary
            onAudioData(float32Data);
            
            // Log every 50 chunks
            if (chunkCount % 50 == 0) {
              debugPrint('🎤 [MIC] Chunk #$chunkCount: ${chunk.length} bytes → ${float32Data.length} samples');
            }
          } catch (e) {
            debugPrint('❌ [MIC ERROR] Processing chunk: $e');
          }
        },
        onError: (e) {
          debugPrint('❌ [MIC STREAM ERROR] $e');
        },
        onDone: () {
          debugPrint('🏁 [MIC] Recording stream done');
        },
      );
      
      _isRecording = true;
      if (hasListeners) notifyListeners();
      
      debugPrint('✅ Microphone recording active (16kHz, PCM16, mono)');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting microphone recording: $e');
      _isRecording = false;
      if (hasListeners) notifyListeners();
      return false;
    }
  }
  
  /// Stop capturing audio
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _isRecording = false;
      
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;
      
      await _recorder.stop();
      
      debugPrint('🛑 Microphone recording stopped');
      if (hasListeners) notifyListeners();
    } catch (e) {
      debugPrint('❌ Error stopping microphone recording: $e');
    }
  }
  
  /// Convert Int16 PCM data to Float32 for Sherpa ONNX
  Float32List _convertInt16ToFloat32(Int16List int16Data) {
    final float32Data = Float32List(int16Data.length);
    for (int i = 0; i < int16Data.length; i++) {
      float32Data[i] = int16Data[i] / 32768.0;
    }
    return float32Data;
  }
  
  @override
  void dispose() {
    stopRecording();
    _recorder.dispose();
    super.dispose();
  }
}
