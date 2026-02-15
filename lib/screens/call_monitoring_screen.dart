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
import '../services/api_service.dart';
import '../models/threat_model.dart';
import '../widgets/voice_orb.dart';

// ── Interactive Demo Scenarios ──
// The scammer speaks these via TTS. The user responds naturally.
// Threat analysis runs on the scammer text (guaranteed accurate).

class DemoLine {
  final String text;
  final double pauseAfterSec; // how long to wait for user response
  const DemoLine(this.text, {this.pauseAfterSec = 5.0});
}

class DemoScenario {
  final String title;
  final String callerName;
  final List<DemoLine> lines;
  const DemoScenario({required this.title, required this.callerName, required this.lines});
}

final kDemoScenarios = {
  'banking': DemoScenario(
    title: 'Banking Fraud',
    callerName: 'SBI Caller',
    lines: [
      DemoLine('Hello sir, I am calling from State Bank of India head office. Am I speaking with the account holder?', pauseAfterSec: 5),
      DemoLine('Sir, we have detected suspicious activity on your bank account. There have been two unauthorized transactions from your account today.', pauseAfterSec: 5),
      DemoLine('For security verification, I need to confirm your identity. Can you please tell me your Aadhaar card number?', pauseAfterSec: 6),
      DemoLine('Sir, I also need your account PIN number to verify that you are the real account holder.', pauseAfterSec: 6),
      DemoLine('An OTP has been sent to your registered mobile number. Please share that OTP with me right now for verification.', pauseAfterSec: 6),
      DemoLine('Sir, this is very urgent. If you do not verify in the next 2 minutes, your account will be permanently blocked and all your money will be frozen.', pauseAfterSec: 5),
      DemoLine('I am sending you a secure link right now. Please click on it and enter your net banking password immediately to stop the fraud.', pauseAfterSec: 5),
      DemoLine('Sir, to reverse the unauthorized transaction, you need to transfer a verification amount of 10,000 rupees to our secure RBI account right now.', pauseAfterSec: 5),
    ],
  ),
  'tech_support': DemoScenario(
    title: 'Tech Support Scam',
    callerName: 'Microsoft Support',
    lines: [
      DemoLine('Hello, this is the Microsoft Windows Technical Support department. We are calling regarding a critical security alert on your computer.', pauseAfterSec: 5),
      DemoLine('Sir, our systems have detected a very dangerous virus on your computer. Hackers are currently stealing your personal data and bank passwords.', pauseAfterSec: 5),
      DemoLine('Your Windows license has been compromised. We are seeing active unauthorized access to your system right now from a foreign IP address.', pauseAfterSec: 5),
      DemoLine('I need you to download TeamViewer remote access software immediately so our technician can fix this critical issue.', pauseAfterSec: 6),
      DemoLine('Please give me remote access to your computer. I will remove the virus and secure your system.', pauseAfterSec: 6),
      DemoLine('Sir, your computer is very badly infected. I can see that hackers are accessing your bank details and transferring money at this very moment.', pauseAfterSec: 5),
      DemoLine('To fix this permanently, you must purchase our premium lifetime security package. It costs only 15,000 rupees.', pauseAfterSec: 5),
      DemoLine('Please share your credit card number and CVV right now. If you do not pay immediately, the hackers will empty your entire bank account within 24 hours.', pauseAfterSec: 5),
    ],
  ),
};

class CallMonitoringScreen extends StatefulWidget {
  /// Pass a demo scenario key ('banking' or 'tech_support') for interactive demo.
  /// Pass null for real microphone mode.
  final String? demoScenario;
  
  const CallMonitoringScreen({super.key, this.demoScenario});

  @override
  State<CallMonitoringScreen> createState() => _CallMonitoringScreenState();
}

class _CallMonitoringScreenState extends State<CallMonitoringScreen> {
  Timer? _analysisTimer;
  bool _isInitializing = true;
  bool _pipelineActive = false;
  bool _disposed = false;
  String _status = 'Starting...';
  int _demoLineIndex = 0;
  bool _demoRunning = false;
  bool _autoTakeoverTriggered = false;
  final ScrollController _scrollController = ScrollController();
  
  late final MicrophoneService _micService;
  late final AsrService _asrService;
  late final CallService _callService;
  late final ThreatService _threatService;

  bool get _isDemoMode => widget.demoScenario != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _micService = context.read<MicrophoneService>();
      _asrService = context.read<AsrService>();
      _callService = context.read<CallService>();
      _threatService = context.read<ThreatService>();

      _callService.startCall();
      TtsService.initialize();
      
      if (_isDemoMode) {
        _initInteractiveDemo();
      } else {
        _initPipeline();
      }
    });
  }

  // ── Interactive Demo ──
  Future<void> _initInteractiveDemo() async {
    if (_disposed) return;
    
    try {
      setState(() => _status = 'Connecting...');
      await ApiService.startSession();
      
      if (!_disposed) setState(() => _status = 'Loading ASR...');
      await _asrService.initialize();
      await _asrService.startListening(
        onSentence: (text) {
          if (_disposed) return;
          final cleaned = PiiService.stripPII(text);
          _callService.addTranscriptLine(cleaned, isCleaned: PiiService.containsPII(text));
          _scrollToBottom();
        },
        onPartial: (partial) {
          if (_disposed) return;
          _callService.updateLivePartial(partial);
        },
      );
      
      if (!_disposed) setState(() => _status = 'Starting mic...');
      await _micService.startRecording(
        onAudioData: (Float32List data) {
          if (!_disposed) {
            // ── Gate: skip mic input while TTS is playing (prevents echo) ──
            if (TtsService.isSpeakingOrEcho) return;
            _asrService.processAudioChunk(data, (text) {
              if (_disposed) return;
              final cleaned = PiiService.stripPII(text);
              _callService.addTranscriptLine(cleaned, isCleaned: PiiService.containsPII(text));
              _scrollToBottom();
            });
          }
        },
      );
      
      if (_disposed) return;
      setState(() {
        _isInitializing = false;
        _pipelineActive = true;
        _status = 'Demo active';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      _runDemoScript();
      
    } catch (e) {
      debugPrint('❌ Demo init error: $e');
      if (mounted && !_disposed) {
        setState(() {
          _isInitializing = false;
          _pipelineActive = true;
          _status = 'Demo (ASR unavailable)';
        });
        await Future.delayed(const Duration(seconds: 1));
        _runDemoScript();
      }
    }
  }
  
  Future<void> _runDemoScript() async {
    final scenario = kDemoScenarios[widget.demoScenario];
    if (scenario == null || _disposed) return;
    
    _demoRunning = true;
    
    for (int i = 0; i < scenario.lines.length; i++) {
      if (_disposed || _autoTakeoverTriggered) break;
      
      _demoLineIndex = i;
      final line = scenario.lines[i];
      
      final cleaned = PiiService.stripPII(line.text);
      _callService.addTranscriptLine(
        cleaned,
        isCleaned: PiiService.containsPII(line.text),
        isScammer: true,
      );
      _scrollToBottom();
      
      debugPrint('🔊 [DEMO] Scammer line ${i+1}: "${line.text.substring(0, 40)}..."');
      await TtsService.speakAsScammer(line.text);
      
      if (_disposed || _autoTakeoverTriggered) break;
      
      _sendToBackend();
      
      await Future.delayed(Duration(milliseconds: (line.pauseAfterSec * 1000).toInt()));
      
      if (_disposed || _autoTakeoverTriggered) break;
    }
    
    // If takeover fired mid-script, stop the scammer's TTS immediately
    if (_autoTakeoverTriggered) {
      await TtsService.stop();
      debugPrint('🛑 [DEMO] Script halted — AI takeover active');
    }
    
    _demoRunning = false;
    debugPrint('✅ [DEMO] Script finished');
  }

  // ── Real mic pipeline ──
  Future<void> _initPipeline() async {
    try {
      if (!mounted) return;
      setState(() => _status = 'Connecting to backend...');
      await ApiService.startSession();
      
      if (_disposed) return;
      setState(() => _status = 'Loading AI models...');
      await _asrService.initialize();
      
      if (_disposed) return;
      setState(() => _status = 'Starting speech recognition...');
      await _asrService.startListening(
        onSentence: _onSentence,
        onPartial: _onPartial,
      );
      
      if (_disposed) return;
      setState(() => _status = 'Starting microphone...');
      final started = await _micService.startRecording(
        onAudioData: (Float32List data) {
          if (!_disposed) {
            _asrService.processAudioChunk(data, _onSentence);
          }
        },
      );
      
      if (!started) throw Exception('Microphone permission denied');
      
      _analysisTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        _sendToBackend();
      });
      
      if (_disposed) return;
      setState(() {
        _isInitializing = false;
        _pipelineActive = true;
        _status = 'Listening';
      });
    } catch (e) {
      debugPrint('❌ Pipeline error: $e');
      if (mounted && !_disposed) {
        setState(() {
          _isInitializing = false;
          _pipelineActive = false;
          _status = 'Error: $e';
        });
      }
    }
  }
  
  void _onSentence(String text) {
    if (_disposed) return;
    final cleaned = PiiService.stripPII(text);
    _callService.addTranscriptLine(cleaned, isCleaned: PiiService.containsPII(text));
    _sendToBackend();
    _scrollToBottom();
  }
  
  void _onPartial(String partial) {
    if (_disposed) return;
    _callService.updateLivePartial(partial);
  }
  
  void _sendToBackend() {
    if (_disposed) return;
    final transcript = _callService.getTranscriptText();
    if (transcript.isEmpty) return;
    
    final lines = _callService.transcript.map((t) => t.text).toList();
    final recentLines = lines.length > 5 ? lines.sublist(lines.length - 5) : lines;
    
    _threatService.analyzeText(
      transcript, recentLines, _callService.callDuration.inSeconds,
    ).then((_) {
      // ── Auto-dispatch takeover in demo mode ──
      if (!_isDemoMode || _disposed || _autoTakeoverTriggered) return;
      final analysis = _threatService.currentAnalysis;
      if (analysis != null && analysis.threatLevel == 'CRITICAL') {
        setState(() => _autoTakeoverTriggered = true);
        debugPrint('🚨 [DEMO] Auto-dispatching Siren takeover (CRITICAL detected)');
        // Small delay so the threat banner UI updates first
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!_disposed && mounted) _activateTakeover('siren');
        });
      }
    });
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _activateTakeover(String mode) async {
    await TtsService.stop();
    final script = await ApiService.getTakeoverScript(mode);
    if (!mounted) return;
    
    // ignore: unused_local_variable
    final sheetController = showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mode == 'shield' ? Icons.shield : mode == 'interrogate' ? Icons.search : Icons.campaign,
                  color: mode == 'shield' ? const Color(0xFF34C759) : mode == 'interrogate' ? Colors.amber : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  mode == 'shield' ? 'Shield Mode' : mode == 'interrogate' ? 'Interrogate' : 'Siren Mode',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_isDemoMode) ...[
                  const Spacer(),
                  Text('AUTO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF34C759), letterSpacing: 1)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                script,
                style: GoogleFonts.inter(fontSize: 15, color: Colors.white, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  TtsService.speakAsAgent(script);
                },
                icon: const Icon(Icons.volume_up),
                label: Text(
                  _isDemoMode ? 'AI Speaking...' : 'Speak Now',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    
    // ── Demo mode: auto-speak and auto-dismiss ──
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || _disposed) return;
      TtsService.speakAsAgent(script).then((_) {
        // Dismiss the sheet after TTS finishes
        if (mounted && !_disposed && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _analysisTimer?.cancel();
    _scrollController.dispose();
    TtsService.stop();
    
    final mic = _micService;
    final asr = _asrService;
    final call = _callService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mic.stopRecording(silent: true);
      asr.stopListening();
      call.endCall(silent: true);
      ApiService.endSession();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildThreatBanner(),
            // Voice Orb
            const SizedBox(
              height: 200,
              child: Center(child: VoiceOrb()),
            ),
            Expanded(child: _buildTranscript()),
            _buildTakeoverBar(),
            _buildBottomStatus(),
          ],
        ),
      ),
    );
  }
  
  // ── Top Bar ──
  Widget _buildTopBar() {
    return Consumer<CallService>(
      builder: (context, cs, _) {
        final m = cs.callDuration.inMinutes.toString().padLeft(2, '0');
        final s = (cs.callDuration.inSeconds % 60).toString().padLeft(2, '0');
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              // Pulsing dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _pipelineActive ? const Color(0xFF34C759) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
              const SizedBox(width: 8),
              Text(
                _isDemoMode ? 'DEMO' : (_pipelineActive ? 'LIVE' : 'PAUSED'),
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: _isDemoMode ? const Color(0xFF34C759) : (_pipelineActive ? const Color(0xFF34C759) : Colors.grey),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '$m:$s',
                style: GoogleFonts.robotoMono(
                  fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // ── Threat Banner ──
  Widget _buildThreatBanner() {
    return Consumer<ThreatService>(
      builder: (context, ts, _) {
        final a = ts.currentAnalysis;
        if (a == null) {
          return const SizedBox(height: 8);
        }
        
        final color = a.threatColor;
        final isAlert = a.isAlert;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isAlert ? color.withValues(alpha: 0.15) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4), width: isAlert ? 1.5 : 0.5),
          ),
          child: Row(
            children: [
              // Score
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    '${a.threatScore}',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Level + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          a.threatLevel,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
                        ),
                        if (a.scamType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              a.scamType!.replaceAll('_', ' '),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (a.techniques.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          a.techniques.join(' · '),
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (isAlert)
                Icon(Icons.warning_amber_rounded, color: color, size: 24)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
            ],
          ),
        );
      },
    );
  }
  
  // ── Transcript ──
  Widget _buildTranscript() {
    final scenario = _isDemoMode ? kDemoScenarios[widget.demoScenario] : null;
    
    return Consumer<CallService>(
      builder: (context, cs, _) {
        final lines = cs.transcript;
        final partial = cs.livePartial;
        
        if (lines.isEmpty && partial.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isInitializing)
                  Column(
                    children: [
                      const SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34C759)),
                      ),
                      const SizedBox(height: 16),
                      Text(_status, style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
                    ],
                  )
                else ...[
                  Icon(Icons.mic_none_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Text(
                    _isDemoMode ? 'Starting call simulation...' : 'Speak to begin',
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.white30),
                  ),
                ],
              ],
            ),
          );
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: lines.length + (partial.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            // Last item = live partial text
            if (index == lines.length && partial.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3, height: 20,
                      margin: const EdgeInsets.only(top: 2, right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        partial,
                        style: GoogleFonts.inter(
                          fontSize: 15, color: Colors.white30, fontStyle: FontStyle.italic, height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final line = lines[index];
            final isScammer = line.isScammer;
            final barColor = isScammer ? const Color(0xFFFF453A) : const Color(0xFF34C759);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3, height: 20,
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speaker label
                        if (_isDemoMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              isScammer ? (scenario?.callerName ?? 'Caller') : 'You',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isScammer ? const Color(0xFFFF453A).withValues(alpha: 0.7) : const Color(0xFF34C759).withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Text(
                          line.text,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                        if (line.isCleaned)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.security, size: 10, color: const Color(0xFF34C759).withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  'PII stripped',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF34C759).withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: isScammer ? -0.03 : 0.03);
          },
        );
      },
    );
  }
  
  // ── Takeover Bar ──
  Widget _buildTakeoverBar() {
    return Consumer<ThreatService>(
      builder: (context, ts, _) {
        final isAlert = ts.currentAnalysis?.isAlert ?? false;
        
        if (!isAlert) return const SizedBox.shrink();
        
        // ── Demo mode: AI handles it autonomously, no manual buttons ──
        if (_isDemoMode) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _autoTakeoverTriggered
                  ? const Color(0xFFFF453A).withValues(alpha: 0.12)
                  : const Color(0xFF34C759).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _autoTakeoverTriggered
                    ? const Color(0xFFFF453A).withValues(alpha: 0.3)
                    : const Color(0xFF34C759).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _autoTakeoverTriggered ? Icons.campaign : Icons.psychology,
                  color: _autoTakeoverTriggered ? const Color(0xFFFF453A) : const Color(0xFF34C759),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _autoTakeoverTriggered ? 'AI TAKEOVER ACTIVE' : 'AI MONITORING — WILL INTERVENE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _autoTakeoverTriggered ? const Color(0xFFFF453A) : const Color(0xFF34C759),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
        }
        
        // ── Real mode: manual takeover buttons ──
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _takeoverBtn('Shield', Icons.shield_outlined, const Color(0xFF34C759), 'shield'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _takeoverBtn('Interrogate', Icons.search, const Color(0xFFFFA502), 'interrogate'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _takeoverBtn('Siren', Icons.campaign, const Color(0xFFFF453A), 'siren'),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
      },
    );
  }
  
  Widget _takeoverBtn(String label, IconData icon, Color color, String mode) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _activateTakeover(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
  
  // ── Bottom Status ──
  Widget _buildBottomStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _pipelineActive ? const Color(0xFF34C759) : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _pipelineActive 
                ? (_isDemoMode 
                    ? 'Demo mode  ·  Session: ${ApiService.sessionId?.substring(0, 12) ?? "offline"}'
                    : 'On-device ASR  ·  Session: ${ApiService.sessionId?.substring(0, 12) ?? "offline"}')
                : _status,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}
