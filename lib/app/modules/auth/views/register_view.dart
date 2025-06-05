import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/modules/auth/controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto Profil
              Obx(() => GestureDetector(
                    onTap: controller.pickPhoto,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: controller.photoFile.value != null
                          ? FileImage(controller.photoFile.value!)
                          : null,
                      child: controller.photoFile.value == null
                          ? Icon(Icons.camera_alt,
                              size: 50, color: Colors.grey[700])
                          : null,
                    ),
                  )),
              const SizedBox(height: 24),
              TextField(
                controller: controller.usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                    onPressed:
                        controller.isLoading.value ? null : controller.register,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register'),
                  )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.goToLogin,
                child: const Text('Sudah punya akun? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
