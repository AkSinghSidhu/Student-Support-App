class FeedbackModel {
  final String userId;
  final String department;
  final String teacher;
  final String category;
  final int rating;
  final String message;
  final String status;
  final String createdAt;

  const FeedbackModel({
    required this.userId,
    required this.department,
    required this.teacher,
    required this.category,
    required this.rating,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
        userId: json['userId'] as String? ?? '',
        department: json['department'] as String? ?? '',
        teacher: json['teacher'] as String? ?? '',
        category: json['category'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'department': department,
        'teacher': teacher,
        'category': category,
        'rating': rating,
        'message': message,
        'status': status,
        'createdAt': createdAt,
      };
}
