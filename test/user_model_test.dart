import 'package:flutter_test/flutter_test.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'dart:io'; // Import for File, though actual test might mock this

void main() {
  group('UserModel', () {
    final Map<String, dynamic> validUserMap = {
      'uid': 1,
      'username': 'testuser',
      'email': 'test@example.com',
      'password': 'hashed_password_123',
      'photoPath': '/path/to/profile_pic.png',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final Map<String, dynamic> validUserMapWithoutPhoto = {
      'uid': 2,
      'username': 'anotheruser',
      'email': 'another@example.com',
      'password': 'hashed_password_456',
      'photoPath': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': null,
    };

    test('should create a UserModel instance correctly from a valid Map', () {
      final user = User.fromMap(validUserMap);

      expect(user.uid, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.password, 'hashed_password_123');
      expect(user.photoPath, '/path/to/profile_pic.png');
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
      expect(user.photoFile, isA<File>());
    });

    test('should handle null photoPath and updatedAt gracefully', () {
      final user = User.fromMap(validUserMapWithoutPhoto);

      expect(user.uid, 2);
      expect(user.username, 'anotheruser');
      expect(user.photoPath, isNull);
      expect(user.updatedAt, isNull);
      expect(user.photoFile, isNull);
    });

    test('should throw an error if required fields are missing in fromMap', () {
      final Map<String, dynamic> invalidMapMissingUsername = {
        'uid': 3,
        'email': 'missing@example.com',
        'password': 'abc',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      expect(() => User.fromMap(invalidMapMissingUsername), throwsA(isA<TypeError>()));
    });

    test('should convert UserModel instance to a Map correctly (toMap)', () {
      final user = User(
        uid: 4,
        username: 'tomapuser',
        email: 'tomap@example.com',
        password: 'hashed_password',
        photoPath: '/path/to/tomap_pic.png',
        createdAt: DateTime(2023, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0, 0),
      );

      final map = user.toMap();

      expect(map['uid'], 4);
      expect(map['username'], 'tomapuser');
      expect(map['email'], 'tomap@example.com');
      expect(map['password'], 'hashed_password');
      expect(map['photoPath'], '/path/to/tomap_pic.png');
      expect(map['createdAt'], '2023-01-01T10:00:00.000');
      expect(map['updatedAt'], '2023-01-01T11:00:00.000');
    });

    test('toMap should handle null photoPath and updatedAt gracefully', () {
      final user = User(
        uid: 5,
        username: 'nullfielduser',
        email: 'nullfield@example.com',
        password: 'pass',
        createdAt: DateTime(2024, 5, 10),
        photoPath: null,
        updatedAt: null,
      );

      final map = user.toMap();

      expect(map['photoPath'], isNull);
      expect(map['updatedAt'], isNull);
    });

  });
}