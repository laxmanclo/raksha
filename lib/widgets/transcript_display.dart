import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/call_service.dart';

/// Flowing transcript display.
///
/// HCI rationale:
/// - No card wrapper: the transcript IS the main content, not a widget inside content
/// - Reverse list: newest at bottom, natural reading flow (like chat)
/// - Minimal metadata: timestamp is subtle and inline
/// - Empty state is calm and informative (reduces anxiety during wait)
class TranscriptDisplay extends StatelessWidget {
  const TranscriptDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallService>(
      builder: (context, callService, _) {
        final transcript = callService.transcript;

        if (transcript.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for speech',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          reverse: true,
          itemCount: transcript.length,
          itemBuilder: (context, index) {
            final reversedIndex = transcript.length - 1 - index;
            final line = transcript[reversedIndex];
            return _buildLine(line, reversedIndex == transcript.length - 1);
          },
        );
      },
    );
  }

  Widget _buildLine(dynamic line, bool isLatest) {
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Inline timestamp
          SizedBox(
            width: 40,
            child: Text(
              timeFormat.format(line.timestamp),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF333333),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Transcript text
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isLatest ? FontWeight.w500 : FontWeight.w400,
                      color: isLatest ? Colors.white : Colors.white70,
                      height: 1.45,
                    ),
                  ),
                ),
                if (line.isCleaned)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: const Color(0xFF34C759).withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
