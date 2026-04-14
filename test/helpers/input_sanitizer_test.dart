import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/core/helpers/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitize', () {
      test('removes Firebase-forbidden characters . # \$ [ ]', () {
        expect(InputSanitizer.sanitize('hello.world'), 'helloworld');
        expect(InputSanitizer.sanitize('path#key'), 'pathkey');
        expect(InputSanitizer.sanitize('price\$100'), 'price100');
        expect(InputSanitizer.sanitize('arr[0]'), 'arr0');
      });

      test('leaves clean strings untouched', () {
        const clean = 'Hello World 123!@&*()';
        expect(InputSanitizer.sanitize(clean), clean);
      });

      test('handles empty string', () {
        expect(InputSanitizer.sanitize(''), '');
      });

      test('handles string with only forbidden chars', () {
        expect(InputSanitizer.sanitize('.#\$[]'), '');
      });

      test('handles mixed forbidden and safe chars', () {
        expect(
          InputSanitizer.sanitize('a.b#c\$d[e]f'),
          'abcdef',
        );
      });
    });

    group('isValid', () {
      test('returns true for clean input', () {
        expect(InputSanitizer.isValid('Hello World'), isTrue);
      });

      test('returns false for input with dot', () {
        expect(InputSanitizer.isValid('hello.world'), isFalse);
      });

      test('returns false for input with hash', () {
        expect(InputSanitizer.isValid('path#key'), isFalse);
      });

      test('returns false for input with dollar', () {
        expect(InputSanitizer.isValid('\$price'), isFalse);
      });

      test('returns false for input with brackets', () {
        expect(InputSanitizer.isValid('arr[0]'), isFalse);
      });

      test('returns true for empty string', () {
        expect(InputSanitizer.isValid(''), isTrue);
      });
    });

    group('maxLength', () {
      test('equals 1000', () {
        expect(InputSanitizer.maxLength, 1000);
      });
    });
  });
}
