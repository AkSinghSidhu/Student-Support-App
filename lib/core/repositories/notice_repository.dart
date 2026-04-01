import '../services/notice_service.dart';
import '../../models/models.dart';

class NoticeRepository {
  Stream<List<NoticeModel>> noticesStream() {
    return NoticeService().noticesStream().map(
          (rawList) => rawList
              .map((json) => NoticeModel.fromJson(json))
              .toList(),
        );
  }
}
