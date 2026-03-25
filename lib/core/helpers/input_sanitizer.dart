class InputSanitizer {
  // Firebase RTDB forbidden characters in keys: . # $ [ ]
  static const String _forbiddenPattern = r'[.#$\[\]]';

  static String sanitize(String input) {
    return input.replaceAll(RegExp(_forbiddenPattern), '');
  }

  static bool isValid(String input) {
    return !RegExp(_forbiddenPattern).hasMatch(input);
  }

  static const int maxLength = 1000;
}
