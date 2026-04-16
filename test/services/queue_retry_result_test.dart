import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/core/queue_service.dart';

void main() {
  group('QueueRetryResult', () {
    test('default values are all zero', () {
      const result = QueueRetryResult();
      expect(result.sentCount, 0);
      expect(result.expiredCount, 0);
      expect(result.failedCount, 0);
    });

    test('hasActivity is false when nothing happened', () {
      const result = QueueRetryResult();
      expect(result.hasActivity, isFalse);
    });

    test('hasActivity is true when sentCount > 0', () {
      const result = QueueRetryResult(sentCount: 2);
      expect(result.hasActivity, isTrue);
    });

    test('hasActivity is true when expiredCount > 0', () {
      const result = QueueRetryResult(expiredCount: 1);
      expect(result.hasActivity, isTrue);
    });

    test('hasActivity is false when only failedCount > 0', () {
      const result = QueueRetryResult(failedCount: 3);
      expect(result.hasActivity, isFalse);
    });

    test('hasActivity is true with mixed sent and expired', () {
      const result = QueueRetryResult(
        sentCount: 1,
        expiredCount: 2,
        failedCount: 1,
      );
      expect(result.hasActivity, isTrue);
    });
  });
}
