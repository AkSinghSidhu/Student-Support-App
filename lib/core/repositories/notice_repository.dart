import '../services/notice_service.dart';
import '../../models/models.dart';
import '../di/service_locator.dart';

class NoticeRepository {
  Stream<List<NoticeModel>> noticesStream() {
    return sl<NoticeService>().noticesStream().map(
          (rawList) => rawList
              .map((json) => NoticeModel.fromJson(json))
              .toList(),
        );
  }
}
