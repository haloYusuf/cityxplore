import 'dart:io';

class User {
  int? uid;
  String username;
  String email;
  String password;
  String? photoPath;
  DateTime createdAt;
  DateTime? updatedAt;

  User({
    this.uid,
    required this.username,
    required this.email,
    required this.password,
    this.photoPath,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      photoPath: map['photoPath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'password': password,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  File? get photoFile => photoPath != null ? File(photoPath!) : null;

  @override
  String toString() {
    return 'User(uid: $uid, username: $username, email: $email, photoPath: $photoPath)';
  }
}
