import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_support_app/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default mode is system', () {
      expect(ThemeProvider().themeMode, ThemeMode.system);
    });

    test('setThemeMode changes mode', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark);
      expect(p.themeMode, ThemeMode.dark);
    });

    test('isDarkMode true when dark', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark);
      expect(p.isDarkMode, isTrue);
    });

    test('isDarkMode false when light', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.light);
      expect(p.isDarkMode, isFalse);
    });
  });
}
