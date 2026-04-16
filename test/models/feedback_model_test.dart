import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('FeedbackModel', () {
    final json = {
      'userId': 'user456',
      'department': 'Computer Science',
      'teacher': 'Dr. Turing',
      'category': 'Teaching',
      'rating': 4,
      'message': 'Great lecture on algorithms',
      'status': 'pending',
      'createdAt': '2026-03-15T10:00:00.000',
    };

    test('fromJson parses all fields correctly', () {
      final f = FeedbackModel.fromJson(json);
      expect(f.userId, 'user456');
      expect(f.department, 'Computer Science');
      expect(f.teacher, 'Dr. Turing');
      expect(f.category, 'Teaching');
      expect(f.rating, 4);
      expect(f.message, 'Great lecture on algorithms');
      expect(f.status, 'pending');
      expect(f.createdAt, '2026-03-15T10:00:00.000');
    });

    test('toJson round-trip preserves all fields', () {
      final f = FeedbackModel.fromJson(json);
      final out = f.toJson();
      expect(out['userId'], json['userId']);
      expect(out['department'], json['department']);
      expect(out['teacher'], json['teacher']);
      expect(out['category'], json['category']);
      expect(out['rating'], json['rating']);
      expect(out['message'], json['message']);
      expect(out['status'], json['status']);
      expect(out['createdAt'], json['createdAt']);
    });

    test('defaults on empty json', () {
      final f = FeedbackModel.fromJson({});
      expect(f.userId, '');
      expect(f.department, '');
      expect(f.teacher, '');
      expect(f.category, '');
      expect(f.rating, 0);
      expect(f.message, '');
      expect(f.status, 'pending');
      expect(f.createdAt, '');
    });

    test('rating parses from num types', () {
      final f = FeedbackModel.fromJson({'rating': 3.7});
      expect(f.rating, 3); // toInt() truncates
    });
  });
}
