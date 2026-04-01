import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('SubjectModel', () {
    test('fromJson parses valid data', () {
      final s = SubjectModel.fromJson('CS101', {
        'name': 'Computer Science',
        'attended': 8,
        'total': 10,
      });
      expect(s.code, 'CS101');
      expect(s.name, 'Computer Science');
      expect(s.attended, 8);
      expect(s.total, 10);
    });

    test('percent = 80.0 when 8/10', () {
      final s = SubjectModel.fromJson('X', {
        'name': 'X', 'attended': 8, 'total': 10,
      });
      expect(s.percent, 80.0);
    });

    test('isLow true when percent < 75', () {
      final s = SubjectModel.fromJson('X', {
        'name': 'X', 'attended': 7, 'total': 10,
      });
      expect(s.isLow, isTrue);
    });

    test('isLow false when percent >= 75', () {
      final s = SubjectModel.fromJson('X', {
        'name': 'X', 'attended': 8, 'total': 10,
      });
      expect(s.isLow, isFalse);
    });

    test('percent = 0 when total = 0', () {
      final s = SubjectModel.fromJson('X', {
        'name': 'X', 'attended': 0, 'total': 0,
      });
      expect(s.percent, 0.0);
    });

    test('handles empty json gracefully', () {
      final s = SubjectModel.fromJson('X', {});
      expect(s.attended, 0);
      expect(s.total, 0);
    });
  });
}
