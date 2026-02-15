import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/threat_service.dart';
import '../services/tts_service.dart';

class TakeoverButtons extends StatelessWidget {
  const TakeoverButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatService>(
      builder: (context, threatService, _) {
        final analysis = threatService.currentAnalysis;
        final scripts = analysis?.takeoverScripts;
        final isAlert = analysis?.isAlert ?? false;

        if (!isAlert || scripts == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1F33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Takeover available when threat detected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '🤖 AI Takeover Ready',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms),

            // Takeover Mode Buttons
            Row(
              children: [
                Expanded(
                  child: _buildTakeoverButton(
                    context,
                    icon: '🛡️',
                    label: 'Shield',
                    description: 'Clean exit',
                    color: const Color(0xFF5FD068),
                    script: scripts.shield,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTakeoverButton(
                    context,
                    icon: '🔍',
                    label: 'Interrogate',
                    description: 'Expose them',
                    color: const Color(0xFFFFA502),
                    script: scripts.interrogate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTakeoverButton(
                    context,
                    icon: '🚨',
                    label: 'Siren',
                    description: 'Scare off',
                    color: const Color(0xFFFF4757),
                    script: scripts.siren,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.3),
          ],
        );
      },
    );
  }

  Widget _buildTakeoverButton(
    BuildContext context, {
    required String icon,
    required String label,
    required String description,
    required Color color,
    required String script,
  }) {
    return InkWell(
      onTap: () => _activateTakeover(context, label, script),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _activateTakeover(BuildContext context, String mode, String script) {
    // Show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1F33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '🤖 AI Taking Over',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode: $mode',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                script,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TtsService.speak(script);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🔊 AI is speaking...',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: const Color(0xFF6C63FF),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Activate',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
