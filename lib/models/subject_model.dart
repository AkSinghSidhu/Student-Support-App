class SubjectModel {
  final String code;
  final String name;
  final int attended;
  final int total;

  double get percent => total > 0 ? (attended / total * 100) : 0.0;
  bool get isLow => percent < 75.0;
  String get percentFormatted => '${percent.toStringAsFixed(1)}%';

  const SubjectModel({
    required this.code,
    required this.name,
    required this.attended,
    required this.total,
  });

  factory SubjectModel.fromJson(String code, Map<String, dynamic> json) =>
      SubjectModel(
        code: code,
        name: json['name'] as String? ?? code,
        attended: (json['attended'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'attended': attended,
    'total': total,
  };
}
