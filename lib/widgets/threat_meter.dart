import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/threat_service.dart';
import 'dart:math' as math;

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

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAlert
                  ? [
                      const Color(0xFFFF4757).withValues(alpha: 0.3),
                      const Color(0xFF0A0E21),
                    ]
                  : [
                      const Color(0xFF1D1F33),
                      const Color(0xFF1D1F33),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAlert
                  ? const Color(0xFFFF4757)
                  : Colors.white.withValues(alpha: 0.1),
              width: isAlert ? 2 : 1,
            ),
            boxShadow: isAlert
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Alert Banner
              if (isAlert)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ SCAM DETECTED',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysis?.scamType ?? 'Suspicious Activity',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)),

              // Threat Score Circle
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: ThreatCirclePainter(
                        score: score,
                        color: analysis?.threatColor ?? Colors.grey,
                        isAlert: isAlert,
                      ),
                    ),
                    
                    // Score text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: analysis?.threatColor ?? Colors.grey,
                          ),
                        ),
                        Text(
                          level,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

              const SizedBox(height: 24),

              // Threat Techniques Tags
              if (techniques.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: techniques.map((technique) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (analysis?.threatColor ?? Colors.grey)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: analysis?.threatColor ?? Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        technique,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: analysis?.threatColor ?? Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              // Explanation
              if (analysis?.explanation != null && analysis!.explanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis.explanation,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ThreatCirclePainter extends CustomPainter {
  final int score;
  final Color color;
  final bool isAlert;

  ThreatCirclePainter({
    required this.score,
    required this.color,
    required this.isAlert,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius - 8, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Alert pulse effect
    if (isAlert) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius + 5, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(ThreatCirclePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.isAlert != isAlert;
  }
}
