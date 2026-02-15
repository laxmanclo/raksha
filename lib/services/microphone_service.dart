import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Microphone capture service for real-time audio streaming
/// Captures PCM audio at 16kHz for Sherpa ONNX processing
class MicrophoneService extends ChangeNotifier {
  bool _isRecording = false;
  StreamController<Float32List>? _audioStreamController;
  
  // Note: For production, you would use a plugin like:
  // - record: ^5.0.0
  // - audio_session: ^0.1.0
  // - flutter_sound: ^9.0.0
  // - microphone: ^0.3.0
  
  bool get isRecording => _isRecording;
  Stream<Float32List>? get audioStream => _audioStreamController?.stream;
  
  /// Request microphone permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        debugPrint('✅ Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        debugPrint('❌ Microphone permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('❌ Microphone permission permanently denied');
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');
      return false;
    }
  }
  
  /// Start capturing audio from microphone
  /// Audio is captured at 16kHz PCM format for Sherpa ONNX
  Future<bool> startRecording() async {
    if (_isRecording) return true;
    
    // Check permission first
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('❌ Cannot start recording without microphone permission');
      return false;
    }
    
    try {
      _audioStreamController = StreamController<Float32List>.broadcast();
      _isRecording = true;
      notifyListeners();
      
      debugPrint('🎙️ Microphone recording started');
      
      // TODO: In production, integrate actual microphone capture
      // Example with 'record' package:
      /*
      final recorder = Record();
      await recorder.start(
        path: null, // We want stream, not file
        encoder: AudioEncoder.pcm16bit,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      // Listen to audio stream
      recorder.onData.listen((data) {
        // Convert to Float32List and emit
        final float32Data = convertToFloat32(data);
        _audioStreamController?.add(float32Data);
      });
      */
      
      return true;
    } catch (e) {
      debugPrint('❌ Error starting microphone recording: $e');
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Stop capturing audio
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _isRecording = false;
      await _audioStreamController?.close();
      _audioStreamController = null;
      
      debugPrint('🛑 Microphone recording stopped');
      notifyListeners();
      
      // TODO: Stop actual recorder
      // await recorder.stop();
    } catch (e) {
      debugPrint('❌ Error stopping microphone recording: $e');
    }
  }
  
  /// Convert Int16 PCM data to Float32 for Sherpa ONNX
  Float32List convertInt16ToFloat32(Int16List int16Data) {
    final float32Data = Float32List(int16Data.length);
    for (int i = 0; i < int16Data.length; i++) {
      // Normalize from Int16 range [-32768, 32767] to Float32 range [-1.0, 1.0]
      float32Data[i] = int16Data[i] / 32768.0;
    }
    return float32Data;
  }
  
  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }
}
