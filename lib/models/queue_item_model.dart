class QueueItemModel {
  final String localId;
  final String type;
  final String auid;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const QueueItemModel({
    required this.localId,
    required this.type,
    required this.auid,
    required this.data,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp).inDays > 7;

  factory QueueItemModel.fromJson(Map<String, dynamic> json) => QueueItemModel(
        localId: json['localId'] as String? ?? '',
        type: json['type'] as String? ?? '',
        auid: json['auid'] as String? ?? '',
        data: Map<String, dynamic>.from(
          json['data'] is Map ? json['data'] as Map : {},
        ),
        timestamp: DateTime.tryParse(
              json['timestamp'] as String? ?? '',
            ) ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'type': type,
        'auid': auid,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}
