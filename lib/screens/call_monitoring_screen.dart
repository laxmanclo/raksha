import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:typed_data';
import '../services/call_service.dart';
import '../services/threat_service.dart';
import '../services/tts_service.dart';
import '../services/pii_service.dart';
import '../services/asr_service.dart';
import '../services/microphone_service.dart';
import '../widgets/threat_meter.dart';
import '../widgets/transcript_display.dart';
import '../widgets/takeover_buttons.dart';

// ignore: unused_import - Float32List used in callback type

class CallMonitoringScreen extends StatefulWidget {
  const CallMonitoringScreen({super.key});

  @override
  State<CallMonitoringScreen> createState() => _CallMonitoringScreenState();
}

class _CallMonitoringScreenState extends State<CallMonitoringScreen> {
  final TextEditingController _testInputController = TextEditingController();
  Timer? _analysisTimer;
  bool _useRealMicrophone = true;  // Default to real mic
  bool _isInitializingMicrophone = true;  // Start initializing immediately
  String _micStatus = 'Initializing...';
  
  // Store service references to avoid context access in dispose()
  late final MicrophoneService _micService;
  late final AsrService _asrService;
  late final CallService _callService;

  @override
  void initState() {
    super.initState();
    
    // Start call monitoring and auto-start microphone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store service references
      _micService = context.read<MicrophoneService>();
      _asrService = context.read<AsrService>();
      _callService = context.read<CallService>();
      
      _callService.startCall();
      
      // Initialize TTS
      TtsService.initialize();
      
      // Start periodic analysis (every 5 seconds)
      _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _performAnalysis();
      });
      
      // Auto-start microphone pipeline
      _startRealMicrophoneListening();
    });
  }

  @override
  void dispose() {
    _testInputController.dispose();
    _analysisTimer?.cancel();
    
    // Stop services using stored references (not context)
    _micService.stopRecording();
    _asrService.stopListening();
    _callService.endCall();
    
    super.dispose();
  }

  void _performAnalysis() {
    final callService = context.read<CallService>();
    final threatService = context.read<ThreatService>();
    
    final transcript = callService.getTranscriptText();
    if (transcript.isEmpty) return;
    
    final lines = callService.transcript.map((t) => t.text).toList();
    final contextLines = lines.length > 5 ? lines.sublist(lines.length - 5) : lines;
    
    threatService.analyzeText(
      transcript,
      contextLines,
      callService.callDuration.inSeconds,
    );
  }

  void _addTestTranscript() {
    if (_testInputController.text.isEmpty) return;
    
    final text = _testInputController.text;
    final cleaned = PiiService.stripPII(text);
    
    context.read<CallService>().addTranscriptLine(
      cleaned,
      isCleaned: PiiService.containsPII(text),
    );
    
    _testInputController.clear();
    
    // Trigger immediate analysis
    _performAnalysis();
  }

  Future<void> _startRealMicrophoneListening() async {
    debugPrint('\n🔴 [START] Starting Real Microphone Pipeline...');
    final micService = context.read<MicrophoneService>();
    final asrService = context.read<AsrService>();
    final callService = context.read<CallService>();
    
    try {
      // Step 1: Initialize ASR (Sherpa ONNX models)
      if (mounted) setState(() => _micStatus = 'Loading ASR models...');
      debugPrint('🎯 [STEP 1] Initializing ASR service...');
      await asrService.initialize();
      debugPrint('✅ [STEP 1] ASR initialized');
      
      // Define the transcript callback
      void onTranscript(String text) {
        debugPrint('📝 [TRANSCRIPT] Received: "$text"');
        final cleaned = PiiService.stripPII(text);
        callService.addTranscriptLine(
          cleaned,
          isCleaned: PiiService.containsPII(text),
        );
        _performAnalysis();
      }
      
      // Step 2: Start ASR listening
      if (mounted) setState(() => _micStatus = 'Starting ASR...');
      debugPrint('🎯 [STEP 2] Starting ASR listening...');
      await asrService.startListening(onTranscript);
      debugPrint('✅ [STEP 2] ASR listening');
      
      // Step 3: Start microphone with DIRECT callback to ASR
      // No broadcast stream — mic chunks go directly to ASR
      if (mounted) setState(() => _micStatus = 'Starting microphone...');
      debugPrint('🎯 [STEP 3] Starting microphone with direct ASR callback...');
      
      int chunkCount = 0;
      final started = await micService.startRecording(
        onAudioData: (Float32List audioData) {
          chunkCount++;
          if (chunkCount % 100 == 0) {
            debugPrint('📡 [PIPE] Chunk #$chunkCount → ASR (${audioData.length} samples)');
          }
          asrService.processAudioChunk(audioData, onTranscript);
        },
      );
      
      if (!started) {
        throw Exception('Microphone failed to start — check permissions in Settings');
      }
      
      debugPrint('✅ [STEP 3] Microphone recording active');
      debugPrint('🟢 Pipeline: Mic → PCM16 → Float32 → ASR → Transcript');
      
      if (mounted) {
        setState(() {
          _useRealMicrophone = true;
          _isInitializingMicrophone = false;
          _micStatus = 'Listening...';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎙️ Microphone active — speak now!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ERROR] Pipeline failed: $e');
      debugPrint('🔎 $stackTrace');
      if (mounted) {
        setState(() {
          _useRealMicrophone = false;
          _isInitializingMicrophone = false;
          _micStatus = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mic error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _stopRealMicrophoneListening() {
    context.read<MicrophoneService>().stopRecording();
    context.read<AsrService>().stopListening();
    
    if (mounted) {
      setState(() {
        _useRealMicrophone = false;
        _micStatus = 'Demo mode';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⌨️ Demo mode activated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Threat Meter
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ThreatMeter(),
            ),
            
            // Transcript Display
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TranscriptDisplay(),
              ),
            ),
            
            // AI Takeover Buttons
            const Padding(
              padding: EdgeInsets.all(24),
              child: TakeoverButtons(),
            ),
            
            // Test Input (for demo purposes)
            _buildTestInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<CallService>(
      builder: (context, callService, _) {
        final duration = callService.callDuration;
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1F33),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring Call',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: callService.isListening
                                ? Colors.red
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ).animate(
                          onPlay: (controller) => controller.repeat(),
                        ).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
                        const SizedBox(width: 8),
                        Text(
                          callService.isListening ? 'LIVE' : 'PAUSED',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: callService.isListening
                                ? Colors.red
                                : Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.robotoMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Toggle between Demo and Real Microphone
              IconButton(
                onPressed: _isInitializingMicrophone ? null : () async {
                  if (_useRealMicrophone) {
                    _stopRealMicrophoneListening();
                  } else {
                    setState(() => _isInitializingMicrophone = true);
                    await _startRealMicrophoneListening();
                  }
                },
                icon: _isInitializingMicrophone
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      )
                    : Icon(
                        _useRealMicrophone ? Icons.mic : Icons.keyboard,
                        color: _useRealMicrophone ? Colors.green : Colors.blue,
                      ),
                tooltip: _isInitializingMicrophone
                    ? 'Initializing...'
                    : (_useRealMicrophone ? 'Switch to Demo Mode' : 'Switch to Real Microphone'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isInitializingMicrophone
                        ? Icons.sync
                        : (_useRealMicrophone ? Icons.mic : Icons.keyboard),
                    color: _isInitializingMicrophone
                        ? Colors.orange
                        : (_useRealMicrophone ? Colors.green : Colors.blue),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isInitializingMicrophone
                        ? '⏳ Initializing...'
                        : (_useRealMicrophone ? '🎙️ Real Microphone' : '⌨️ Demo Mode'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E21),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'On-Device',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!_useRealMicrophone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testInputController,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type scam text here...',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0A0E21),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _addTestTranscript(),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _addTestTranscript,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickTest('Sir aapka Aadhaar card block hone wala hai'),
                _buildQuickTest('OTP batao urgent hai'),
                _buildQuickTest('Police se bol raha hun, arrest warrant hai'),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listening via microphone...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Audio → VAD → ASR → PII Strip (on-device)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickTest(String text) {
    return InkWell(
      onTap: () {
        _testInputController.text = text;
        _addTestTranscript();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
