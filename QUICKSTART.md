# Raksha - Quick Setup Guide

## 🚀 Quick Start (5 minutes)

### Step 1: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 2: Run in Demo Mode
```bash
flutter run
```

The app will run in **demo mode** without requiring Sherpa ONNX models. You can test the UI and functionality by typing text in the demo input.

### Step 3: Test the App

1. **Home Screen**: Tap "Start Monitoring"
2. **Call Monitoring**: Use the test input at bottom
3. **Try these test phrases**:
   - `Police se bol raha hun, arrest warrant hai`
   - `Sir aapka account block hona wala hai. OTP batao`
   - `Main CBI officer hun. Urgent action required`

4. **Watch the threat meter** climb
5. **See AI Takeover buttons** appear when threat is critical
6. **Tap a takeover mode** to hear AI response (TTS)

## 📱 Running on Physical Device

### Android
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Enable USB Debugging on Android:
1. Settings → About Phone
2. Tap "Build Number" 7 times
3. Settings → Developer Options
4. Enable "USB Debugging"

## 🎯 Features You Can Test Now

✅ **Working without models**:
- Beautiful UI with animations
- Threat meter visualization
- Live transcript display
- PII stripping (type "9876543210" and see it become [PHONE])
- AI Takeover buttons
- TTS voice output
- Threat analysis (keyword-based demo mode)

❌ **Requires models** (optional):
- Real-time speech recognition
- Actual call monitoring
- VAD (Voice Activity Detection)

## 🔧 Troubleshooting

### "flutter not found"
```bash
# Add Flutter to PATH
# Windows: Add C:\path\to\flutter\bin to PATH
# Mac/Linux: export PATH="$PATH:/path/to/flutter/bin"
```

### "SDK not found"
```bash
flutter doctor
```

### "Gradle build failed"
1. Open Android Studio
2. File → Project Structure
3. Set Android SDK location
4. Rebuild

### Dependencies issue
```bash
flutter clean
flutter pub get
```

## 🎨 Customization

### Change Colors
Edit [lib/main.dart](lib/main.dart):
```dart
primaryColor: const Color(0xFF6C63FF), // Your color here
```

### Change Backend URL
Edit [lib/services/api_service.dart](lib/services/api_service.dart):
```dart
static const String baseUrl = 'https://your-backend.com';
```

### Add More Test Phrases
Edit [lib/screens/call_monitoring_screen.dart](lib/screens/call_monitoring_screen.dart):
```dart
_buildQuickTest('Your custom scam phrase here'),
```

## 📦 Adding Sherpa ONNX Models (Optional)

### Download Models
1. Visit: https://github.com/k2-fsa/sherpa-onnx/releases
2. Download Hindi/Multilingual Zipformer model
3. Extract to `assets/models/`

### Implement ASR
Edit [lib/services/asr_service.dart](lib/services/asr_service.dart) and uncomment the TODOs.

## 🏗️ Build Release APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## 📊 Performance Tips

- Use `flutter run --release` for better performance
- Enable hardware acceleration on emulator
- Test on real device for accurate TTS

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| TTS not working | Check volume, restart app |
| UI lag | Run in release mode |
| Can't find pubspec.yaml | Run from project root |
| Gradle errors | Update Android SDK |

## 🎯 Demo Script for Hackathon

```
1. "₹25 billion stolen through digital arrest scams"
2. Show Home Screen stats
3. Tap "Start Monitoring"
4. Type: "Police se bol raha hun, CBI officer"
5. Watch threat meter climb
6. Type: "OTP batao urgent"
7. Show CRITICAL alert
8. Tap "Interrogate"
9. AI speaks in Hindi
10. "Audio stays on device, only text sent to cloud"
```

## 📚 Next Steps

1. ✅ Get the UI running
2. ⬜ Set up Replit backend
3. ⬜ Download Sherpa ONNX models
4. ⬜ Integrate real ASR
5. ⬜ Test end-to-end flow
6. ⬜ Practice demo pitch

## 🤝 Team Workflow

**P1 (Frontend)**: This code is ready! Test the UI.  
**P2 (Backend)**: Set up Replit with Claude API.  
**P3 (Models)**: Download and test Sherpa ONNX models.

## 💬 Support

Stuck? Check:
- README.md (detailed docs)
- Flutter docs: https://docs.flutter.dev
- Sherpa ONNX: https://k2-fsa.github.io/sherpa/onnx/

---

**You're all set!** Run `flutter run` and start testing! 🚀
