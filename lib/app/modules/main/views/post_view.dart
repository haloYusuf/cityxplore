import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cityxplore/app/modules/main/controllers/post_controller.dart';
import 'package:cityxplore/core/utils/price_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
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
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildCameraAndImageViewer(),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Nama Tempat',
                  controller: controller.titleController,
                  hintText: 'Masukkan Nama Tempat',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                _buildPriceInputField(),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Deskripsi Singkat',
                  controller: controller.descController,
                  hintText: 'Masukkan deskripsi singkat.',
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  maxLines: 7,
                  maxLength: 250,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraAndImageViewer() {
    return Container(
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
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 325,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                        color: Colors.black54,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 30,
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
                  child: GetBuilder<PostController>(
                    builder: (_) {
                      if (!controller.cameraController!.value.isInitialized) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      return FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          width: controller
                              .cameraController!.value.previewSize!.height,
                          height: controller
                              .cameraController!.value.previewSize!.width,
                          child: CameraPreview(controller.cameraController!),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'switchCameraBtn',
                        mini: true,
                        backgroundColor:
                            Colors.white.withAlpha((0.5 * 255).round()),
                        onPressed: controller.switchCamera,
                        child:
                            const Icon(Icons.cameraswitch, color: Colors.blue),
                      ),
                      GestureDetector(
                        onTap: controller.takePhoto,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            color: Colors.white.withAlpha((0.5 * 255).round()),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'placeholderBtn',
                        mini: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        onPressed: () {},
                        child: const Icon(Icons.cameraswitch,
                            color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Container(
              alignment: Alignment.center,
              color: Colors.grey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    controller.isCameraInit
                        ? 'Kamera siap, menunggu preview...'
                        : 'Menginisialisasi kamera...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Harga Masuk'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => TextField(
                  controller: controller.priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  enabled: !controller.isFree.value,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    PriceInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => ElevatedButton(
                onPressed: controller.toggleFree,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      controller.isFree.value ? Colors.red : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  controller.isFree.value ? 'Tidak Gratis' : 'Gratis',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
