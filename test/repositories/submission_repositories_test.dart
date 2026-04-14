import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:student_support_app/core/helpers/form_submission_helper.dart';
import 'package:student_support_app/core/repositories/complaint_repository.dart';
import 'package:student_support_app/core/repositories/feedback_repository.dart';

class MockFormSubmissionHelper extends Mock implements FormSubmissionHelper {}

void main() {
  late MockFormSubmissionHelper mockHelper;

  setUp(() {
    mockHelper = MockFormSubmissionHelper();
  });

  group('ComplaintRepository', () {
    late ComplaintRepository repo;

    setUp(() {
      repo = ComplaintRepository(formHelper: mockHelper);
    });

    test('submitComplaint delegates to FormSubmissionHelper with type complaints', () async {
      final data = {'subject': 'Test', 'description': 'Desc'};
      when(() => mockHelper.submitForm(
            type: 'complaints',
            auid: 'user1',
            data: data,
          )).thenAnswer((_) async => true);

      final result = await repo.submitComplaint('user1', data);

      expect(result, isTrue);
      verify(() => mockHelper.submitForm(
            type: 'complaints',
            auid: 'user1',
            data: data,
          )).called(1);
    });

    test('submitComplaint returns false when offline (helper returns false)', () async {
      final data = {'subject': 'Offline'};
      when(() => mockHelper.submitForm(
            type: 'complaints',
            auid: 'user2',
            data: data,
          )).thenAnswer((_) async => false);

      final result = await repo.submitComplaint('user2', data);

      expect(result, isFalse);
    });

    test('submitComplaint rethrows when helper throws', () async {
      final data = {'subject': 'Error'};
      when(() => mockHelper.submitForm(
            type: 'complaints',
            auid: 'user3',
            data: data,
          )).thenThrow(Exception('Network error'));

      expect(
        () => repo.submitComplaint('user3', data),
        throwsException,
      );
    });
  });

  group('FeedbackRepository', () {
    late FeedbackRepository repo;

    setUp(() {
      repo = FeedbackRepository(formHelper: mockHelper);
    });

    test('submitFeedback delegates to FormSubmissionHelper with type feedback', () async {
      final data = {'message': 'Good', 'rating': 5};
      when(() => mockHelper.submitForm(
            type: 'feedback',
            auid: 'user1',
            data: data,
          )).thenAnswer((_) async => true);

      final result = await repo.submitFeedback('user1', data);

      expect(result, isTrue);
      verify(() => mockHelper.submitForm(
            type: 'feedback',
            auid: 'user1',
            data: data,
          )).called(1);
    });

    test('submitFeedback returns false when offline', () async {
      final data = {'message': 'Offline test'};
      when(() => mockHelper.submitForm(
            type: 'feedback',
            auid: 'user2',
            data: data,
          )).thenAnswer((_) async => false);

      final result = await repo.submitFeedback('user2', data);

      expect(result, isFalse);
    });
  });
}
