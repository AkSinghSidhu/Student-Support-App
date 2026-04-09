import '../services/notice_service.dart';
import '../../models/models.dart';
import '../di/service_locator.dart';

abstract class INoticeRepository {
  Stream<List<NoticeModel>> noticesStream();
}

class NoticeRepository implements INoticeRepository {
  final NoticeService _noticeService;

  NoticeRepository({NoticeService? noticeService})
      : _noticeService = noticeService ?? sl<NoticeService>();

  @override
  Stream<List<NoticeModel>> noticesStream() {
    return _noticeService.noticesStream().map(
          (rawList) => rawList
              .map((json) => NoticeModel.fromJson(json))
              .toList(),
        );
  }
}
