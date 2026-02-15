import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/microphone_service.dart';
import '../services/threat_service.dart';

/// A clean, luminous orb -- white core with soft colored glow.
///
/// Default state: white sphere with gentle green aura (= safe, listening).
/// Threat detected: glow shifts to amber or red while core stays white.
/// Voice activity: smooth scale pulse + expanding rings.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({super.key});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _ringPulseController;
  late final AnimationController _tickController;

  double _displayLevel = 0.0;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _tickController.addListener(_smoothAmplitude);
  }

  void _smoothAmplitude() {
    final mic = context.read<MicrophoneService>();
    final target = mic.audioLevel;
    final speed = target > _displayLevel ? 0.35 : 0.06;
    final newLevel = _displayLevel + (target - _displayLevel) * speed;
    if ((newLevel - _displayLevel).abs() > 0.001) {
      setState(() => _displayLevel = newLevel);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _ringPulseController.dispose();
    _tickController.removeListener(_smoothAmplitude);
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatService>(
      builder: (context, threatService, _) {
        final level =
            threatService.currentAnalysis?.threatLevel ?? 'NONE';

        // Glow color shifts with threat; core stays white
        final Color glowColor;
        switch (level) {
          case 'MEDIUM':
            glowColor = const Color(0xFFFF9F0A);
            break;
          case 'HIGH':
          case 'CRITICAL':
            glowColor = const Color(0xFFFF453A);
            break;
          case 'LOW':
          default:
            glowColor = const Color(0xFF34C759); // Clean green
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            _breathController,
            _ringPulseController,
          ]),
          builder: (context, child) {
            final breathOffset =
                math.sin(_breathController.value * math.pi) * 0.035;
            final ampOffset = _displayLevel * 0.22;
            final totalScale = 1.0 + breathOffset + ampOffset;

            return Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Transform.scale(
                  scale: totalScale,
                  child: CustomPaint(
                    painter: _OrbPainter(
                      glowColor: glowColor,
                      amplitude: _displayLevel,
                      ringPhase: _ringPulseController.value,
                    ),
                    size: const Size(280, 280),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Color glowColor;
  final double amplitude;
  final double ringPhase;

  _OrbPainter({
    required this.glowColor,
    required this.amplitude,
    required this.ringPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final coreRadius = maxR * 0.35;

    // ── Pulse rings (only with voice) ──
    if (amplitude > 0.02) {
      for (int i = 0; i < 3; i++) {
        final phase = (ringPhase + i * 0.33) % 1.0;
        final ringR = coreRadius + (maxR * 0.55 * phase);
        final opacity =
            (1.0 - phase) * amplitude.clamp(0.0, 0.5) * 0.3;

        if (opacity > 0.005) {
          final paint = Paint()
            ..color = glowColor.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 + (1.0 - phase) * 1.0;
          canvas.drawCircle(center, ringR, paint);
        }
      }
    }

    // ── Outer glow: soft, wide, colored ──
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.12 + amplitude * 0.08),
          glowColor.withValues(alpha: 0.03),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.95));
    canvas.drawCircle(center, maxR * 0.95, outerPaint);

    // ── Mid glow: tighter, brighter ──
    final midPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.25 + amplitude * 0.12),
          glowColor.withValues(alpha: 0.05),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: maxR * 0.6));
    canvas.drawCircle(center, maxR * 0.6, midPaint);

    // ── Core: white sphere with slight color tint at edge ──
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.25),
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.95),
          Color.lerp(Colors.white, glowColor, 0.2)!,
          Color.lerp(Colors.white, glowColor, 0.45)!,
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);

    // ── Soft edge rim: colored ring at the sphere boundary ──
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = glowColor.withValues(alpha: 0.3 + amplitude * 0.15);
    canvas.drawCircle(center, coreRadius, rimPaint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.ringPhase != ringPhase;
  }
}
