import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Manages copying ONNX model files from Flutter assets to the filesystem.
/// Sherpa ONNX requires actual filesystem paths (not asset bundle paths),
/// so we copy models from assets/ to the app's documents directory on first launch.
class ModelManager {
  static String? _modelsDir;

  /// Get or create the models directory in the app's documents folder
  static Future<String> getModelsDirectory() async {
    if (_modelsDir != null) return _modelsDir!;

    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/sherpa_models');

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    _modelsDir = modelsDir.path;
    return _modelsDir!;
  }

  /// Copy a single asset file to the filesystem. Skips if already exists.
  static Future<String> copyAssetToFile(
    String assetPath,
    String fileName,
  ) async {
    final modelsDir = await getModelsDirectory();
    final filePath = '$modelsDir/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      debugPrint('✅ Model already cached: $fileName');
      return filePath;
    }

    try {
      debugPrint('📦 Copying model to filesystem: $fileName');
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      debugPrint(
        '✅ Model copied: $fileName (${(data.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
      return filePath;
    } catch (e) {
      debugPrint('❌ Failed to copy model $fileName: $e');
      rethrow;
    }
  }

  /// Copy all required model files from assets to filesystem.
  /// Returns a map of model name -> filesystem path.
  static Future<Map<String, String>> initializeModels() async {
    debugPrint('🔄 Initializing ONNX models...');

    final paths = <String, String>{};

    // Streaming ASR model files (Zipformer transducer)
    paths['encoder'] = await copyAssetToFile(
      'assets/models/encoder.int8.onnx',
      'encoder.int8.onnx',
    );
    paths['decoder'] = await copyAssetToFile(
      'assets/models/decoder.onnx',
      'decoder.onnx',
    );
    paths['joiner'] = await copyAssetToFile(
      'assets/models/joiner.int8.onnx',
      'joiner.int8.onnx',
    );
    paths['tokens'] = await copyAssetToFile(
      'assets/models/tokens.txt',
      'tokens.txt',
    );

    // Silero VAD model
    paths['vad'] = await copyAssetToFile(
      'assets/models/silero_vad.onnx',
      'silero_vad.onnx',
    );

    debugPrint('🎉 All models initialized');
    return paths;
  }

  /// Check if all required models exist in assets.
  /// Returns list of missing model filenames.
  static Future<List<String>> checkMissingModels() async {
    final required = [
      'assets/models/encoder.int8.onnx',
      'assets/models/decoder.onnx',
      'assets/models/joiner.int8.onnx',
      'assets/models/tokens.txt',
      'assets/models/silero_vad.onnx',
    ];

    final missing = <String>[];
    for (final asset in required) {
      try {
        await rootBundle.load(asset);
      } catch (_) {
        missing.add(asset.split('/').last);
      }
    }
    return missing;
  }

  /// Clear cached models (e.g. for model updates)
  static Future<void> clearCache() async {
    final modelsDir = await getModelsDirectory();
    final dir = Directory(modelsDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _modelsDir = null;
      debugPrint('🧹 Model cache cleared');
    }
  }
}
