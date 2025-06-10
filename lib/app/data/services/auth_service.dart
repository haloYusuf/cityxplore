import 'package:cityxplore/core/utils/password_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'dart:io';
import 'package:get_storage/get_storage.dart';

class AuthService extends GetxService {
  final DbHelper _dbHelper = Get.find<DbHelper>();
  final Rx<User?> _currentUser = Rx<User?>(null);
  User? get currentUser => _currentUser.value;
  Rx<User?> get currentUserRx => _currentUser;

  final GetStorage _box = GetStorage();
  static const String _userUidKey = 'current_user_uid';

  Future<AuthService> init() async {
    final int? savedUid = _box.read<int?>(_userUidKey);
    if (savedUid != null) {
      final user = await _dbHelper.getUserById(savedUid);
      if (user != null) {
        _currentUser.value = user;
      } else {
        _box.remove(_userUidKey);
      }
    }
    return this;
  }

  void updateCurrentUser(User user) {
    _currentUser.value = user;
  }

  Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
    File? photo,
  }) async {
    final existingUserByUsername = await _dbHelper.getUserByUsername(username);
    if (existingUserByUsername != null) {
      Get.snackbar(
        'Register Gagal',
        'Username sudah digunakan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    final existingUserByEmail = await _dbHelper.getUserByEmail(email);
    if (existingUserByEmail != null) {
      Get.snackbar(
        'Register Gagal',
        'Email sudah terdaftar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final hashedPassword = PasswordUtil.hashPassword(password);

    String? photoPath;
    if (photo != null) {
      photoPath = photo.path;
    }

    final newUser = User(
      username: username,
      email: email,
      password: hashedPassword,
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );

    try {
      final uid = await _dbHelper.insertUser(newUser);
      if (uid > 0) {
        _currentUser.value = newUser..uid = uid;
        _box.write(_userUidKey, uid);
        Get.snackbar(
          'Sukses',
          'Registrasi Berhasil!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registrasi Gagal: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return false;
  }

  Future<bool> loginUser({
    required String username,
    required String password,
  }) async {
    final user = await _dbHelper.getUserByUsername(username);

    if (user == null) {
      Get.snackbar(
        'Login Gagal',
        'Username tidak ditemukan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (PasswordUtil.verifyPassword(password, user.password)) {
      _currentUser.value = user;
      _box.write(_userUidKey, user.uid);
      Get.snackbar(
        'Login Sukses',
        'Selamat datang, ${user.username}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } else {
      Get.snackbar(
        'Login Gagal',
        'Password salah.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  void logout() {
    _currentUser.value = null;
    _box.remove(_userUidKey);
    Get.snackbar(
      'Logout',
      'Anda telah keluar.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
