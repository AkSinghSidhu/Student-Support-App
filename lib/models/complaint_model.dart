class ComplaintModel {
  final String userId;
  final String subject;
  final String description;
  final String type;
  final String urgency;
  final String status;
  final String createdAt;

  const ComplaintModel({
    required this.userId,
    required this.subject,
    required this.description,
    required this.type,
    required this.urgency,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
        userId: json['userId'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? '',
        urgency: json['urgency'] as String? ?? 'Low',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'subject': subject,
        'description': description,
        'type': type,
        'urgency': urgency,
        'status': status,
        'createdAt': createdAt,
      };
}
