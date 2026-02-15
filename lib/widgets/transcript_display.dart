import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/call_service.dart';

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Listening...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Speech will appear here',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D1F33),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.subtitles_rounded,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Live Transcript',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${transcript.length} lines',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                color: Color(0xFF2A2D47),
              ),

              // Transcript Lines
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  reverse: true,
                  itemCount: transcript.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = transcript.length - 1 - index;
                    final line = transcript[reversedIndex];
                    return _buildTranscriptLine(line);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranscriptLine(line) {
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeFormat.format(line.timestamp),
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                
                // PII Indicator
                if (line.isCleaned)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 12,
                          color: Color(0xFF5FD068),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PII stripped',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF5FD068),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
