import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';
import '../services/threat_service.dart';
import '../services/api_service.dart';
import 'call_monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _backendOnline = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final ok = await ApiService.checkHealth();
    if (mounted) setState(() { _backendOnline = ok; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Header
              Text(
                'Raksha',
                style: GoogleFonts.inter(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 6),

              Text(
                'AI scam call protection',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white38,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 48),

              // Feature chips
              _chip(Icons.mic_none, 'On-device ASR', 'Audio never leaves phone'),
              const SizedBox(height: 12),
              _chip(Icons.psychology_outlined, 'Claude analysis', 'Real-time threat scoring'),
              const SizedBox(height: 12),
              _chip(Icons.shield_outlined, 'AI takeover', 'Auto-respond to scammers'),
              const SizedBox(height: 12),
              _chip(Icons.fingerprint, 'PII stripping', 'Sensitive data stays private'),

              const Spacer(),

              // Backend status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: _checking
                          ? const Color(0xFFFF9F0A)
                          : (_backendOnline ? const Color(0xFF34C759) : const Color(0xFFFF453A)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _checking ? 'Checking backend...' : (_backendOnline ? 'Backend online' : 'Offline mode'),
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Start monitoring button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CallService>().clearTranscript();
                    context.read<ThreatService>().clearAnalysis();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const CallMonitoringScreen(),
                        transitionsBuilder: (_, anim, __, child) {
                          return FadeTransition(opacity: anim, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Start Monitoring',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 14),

              // Demo scenario buttons (from friend's code)
              Row(
                children: [
                  Expanded(
                    child: _demoBtn(context, 'Banking Scam', Icons.account_balance_outlined, 'banking'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _demoBtn(context, 'Tech Support', Icons.computer_outlined, 'tech_support'),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoBtn(BuildContext context, String label, IconData icon, String scenario) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<CallService>().clearTranscript();
          context.read<ThreatService>().clearAnalysis();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CallMonitoringScreen(demoScenario: scenario)),
          );
        },
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white54,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF34C759), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.inter(fontSize: 12, color: Colors.white30)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.05);
  }
}
