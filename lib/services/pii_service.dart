class PiiService {
  /// Strip PII from text on-device before sending to backend
  static String stripPII(String text) {
    String cleaned = text;
    
    // Aadhaar: 12 digits with optional spaces
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'),
      '[AADHAAR]',
    );
    
    // Phone numbers: 10 digits with optional +91 prefix
    cleaned = cleaned.replaceAll(
      RegExp(r'(\+91[\-\s]?)?\b\d{10}\b'),
      '[PHONE]',
    );
    
    // Credit/Debit card numbers: 16 digits with optional spaces/dashes
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b'),
      '[CARD]',
    );
    
    // OTP: 4-6 digit codes
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{4,6}\b'),
      '[OTP]',
    );
    
    // UPI IDs: email-like format
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[\w.]+@[\w]+\b'),
      '[UPI_ID]',
    );
    
    // Bank account numbers: 9-18 digits
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{9,18}\b'),
      '[ACCOUNT]',
    );
    
    // PAN card: ABCDE1234F format
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'),
      '[PAN]',
    );
    
    return cleaned;
  }

  /// Check if text contains PII
  static bool containsPII(String text) {
    final patterns = [
      RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'), // Aadhaar
      RegExp(r'(\+91[\-\s]?)?\b\d{10}\b'), // Phone
      RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b'), // Card
      RegExp(r'\b\d{4,6}\b'), // OTP
      RegExp(r'\b[\w.]+@[\w]+\b'), // UPI/Email
      RegExp(r'\b\d{9,18}\b'), // Account
      RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'), // PAN
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Get list of PII types found in text
  static List<String> detectPIITypes(String text) {
    final types = <String>[];
    
    if (RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b').hasMatch(text)) {
      types.add('Aadhaar');
    }
    if (RegExp(r'(\+91[\-\s]?)?\b\d{10}\b').hasMatch(text)) {
      types.add('Phone');
    }
    if (RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b').hasMatch(text)) {
      types.add('Card');
    }
    if (RegExp(r'\b\d{4,6}\b').hasMatch(text)) {
      types.add('OTP');
    }
    if (RegExp(r'\b[\w.]+@[\w]+\b').hasMatch(text)) {
      types.add('UPI/Email');
    }
    if (RegExp(r'\b\d{9,18}\b').hasMatch(text)) {
      types.add('Account');
    }
    if (RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b').hasMatch(text)) {
      types.add('PAN');
    }
    
    return types;
  }
}
