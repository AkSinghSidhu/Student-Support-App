import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/core/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('SharedPreferences Keys', () {
      test('themeModeKey is non-empty', () {
        expect(AppConstants.themeModeKey, isNotEmpty);
      });

      test('auidKey is non-empty', () {
        expect(AppConstants.auidKey, isNotEmpty);
      });

      test('rememberMeKey is non-empty', () {
        expect(AppConstants.rememberMeKey, isNotEmpty);
      });

      test('pendingQueueKey is non-empty', () {
        expect(AppConstants.pendingQueueKey, isNotEmpty);
      });

      test('seenNoticeIdsKey is non-empty', () {
        expect(AppConstants.seenNoticeIdsKey, isNotEmpty);
      });
    });

    group('Hive Box Names', () {
      test('notificationsBoxKey is non-empty', () {
        expect(AppConstants.notificationsBoxKey, isNotEmpty);
      });

      test('attendanceCacheBox is non-empty', () {
        expect(AppConstants.attendanceCacheBox, isNotEmpty);
      });
    });

    group('attendanceThreshold', () {
      test('is 75.0', () {
        expect(AppConstants.attendanceThreshold, 75.0);
      });
    });

    group('Status Constants', () {
      test('statusPending equals pending', () {
        expect(AppConstants.statusPending, 'pending');
      });

      test('statusResolved equals resolved', () {
        expect(AppConstants.statusResolved, 'resolved');
      });

      test('statusRejected equals rejected', () {
        expect(AppConstants.statusRejected, 'rejected');
      });
    });

    group('Default Department Teachers', () {
      test('contains Computer Science', () {
        expect(
          AppConstants.defaultDepartmentTeachers.containsKey('Computer Science'),
          isTrue,
        );
      });

      test('Computer Science has at least 1 teacher', () {
        expect(
          AppConstants.defaultDepartmentTeachers['Computer Science']!.length,
          greaterThanOrEqualTo(1),
        );
      });

      test('contains at least 4 departments', () {
        expect(
          AppConstants.defaultDepartmentTeachers.length,
          greaterThanOrEqualTo(4),
        );
      });
    });

    group('UI Strings are non-empty', () {
      test('appName is non-empty', () {
        expect(AppConstants.appName, isNotEmpty);
      });

      test('loginWelcomeTitle is non-empty', () {
        expect(AppConstants.loginWelcomeTitle, isNotEmpty);
      });

      test('loginAuidLabel is non-empty', () {
        expect(AppConstants.loginAuidLabel, isNotEmpty);
      });
    });
  });
}
