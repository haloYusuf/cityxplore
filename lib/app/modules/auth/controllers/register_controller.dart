import 'package:cityxplore/app/routes/route_name.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:cityxplore/app/data/services/auth_service.dart';

class RegisterController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Rx<File?> photoFile = Rx<File?>(null);
  final RxBool isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickPhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      photoFile.value = File(pickedFile.path);
    }
  }

  Future<void> register() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Semua kolom harus diisi.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Format email tidak valid.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    final success = await _authService.registerUser(
      username: usernameController.text,
      email: emailController.text,
      password: passwordController.text,
      photo: photoFile.value,
    );
    isLoading.value = false;

    if (success) {
      Get.offAllNamed(
        RouteName.main,
      );
    }
  }

  void goToLogin() {
    Get.back();
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
