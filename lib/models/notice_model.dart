class NoticeModel {
  final String id;
  final String title;
  final String category;
  final String date;
  final bool important;
  final String createdAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.important,
    required this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        date: json['date'] as String? ?? '',
        important: json['important'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date,
        'important': important,
        'createdAt': createdAt,
      };
}
