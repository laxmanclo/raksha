/// Privacy-first PII detection and stripping service.
/// Runs entirely on-device using regex patterns for Indian PII formats.
/// Designed for call monitoring context — strips sensitive info before
/// sending transcript text to any backend for threat analysis.
///
/// Future upgrade: Replace regex with GLiNER ONNX model for context-aware
/// entity recognition (requires onnxruntime_v2 + tokenizer).
class PiiService {
  /// Strip all detected PII from text, replacing with type tags.
  /// Returns cleaned text safe for backend processing.
  static String stripPII(String text) {
    String cleaned = text;

    // Credit/Debit card numbers: 16 digits with optional spaces/dashes
    // Must check before Aadhaar (16 digits vs 12)
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b'),
      '[CARD]',
    );

    // Aadhaar: 12 digits with optional spaces (XXXX XXXX XXXX)
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'),
      '[AADHAAR]',
    );

    // PAN card: ABCDE1234F format (5 letters + 4 digits + 1 letter)
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'),
      '[PAN]',
    );

    // Phone numbers: 10 digits with optional +91 prefix and separators
    cleaned = cleaned.replaceAll(
      RegExp(r'(\+91[\-\s]?)?(\d[\-\s]?)?\d{10}\b'),
      '[PHONE]',
    );

    // UPI IDs: username@bankcode format
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[\w.]+@[a-zA-Z]+\b'),
      '[UPI_ID]',
    );

    // Bank account numbers: 9-18 digit sequences
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{9,18}\b'),
      '[ACCOUNT]',
    );

    // OTP: 4-6 digit codes (after other patterns to avoid false positives)
    // Only match when preceded by OTP-related context words
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:OTP|otp|code|pin|PIN|verify)\s*(?:is|hai|:)?\s*(\d{4,6})\b', caseSensitive: false),
      '[OTP_REDACTED]',
    );

    // IFSC code: 4 letters + 0 + 6 alphanumeric
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b'),
      '[IFSC]',
    );

    // Email addresses
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b'),
      '[EMAIL]',
    );

    return cleaned;
  }

  /// Check if text contains any PII patterns
  static bool containsPII(String text) {
    final patterns = [
      RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b'), // Card
      RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'), // Aadhaar
      RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'), // PAN
      RegExp(r'(\+91[\-\s]?)?(\d[\-\s]?)?\d{10}\b'), // Phone
      RegExp(r'\b[\w.]+@[a-zA-Z]+\b'), // UPI
      RegExp(r'\b\d{9,18}\b'), // Account
      RegExp(r'(?:OTP|otp|code|pin|PIN)\s*(?:is|hai|:)?\s*\d{4,6}\b'), // OTP
      RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b'), // IFSC
      RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b'), // Email
    ];

    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Get list of PII types found in text (for UI display)
  static List<String> detectPIITypes(String text) {
    final types = <String>[];

    if (RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b').hasMatch(text)) {
      types.add('Card');
    }
    if (RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b').hasMatch(text)) {
      types.add('Aadhaar');
    }
    if (RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b').hasMatch(text)) {
      types.add('PAN');
    }
    if (RegExp(r'(\+91[\-\s]?)?(\d[\-\s]?)?\d{10}\b').hasMatch(text)) {
      types.add('Phone');
    }
    if (RegExp(r'\b[\w.]+@[a-zA-Z]+\b').hasMatch(text)) {
      types.add('UPI/Email');
    }
    if (RegExp(r'\b\d{9,18}\b').hasMatch(text)) {
      types.add('Account');
    }
    if (RegExp(r'(?:OTP|otp|code|pin|PIN)\s*(?:is|hai|:)?\s*\d{4,6}\b').hasMatch(text)) {
      types.add('OTP');
    }
    if (RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b').hasMatch(text)) {
      types.add('IFSC');
    }

    return types;
  }
}
