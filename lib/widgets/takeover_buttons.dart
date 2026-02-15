import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/threat_service.dart';
import '../services/tts_service.dart';

/// AI takeover action buttons.
///
/// HCI rationale:
/// - Hidden when no threat (progressive disclosure: reduce cognitive load)
/// - Appears only when actionable (Gestalt: figure/ground — actions emerge from background)
/// - Large tap targets for stressed users (Fitts's Law)
/// - Confirmation dialog prevents accidental activation (error prevention)
class TakeoverButtons extends StatelessWidget {
  const TakeoverButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatService>(
      builder: (context, threatService, _) {
        final analysis = threatService.currentAnalysis;
        final scripts = analysis?.takeoverScripts;
        final isAlert = analysis?.isAlert ?? false;

        // Inactive: one-liner status
        if (!isAlert || scripts == null) {
          return Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(width: 8),
              Text(
                'AI takeover available when threat detected',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          );
        }

        // Active: three action buttons
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.shield_rounded,
                label: 'Shield',
                color: const Color(0xFF34C759),
                onTap: () => _confirmTakeover(context, 'Shield', scripts.shield),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.search_rounded,
                label: 'Interrogate',
                color: const Color(0xFFFF9F0A),
                onTap: () =>
                    _confirmTakeover(context, 'Interrogate', scripts.interrogate),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.campaign_rounded,
                label: 'Siren',
                color: const Color(0xFFFF453A),
                onTap: () => _confirmTakeover(context, 'Siren', scripts.siren),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
      },
    );
  }

  void _confirmTakeover(BuildContext context, String mode, String script) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Activate $mode',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI will speak the following on your behalf:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                script,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              TtsService.speak(script);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'AI speaking...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF34C759),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Activate',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
