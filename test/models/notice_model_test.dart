import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('NoticeModel', () {
    final json = {
      'id': 'notice_001',
      'title': 'Exam Schedule Released',
      'category': 'Academic',
      'date': '2026-04-01',
      'important': true,
      'createdAt': '2026-04-01T08:00:00.000',
    };

    test('fromJson parses all fields correctly', () {
      final n = NoticeModel.fromJson(json);
      expect(n.id, 'notice_001');
      expect(n.title, 'Exam Schedule Released');
      expect(n.category, 'Academic');
      expect(n.date, '2026-04-01');
      expect(n.important, isTrue);
      expect(n.createdAt, '2026-04-01T08:00:00.000');
    });

    test('toJson round-trip preserves all fields', () {
      final n = NoticeModel.fromJson(json);
      final out = n.toJson();
      expect(out['id'], json['id']);
      expect(out['title'], json['title']);
      expect(out['category'], json['category']);
      expect(out['date'], json['date']);
      expect(out['important'], json['important']);
      expect(out['createdAt'], json['createdAt']);
    });

    test('defaults on empty json', () {
      final n = NoticeModel.fromJson({});
      expect(n.id, '');
      expect(n.title, '');
      expect(n.category, 'General');
      expect(n.date, '');
      expect(n.important, isFalse);
      expect(n.createdAt, '');
    });

    test('important defaults to false when null', () {
      final n = NoticeModel.fromJson({'important': null});
      expect(n.important, isFalse);
    });

    test('category defaults to General when missing', () {
      final n = NoticeModel.fromJson({'title': 'Test'});
      expect(n.category, 'General');
    });
  });
}
