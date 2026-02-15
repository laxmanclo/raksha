import 'package:flutter/material.dart';

class ThreatAnalysis {
  final int threatScore;
  final String threatLevel;
  final List<String> techniques;
  final bool isAlert;
  final String? scamType;
  final String explanation;
  final TakeoverScripts? takeoverScripts;

  ThreatAnalysis({
    required this.threatScore,
    required this.threatLevel,
    required this.techniques,
    required this.isAlert,
    this.scamType,
    required this.explanation,
    this.takeoverScripts,
  });

  factory ThreatAnalysis.fromJson(Map<String, dynamic> json) {
    return ThreatAnalysis(
      threatScore: json['threat_score'] ?? 0,
      threatLevel: json['threat_level'] ?? 'NONE',
      techniques: List<String>.from(json['techniques'] ?? []),
      isAlert: json['is_alert'] ?? false,
      scamType: json['scam_type'],
      explanation: json['explanation'] ?? '',
      takeoverScripts: json['takeover_scripts'] != null
          ? TakeoverScripts.fromJson(json['takeover_scripts'])
          : null,
    );
  }

  Color get threatColor {
    switch (threatLevel) {
      case 'CRITICAL':
        return const Color(0xFFFF4757);
      case 'HIGH':
        return const Color(0xFFFF6348);
      case 'MEDIUM':
        return const Color(0xFFFFA502);
      case 'LOW':
        return const Color(0xFFFFD32A);
      default:
        return const Color(0xFF5FD068);
    }
  }
}

class TakeoverScripts {
  final String shield;
  final String interrogate;
  final String siren;

  TakeoverScripts({
    required this.shield,
    required this.interrogate,
    required this.siren,
  });

  factory TakeoverScripts.fromJson(Map<String, dynamic> json) {
    return TakeoverScripts(
      shield: json['shield'] ?? '',
      interrogate: json['interrogate'] ?? '',
      siren: json['siren'] ?? '',
    );
  }
}

class TranscriptLine {
  final String text;
  final DateTime timestamp;
  final bool isCleaned;
  final bool isScammer;

  TranscriptLine({
    required this.text,
    required this.timestamp,
    this.isCleaned = false,
    this.isScammer = false,
  });
}
