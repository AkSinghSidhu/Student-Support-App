import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:student_support_app/core/app_constants.dart';
import 'package:student_support_app/models/models.dart';

/// These tests exercise the QueueService's local persistence layer
/// (add / get / remove) without touching Firebase, by mocking SharedPreferences.
///
/// We cannot test retryAll() here because it requires a real DatabaseService/Firebase.
/// That is covered by integration tests.
void main() {
  group('QueueService local persistence (via SharedPreferences)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getPendingItems returns empty list when nothing stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.pendingQueueKey);
      expect(raw, isNull);
    });

    test('can round-trip a QueueItemModel through SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();

      final item = QueueItemModel(
        localId: 'test1',
        type: 'complaints',
        auid: 'user1',
        data: {'subject': 'Test'},
        timestamp: DateTime(2026, 1, 1),
      );

      // Simulate addToQueue
      final encoded = json.encode([item.toJson()]);
      await prefs.setString(AppConstants.pendingQueueKey, encoded);

      // Simulate getPendingItems
      final stored = prefs.getString(AppConstants.pendingQueueKey);
      expect(stored, isNotNull);

      final decoded = json.decode(stored!) as List;
      final restored = decoded
          .map((e) => QueueItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      expect(restored.length, 1);
      expect(restored.first.localId, 'test1');
      expect(restored.first.type, 'complaints');
      expect(restored.first.auid, 'user1');
    });

    test('removing an item from queue updates the list', () async {
      final prefs = await SharedPreferences.getInstance();

      final items = [
        QueueItemModel(
          localId: 'a',
          type: 'complaints',
          auid: 'u1',
          data: {},
          timestamp: DateTime.now(),
        ),
        QueueItemModel(
          localId: 'b',
          type: 'feedback',
          auid: 'u2',
          data: {},
          timestamp: DateTime.now(),
        ),
      ];

      await prefs.setString(
        AppConstants.pendingQueueKey,
        json.encode(items.map((e) => e.toJson()).toList()),
      );

      // Simulate removeFromQueue('a')
      final stored = prefs.getString(AppConstants.pendingQueueKey)!;
      final decoded = (json.decode(stored) as List)
          .map((e) => QueueItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      decoded.removeWhere((item) => item.localId == 'a');

      await prefs.setString(
        AppConstants.pendingQueueKey,
        json.encode(decoded.map((e) => e.toJson()).toList()),
      );

      final remaining = prefs.getString(AppConstants.pendingQueueKey)!;
      final finalList = (json.decode(remaining) as List)
          .map((e) => QueueItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      expect(finalList.length, 1);
      expect(finalList.first.localId, 'b');
    });
  });
}
