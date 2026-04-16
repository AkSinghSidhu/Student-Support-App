import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/models/models.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields', () {
      final u = UserModel.fromJson('123456789', {
        'name': 'John Doe',
        'department': 'Computer Science',
        'email': 'john@uni.edu',
        'password': 'secret123',
      });
      expect(u.auid, '123456789');
      expect(u.name, 'John Doe');
      expect(u.department, 'Computer Science');
      expect(u.email, 'john@uni.edu');
      expect(u.password, 'secret123');
    });

    test('defaults on empty json', () {
      final u = UserModel.fromJson('000', {});
      expect(u.auid, '000');
      expect(u.name, '');
      expect(u.department, '');
      expect(u.email, '');
      expect(u.password, '');
    });

    test('copyWith overrides specified fields only', () {
      final original = UserModel(
        auid: '111',
        name: 'Alice',
        department: 'ECE',
        email: 'alice@uni.edu',
        password: 'pw',
      );
      final copy = original.copyWith(name: 'Bob', department: 'CSE');
      expect(copy.auid, '111');
      expect(copy.name, 'Bob');
      expect(copy.department, 'CSE');
      expect(copy.email, 'alice@uni.edu');
      expect(copy.password, 'pw');
    });

    test('copyWith with no args returns equivalent object', () {
      final original = UserModel(
        auid: '222',
        name: 'Eve',
        department: 'ME',
        email: 'eve@uni.edu',
        password: 'pw2',
      );
      final copy = original.copyWith();
      expect(copy.auid, original.auid);
      expect(copy.name, original.name);
      expect(copy.department, original.department);
      expect(copy.email, original.email);
      expect(copy.password, original.password);
    });
  });
}
