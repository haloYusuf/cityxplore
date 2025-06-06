import 'dart:io'; // Required for File
import 'package:cityxplore/app/modules/detail/controllers/detail_post_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/data/models/post_model.dart'; // Explicit import for Post type
import 'package:cityxplore/app/data/models/user_model.dart'; // Explicit import for User type

class DetailPostView extends GetView<DetailPostController> {
  const DetailPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        centerTitle: true,
      ),
      body: Obx(
        () {
          // Show a loading indicator until poster data is loaded
          if (controller.poster.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once poster data is available, proceed to build the UI
          final post = controller.post;
          final poster = controller.poster.value!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostImageSection(post),
                const SizedBox(height: 16),
                _buildPostHeaderSection(post, poster),
                const SizedBox(height: 16),
                _buildPostDetailsSection(post),
                const SizedBox(height: 16),
                _buildDescriptionSection(post),
                const SizedBox(height: 24),
                _buildTimeZoneConversionSection(),
                const SizedBox(height: 24),
                _buildCurrencyConversionSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the main image section of the post.
  Widget _buildPostImageSection(Post post) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: post.postImageFile != null &&
              File(post.postImageFile!.path)
                  .existsSync() // Check if file exists
          ? Image.file(
              post.postImageFile!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(size: 80),
            )
          : _buildImagePlaceholder(
              icon: Icons.image,
              size: 80), // Fallback if no image file or corrupted
    );
  }

  /// Builds a placeholder for images when they are not available or fail to load.
  Widget _buildImagePlaceholder(
      {IconData icon = Icons.broken_image, double size = 50}) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[300],
      child: Icon(icon, size: size, color: Colors.grey),
    );
  }

  /// Builds the header section of the post, including the poster's profile picture,
  /// post title, and poster's username.
  Widget _buildPostHeaderSection(Post post, User poster) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100), // Circular profile picture
          child: poster.photoFile != null &&
                  File(poster.photoPath ?? '')
                      .existsSync() // Check if file exists
              ? Image.file(
                  poster.photoFile!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildProfilePlaceholder(),
                )
              : _buildProfilePlaceholder(), // Fallback if no profile picture or corrupted
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.postTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'oleh ${poster.username}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a placeholder for profile pictures.
  Widget _buildProfilePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 30, color: Colors.grey),
    );
  }

  /// Builds the section displaying post details like price and location.
  Widget _buildPostDetailsSection(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.monetization_on,
          post.postPrice == 0
              ? 'Gratis'
              : 'Rp ${post.postPrice.toStringAsFixed(0)}',
          color: post.postPrice == 0 ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: controller.launchLocationOnMap, // Tap to launch map
          child: _buildInfoRow(
            Icons.pin_drop,
            post.detailLoc,
            color: Colors.blue,
            decoration: TextDecoration.underline, // Underline location text
          ),
        ),
      ],
    );
  }

  /// Builds the post description section.
  Widget _buildDescriptionSection(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.postDesc,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  /// Builds the time zone conversion section with a dropdown.
  Widget _buildTimeZoneConversionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Post (Zona Waktu Lain):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Obx(() => Icon(
                  controller.getIconForSelectedTimeZone(),
                  size: 24,
                  color: Colors.grey,
                )),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => DropdownButton<String>(
                  // Value must be null if it's not present in items, to avoid assertion error
                  value: controller.availableTimeZoneNames
                          .contains(controller.selectedTimeZoneName.value)
                      ? controller.selectedTimeZoneName.value
                      : null,
                  onChanged: controller.changeTimeZone,
                  items: controller.availableTimeZoneNames
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  isExpanded: true,
                  underline: Container(), // Remove default underline
                  hint: controller.availableTimeZoneNames.isEmpty
                      ? const Text('Memuat zona waktu...') // Loading hint
                      : const Text('Pilih Zona Waktu'), // Default hint
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Text(
              controller.formattedSelectedTimeZoneTime.value,
              style: const TextStyle(fontSize: 14),
            )),
      ],
    );
  }

  /// Builds the currency conversion section with a dropdown.
  Widget _buildCurrencyConversionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga dalam Mata Uang Lain:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () {
            if (controller.isConvertingCurrency) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            // Otherwise, show the currency dropdown and converted price
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        // Value must be null if it's not present in items, to avoid assertion error
                        value: controller.availableCurrencyNames
                                .contains(controller.selectedCurrencyName.value)
                            ? controller.selectedCurrencyName.value
                            : null,
                        onChanged: controller.changeCurrency,
                        items: controller.availableCurrencyNames
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        isExpanded: true,
                        underline: Container(), // Remove default underline
                        hint: controller.availableCurrencyNames.isEmpty
                            ? const Text('Memuat mata uang...') // Loading hint
                            : const Text('Pilih Mata Uang'), // Default hint
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.getCurrencySymbol(controller.selectedCurrencyName.value)}${controller.displayConvertedPrice.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Builds the action buttons section (Like & Save).
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Obx(() => IconButton(
                onPressed: controller.toggleLike,
                icon: Icon(
                  controller.isLiked.value
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 30,
                  color: controller.isLiked.value ? Colors.red : Colors.grey,
                ),
              )),
        ),
        Expanded(
          child: Obx(() => IconButton(
                onPressed: controller.toggleSave,
                icon: Icon(
                  controller.isSaved.value
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border,
                  size: 30,
                  color: controller.isSaved.value ? Colors.blue : Colors.grey,
                ),
              )),
        ),
      ],
    );
  }

  /// Helper method to build an info row with an icon and text.
  Widget _buildInfoRow(IconData icon, String text,
      {Color? color, TextDecoration? decoration}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black,
              decoration: decoration,
            ),
          ),
        ),
      ],
    );
  }
}
