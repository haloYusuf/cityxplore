import 'dart:io'; // Import untuk File

import 'package:flutter/material.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final User poster;
  final VoidCallback onItemTap;
  final VoidCallback onLocationTap;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.poster,
    required this.onItemTap,
    required this.onLocationTap,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onItemTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPostImageSection(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPosterInfo(),
                  const SizedBox(height: 12),
                  _buildPostTitle(),
                  const SizedBox(height: 8),
                  _buildLocationInfo(),
                  const SizedBox(height: 8),
                  _buildPostDescription(),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.grey),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImageSection() {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child:
                post.postImageFile != null && File(post.postImage!).existsSync()
                    ? Image.file(
                        File(post.postImage!),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(Icons.broken_image),
                      )
                    : _buildImagePlaceholder(Icons.image),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: post.postPrice == 0
                    ? Colors.green.withAlpha((0.7 * 255).round())
                    : Colors.blue.withAlpha((0.7 * 255).round()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.postPrice == 0
                        ? 'Gratis'
                        : 'Rp ${NumberFormat.compactSimpleCurrency(locale: 'id_ID', name: '').format(post.postPrice)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(IconData icon) {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: Icon(icon, size: 50, color: Colors.grey),
    );
  }

  Widget _buildPosterInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: poster.photoFile != null &&
                  File(poster.photoFile!.path).existsSync()
              ? Image.file(
                  File(poster.photoFile!.path),
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildProfilePlaceholder(),
                )
              : _buildProfilePlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poster.username,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatPostDate(post.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      width: 42,
      height: 42,
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 24, color: Colors.grey),
    );
  }

  Widget _buildPostTitle() {
    return Text(
      post.postTitle,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocationInfo() {
    return GestureDetector(
      onTap: onLocationTap,
      child: Row(
        children: [
          const Icon(
            Icons.pin_drop_rounded,
            size: 18,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              post.detailLoc,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostDescription() {
    return Text(
      post.postDesc,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black54,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                  color: isLiked ? Colors.red : Colors.grey[700],
                ),
                tooltip: isLiked ? 'Batalkan Suka' : 'Suka Postingan Ini',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  Get.snackbar(
                    'Informasi',
                    'Fungsi komentar belum diimplementasikan',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.blueGrey,
                    colorText: Colors.white,
                  );
                },
                icon: Icon(
                  Icons.comment_outlined,
                  size: 24,
                  color: Colors.grey[700],
                ),
                tooltip: 'Lihat Komentar',
              ),
            ],
          ),
          IconButton(
            onPressed: onSave,
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
              size: 24,
              color: isSaved ? Colors.blue : Colors.grey[700],
            ),
            tooltip: isSaved ? 'Batalkan Simpan' : 'Simpan Postingan Ini',
          ),
        ],
      ),
    );
  }

  String _formatPostDate(DateTime dateTime) {
    final formatter = DateFormat('dd MMMM yyyy HH:mm');
    return formatter.format(dateTime.toLocal());
  }
}
