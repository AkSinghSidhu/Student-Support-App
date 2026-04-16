import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('ComplaintModel', () {
    final json = {
      'userId': 'user123',
      'subject': 'Test',
      'description': 'Desc',
      'type': 'Academic',
      'urgency': 'High',
      'status': 'pending',
      'createdAt': '2026-01-01T00:00:00.000',
    };

    test('fromJson parses correctly', () {
      final c = ComplaintModel.fromJson(json);
      expect(c.userId, 'user123');
      expect(c.urgency, 'High');
      expect(c.status, 'pending');
    });

    test('toJson round-trip', () {
      final c = ComplaintModel.fromJson(json);
      final out = c.toJson();
      expect(out['userId'], json['userId']);
      expect(out['urgency'], json['urgency']);
    });

    test('defaults on empty json', () {
      final c = ComplaintModel.fromJson({});
      expect(c.urgency, 'Low');
      expect(c.status, 'pending');
    });
  });
}
