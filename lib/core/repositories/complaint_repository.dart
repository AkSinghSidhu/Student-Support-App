import '../di/service_locator.dart';
import '../helpers/form_submission_helper.dart';

abstract class IComplaintRepository {
  Future<bool> submitComplaint(String auid, Map<String, dynamic> data);
}

class ComplaintRepository implements IComplaintRepository {
  final FormSubmissionHelper _formHelper;

  ComplaintRepository({FormSubmissionHelper? formHelper})
      : _formHelper = formHelper ?? sl<FormSubmissionHelper>();

  @override
  Future<bool> submitComplaint(String auid, Map<String, dynamic> data) async {
    return _formHelper.submitForm(
      type: 'complaints',
      auid: auid,
      data: data,
    );
  }
}
