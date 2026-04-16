import 'package:flutter/foundation.dart';

class UserModel {
  final String auid;
  final String name;
  final String department;
  final String email;
  final String password;

  const UserModel({
    required this.auid,
    required this.name,
    required this.department,
    required this.email,
    required this.password,
  });

  factory UserModel.fromJson(String auid, Map<String, dynamic> json) =>
      UserModel(
        auid: auid,
        name: json['name'] as String? ?? '',
        department: json['department'] as String? ?? '',
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'department': department,
    'email': email,
    if (!kReleaseMode) 'password': password,
  };

  UserModel copyWith({
    String? auid,
    String? name,
    String? department,
    String? email,
    String? password,
  }) =>
      UserModel(
        auid: auid ?? this.auid,
        name: name ?? this.name,
        department: department ?? this.department,
        email: email ?? this.email,
        password: password ?? this.password,
      );
}
