import '../di/service_locator.dart';
import '../helpers/form_submission_helper.dart';

abstract class IFeedbackRepository {
  Future<bool> submitFeedback(String auid, Map<String, dynamic> data);
}

class FeedbackRepository implements IFeedbackRepository {
  final FormSubmissionHelper _formHelper;

  FeedbackRepository({FormSubmissionHelper? formHelper})
      : _formHelper = formHelper ?? sl<FormSubmissionHelper>();

  @override
  Future<bool> submitFeedback(String auid, Map<String, dynamic> data) async {
    return _formHelper.submitForm(
      type: 'feedback',
      auid: auid,
      data: data,
    );
  }
}
