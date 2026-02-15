import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/threat_service.dart';

/// Compact threat indicator.
///
/// HCI rationale:
/// - Score is the single most important number on screen -> large typography
/// - Horizontal bar gives instant "how full" perception (pre-attentive)
/// - Alert banner uses red + bold text for urgency without emoji clutter
/// - Techniques shown as small pills for glanceability
class ThreatMeter extends StatelessWidget {
  const ThreatMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatService>(
      builder: (context, threatService, _) {
        final analysis = threatService.currentAnalysis;
        final score = analysis?.threatScore ?? 0;
        final level = analysis?.threatLevel ?? 'NONE';
        final techniques = analysis?.techniques ?? [];
        final isAlert = analysis?.isAlert ?? false;
        final color = analysis?.threatColor ?? const Color(0xFF333333);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert banner — only appears when scam detected
            if (isAlert)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF453A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Scam Detected — ${analysis?.scamType ?? "Suspicious Activity"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF453A),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).shakeX(
                    hz: 3,
                    amount: 2,
                    duration: 400.ms,
                  ),

            // Score row: number + bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Large score number
                Text(
                  score.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    level,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF666666),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                // Technique pills
                if (techniques.isNotEmpty)
                  ...techniques.take(2).map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                height: 4,
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: const Color(0xFF1A1A1A),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ),

            // Explanation
            if (analysis?.explanation != null &&
                analysis!.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                analysis.explanation,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }
}
