import 'package:cityxplore/app/routes/route_name.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> login() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Username dan password tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    final success = await _authService.loginUser(
      username: usernameController.text,
      password: passwordController.text,
    );
    isLoading.value = false;

    if (success) {
      Get.offAllNamed(RouteName.main);
    }
  }

  void goToRegister() {
    Get.toNamed(RouteName.register);
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
