# Raksha - AI-Powered Scam Call Detection

🛡️ **Protect yourself from scam calls with on-device AI**

Raksha is a Flutter-based mobile app that detects and prevents scam calls in real-time using on-device speech recognition and cloud-based AI analysis. Built for the Raksha Hackathon.

## 🌟 Features

- **🔒 Privacy-First**: All audio processing happens on-device using Sherpa ONNX
- **🤖 AI-Powered Detection**: Claude Haiku analyzes conversation patterns for scam indicators
- **⚡ Real-Time Analysis**: Live transcription with threat scoring
- **🎯 Smart PII Protection**: Automatic redaction of sensitive information before transmission
- **🛡️ AI Takeover**: Three response modes to handle scammers:
  - **Shield**: Clean exit strategy
  - **Interrogate**: Expose the scammer
  - **Siren**: Scare them away

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Microphone│────>│ Silero VAD   │────>│Sherpa ONNX  │
│   (Audio)   │     │ (On-device)  │     │ ASR (Hindi/│
└─────────────┘     └──────────────┘     │  English)  │
                                          └──────┬──────┘
                                                 │ transcript
                                          ┌──────▼──────┐
                                          │ PII Stripper│
                                          │ (On-device) │
                                          └──────┬──────┘
                                                 │ clean text
                                          ┌──────▼──────┐
                                          │   Replit   │
                                          │  Backend   │
                                          └──────┬──────┘
                                                 │ analysis
                                          ┌──────▼──────┐
                                          │   Claude    │
                                          │   Haiku     │
                                          └─────────────┘
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode
- Dart SDK
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd raksha
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Download Sherpa ONNX Models**
   
   Create an `assets/models/` directory and download the following:
   
   - **Zipformer Streaming ASR Model** (for Hindi/English)
     - `encoder.int8.onnx`
     - `decoder.int8.onnx`
     - `joiner.int8.onnx`
     - `tokens.txt`
   
   - **Silero VAD Model** (bundled with sherpa_onnx)
     - `silero_vad.onnx`
   
   Download from: [Sherpa ONNX Model Zoo](https://github.com/k2-fsa/sherpa-onnx/releases)

4. **Update Backend URL**
   
   In `lib/services/api_service.dart`, update the Replit backend URL:
   ```dart
   static const String baseUrl = 'https://your-replit-project.repl.co';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage

### Demo Mode (Without Models)

The app includes a **demo mode** that works without Sherpa ONNX models:

1. Launch the app
2. Tap "Start Monitoring"
3. Use the test input at the bottom to type scam phrases
4. Watch the threat meter react in real-time
5. Try quick test buttons for common scam patterns

### Production Mode (With Models)

1. Download and place models in `assets/models/`
2. Implement actual Sherpa ONNX integration in `lib/services/asr_service.dart`
3. Grant microphone permissions
4. Start a call and enable monitoring
5. AI analyzes speech in real-time

## 🎨 UI Components

### Home Screen
- Feature overview
- Stats showcase
- Quick start button

### Call Monitoring Screen
- **Threat Meter**: Visual threat score (0-100)
- **Live Transcript**: Real-time speech-to-text
- **Technique Tags**: Detected scam techniques (AUTHORITY, URGENCY, FEAR, etc.)
- **AI Takeover Buttons**: Three response modes

## 🔧 Configuration

### pubspec.yaml Dependencies

```yaml
dependencies:
  sherpa_onnx: ^1.10.0       # ASR + VAD
  flutter_tts: ^4.0.0        # Hindi TTS
  http: ^1.2.0               # API calls
  permission_handler: ^11.0.0 # Permissions
  google_fonts: ^6.0.0       # Typography
  flutter_animate: ^4.5.0    # Animations
  provider: ^6.1.0           # State management
```

### Android Permissions

The following permissions are declared in `AndroidManifest.xml`:
- `RECORD_AUDIO` - For microphone access
- `INTERNET` - For backend communication
- `READ_PHONE_STATE` - For call detection
- `READ_CALL_LOG` - For call history

## 🧪 Testing

### Quick Test Phrases (Hindi/English Mix)

1. **Digital Arrest Scam**
   ```
   Police se bol raha hun, arrest warrant hai
   ```

2. **OTP Fraud**
   ```
   Sir aapka account block hona wala hai. OTP batao urgent
   ```

3. **Authority Impersonation**
   ```
   Main CBI se bol raha hun. Aapke account mein suspicious activity hai
   ```

## 🔐 Privacy & Security

- ✅ **Audio stays on device** - No raw audio transmitted
- ✅ **PII stripping** - Aadhaar, phone numbers, OTPs redacted before transmission
- ✅ **Minimal data** - Only anonymized text sent to cloud
- ✅ **Open source** - Full transparency

### PII Detection Patterns

The app automatically detects and redacts:
- Aadhaar numbers (12 digits)
- Phone numbers (+91 format)
- Credit/Debit cards (16 digits)
- OTP codes (4-6 digits)
- UPI IDs
- Bank account numbers
- PAN cards

## 🎯 Threat Detection

Claude Haiku analyzes conversations for:

### Scam Types
- `DIGITAL_ARREST` - Fake police/legal threats
- `OTP_FRAUD` - Demanding one-time passwords
- `KYC_SCAM` - Fake KYC updates
- `PRIZE_SCAM` - Lottery/prize frauds
- `INVESTMENT_FRAUD` - Fake investment schemes

### Manipulation Techniques
- `AUTHORITY` - Impersonating officials
- `URGENCY` - Creating time pressure
- `FEAR` - Threats and intimidation
- `ISOLATION` - Preventing verification
- `FINANCIAL_DEMAND` - Asking for money/credentials

## 📊 Threat Levels

| Score | Level | Color | Action |
|-------|-------|-------|--------|
| 0-30 | NONE/LOW | Green/Yellow | Normal conversation |
| 31-50 | MEDIUM | Orange | Monitor closely |
| 51-70 | HIGH | Red-Orange | Likely scam |
| 71-100 | CRITICAL | Red | **AI Takeover Available** |

## 🤖 AI Takeover Modes

When a threat is detected (score ≥ 71), activate AI takeover:

### 🛡️ Shield Mode
**Purpose**: Clean exit  
**Example**: "Main khud bank ki official website se call karunga. Goodbye."

### 🔍 Interrogate Mode
**Purpose**: Expose the scammer  
**Example**: "Aapka employee ID bataiye. Main head office se verify karunga."

### 🚨 Siren Mode
**Purpose**: Scare them off  
**Example**: "Fraud call detect ho gayi hai. Number trace ho raha hai. 1930 pe report ho rahi hai."

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── threat_model.dart     # Data models
├── screens/
│   ├── home_screen.dart      # Home page
│   └── call_monitoring_screen.dart  # Main monitoring UI
├── services/
│   ├── api_service.dart      # Backend API
│   ├── asr_service.dart      # Speech recognition
│   ├── call_service.dart     # Call state management
│   ├── pii_service.dart      # PII detection/stripping
│   ├── threat_service.dart   # Threat analysis
│   └── tts_service.dart      # Text-to-speech
└── widgets/
    ├── threat_meter.dart     # Threat score visualization
    ├── transcript_display.dart  # Live transcript UI
    └── takeover_buttons.dart # AI takeover controls
```

### State Management

Uses **Provider** for reactive state:
- `CallService` - Call state, transcript, duration
- `ThreatService` - Threat analysis, history

## 🚧 TODO / Future Enhancements

- [ ] Implement actual Sherpa ONNX integration in `asr_service.dart`
- [ ] Add call recording with user consent
- [ ] Implement automated call blocking
- [ ] Add offline threat detection (on-device ML model)
- [ ] Support more Indian languages (Tamil, Telugu, Bengali)
- [ ] Add call history with threat reports
- [ ] Implement community scam number database
- [ ] Add parent mode for elderly protection

## 📝 Backend Setup

See the backend repository for Node.js/Express setup with Claude integration.

Required endpoint: `POST /api/analyze`

**Request:**
```json
{
  "text": "cleaned transcript",
  "context": ["line1", "line2"],
  "call_duration_sec": 120
}
```

**Response:**
```json
{
  "threat_score": 82,
  "threat_level": "CRITICAL",
  "techniques": ["AUTHORITY", "URGENCY"],
  "is_alert": true,
  "scam_type": "OTP_FRAUD",
  "explanation": "...",
  "takeover_scripts": {
    "shield": "...",
    "interrogate": "...",
    "siren": "..."
  }
}
```

## 🤝 Contributing

Built for Raksha Hackathon by Team [Your Team Name]

## 📄 License

MIT License - See LICENSE file

## 🙏 Acknowledgments

- Sherpa ONNX for on-device ASR
- Anthropic Claude for threat analysis
- Replit for backend hosting
- Flutter community

## 📞 Support

For issues or questions, please open a GitHub issue.

---

**⚠️ Important**: This is a hackathon project and should be thoroughly tested before production use. Always verify suspicious calls through official channels.
