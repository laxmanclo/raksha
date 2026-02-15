# Raksha Models Directory

Place your Sherpa ONNX models here:

## Required Models

### 1. Zipformer Streaming ASR (Hindi/English)
Download from: https://github.com/k2-fsa/sherpa-onnx/releases

Required files:
- `encoder.int8.onnx`
- `decoder.int8.onnx`
- `joiner.int8.onnx`
- `tokens.txt`

### 2. Silero VAD Model
- `silero_vad.onnx` (usually bundled with sherpa_onnx package)

## Model Size Considerations

- INT8 quantized models: ~15-50MB
- Optimized for mobile devices
- Good balance of accuracy and performance

## Installation

1. Download the models from the Sherpa ONNX releases
2. Place them in this directory
3. Ensure filenames match exactly as listed above
4. The app will automatically load them from `assets/models/`

## Model Zoo

Visit: https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models

Look for:
- Multilingual models supporting Hindi
- Streaming (online) transducer models
- INT8 quantized versions for mobile

## Note

Models are excluded from git due to size. Each team member needs to download them separately.
