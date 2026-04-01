import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('QueueItemModel', () {
    test('isExpired true for 8-day-old item', () {
      final item = QueueItemModel(
        localId: '1',
        type: 'complaints',
        auid: 'user123',
        data: {},
        timestamp: DateTime.now().subtract(
          const Duration(days: 8),
        ),
      );
      expect(item.isExpired, isTrue);
    });

    test('isExpired false for fresh item', () {
      final item = QueueItemModel(
        localId: '1',
        type: 'complaints',
        auid: 'user123',
        data: {},
        timestamp: DateTime.now(),
      );
      expect(item.isExpired, isFalse);
    });

    test('fromJson toJson round-trip', () {
      final item = QueueItemModel(
        localId: 'abc',
        type: 'feedback',
        auid: 'u456',
        data: {'msg': 'test'},
        timestamp: DateTime(2026, 1, 1),
      );
      final restored = QueueItemModel.fromJson(item.toJson());
      expect(restored.localId, item.localId);
      expect(restored.type, item.type);
      expect(restored.auid, item.auid);
    });
  });
}
