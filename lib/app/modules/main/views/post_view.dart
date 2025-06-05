import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cityxplore/app/modules/main/controllers/post_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostView extends StatelessWidget {
  PostView({super.key});
  final controller = Get.put(PostController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bagikan Tempat Baru',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Obx(
              () => ElevatedButton(
                onPressed:
                    controller.isLoading.value ? null : controller.sharePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Bagikan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 325,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: Obx(
                    () {
                      if (controller.capturedImageFile != null) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(controller.capturedImageFile!.path),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 325,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: double.infinity,
                                  height: 325,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 25,
                              child: GestureDetector(
                                onTap: controller.resetImage,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (controller.isCameraInit &&
                          controller.cameraController != null) {
                        return Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 325,
                              child: FittedBox(
                                fit: BoxFit.fitHeight,
                                child: SizedBox(
                                  width: controller.cameraController!.value
                                      .previewSize!.height,
                                  height: controller.cameraController!.value
                                      .previewSize!.width,
                                  child: CameraPreview(
                                    controller.cameraController!,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 25,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: controller.takePhoto,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(
                                        (0.5 * 255).round(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Nama Tempat'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.titleController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Masukkan Nama Tempat',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Harga Masuk'),
                    const SizedBox(height: 8),
                    Obx(
                      () => TextField(
                        controller: controller.priceController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) {
                          if (controller.isFree.value) {
                            controller.priceController.text = '0';
                          }
                        },
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            color: Colors.grey,
                          ),
                          hintText: '0',
                          suffixIcon: TextButton(
                            onPressed: controller.toggleFree,
                            child: Text(
                              controller.isFree.value
                                  ? 'Tidak Gratis'
                                  : 'Gratis',
                              style: TextStyle(
                                color: controller.isFree.value
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Deskripsi Singkat'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.descController,
                      maxLines: 7,
                      maxLength: 250,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Masukkan deskripsi singkat.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
