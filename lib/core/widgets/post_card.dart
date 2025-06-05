import 'package:flutter/material.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:get/get.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final User poster;
  final VoidCallback onLocationTap;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.poster,
    required this.onLocationTap,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: post.postImageFile != null
                      ? Image.file(
                          post.postImageFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: post.postPrice == 0
                            ? Colors.green.withAlpha((0.5 * 255).round())
                            : Colors.blue.withAlpha((0.5 * 255).round()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            post.postPrice == 0
                                ? 'Gratis'
                                : 'Rp ${post.postPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: poster.photoFile != null
                          ? Image.file(
                              poster.photoFile!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 42,
                                height: 42,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person,
                                    size: 24, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 42,
                              height: 42,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person,
                                  size: 24, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            poster.username,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${post.createdAt.toIso8601String().substring(0, 10)} ${post.createdAt.toIso8601String().substring(11, 19)}',
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.postTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.detailLoc,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.postDesc,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Container(
                  height: 1,
                  color: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: onLike,
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 24,
                            color: isLiked ? Colors.red : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            Get.snackbar('Komentar',
                                'Fungsi komentar belum diimplementasikan');
                          },
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(
                            Icons.comment_outlined,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: onSave,
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border,
                        size: 24,
                        color: isSaved ? Colors.blue : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
