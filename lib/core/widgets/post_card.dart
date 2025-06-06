import 'dart:io'; // Import untuk File

import 'package:flutter/material.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:get/get.dart'; // Untuk Get.snackbar

// Optional: For better date formatting
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
        // Menggunakan Card widget untuk efek elevasi dan rounded corners bawaan
        elevation: 4, // Sedikit elevasi
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias, // Penting untuk clipping gambar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPostImageSection(), // Bagian gambar postingan
            Padding(
              padding: const EdgeInsets.all(
                  12), // Padding sedikit lebih besar dan konsisten
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPosterInfo(), // Info pembuat postingan
                  const SizedBox(height: 12), // Jarak antar bagian
                  _buildPostTitle(), // Judul postingan
                  const SizedBox(height: 8),
                  _buildLocationInfo(), // Info lokasi
                  const SizedBox(height: 8),
                  _buildPostDescription(), // Deskripsi postingan
                  const SizedBox(height: 12), // Jarak sebelum divider
                  const Divider(
                      height: 1, color: Colors.grey), // Menggunakan Divider
                  _buildActionButtons(), // Tombol like, comment, save
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun bagian gambar postingan.
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
            // Menggunakan Image.file jika postImageFile tidak null, jika tidak tampilkan placeholder
            child: post.postImageFile != null &&
                    File(post.postImage!).existsSync() // Cek keberadaan file
                ? Image.file(
                    File(post
                        .postImage!), // Gunakan post.postImage (string path)
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(Icons
                            .broken_image), // Placeholder jika gambar rusak
                  )
                : _buildImagePlaceholder(
                    Icons.image), // Placeholder jika tidak ada gambar
          ),
          Positioned(
            top: 8, // Sedikit menjauh dari ujung
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: post.postPrice == 0
                    ? Colors.green.withAlpha(
                        (0.7 * 255).round()) // Opacity yang lebih jelas
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
                  const SizedBox(width: 4), // Jarak lebih baik
                  Text(
                    post.postPrice == 0
                        ? 'Gratis'
                        : 'Rp ${NumberFormat.compactSimpleCurrency(locale: 'id_ID', name: '').format(post.postPrice)}', // Format mata uang
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
        ],
      ),
    );
  }

  /// Membangun placeholder gambar.
  Widget _buildImagePlaceholder(IconData icon) {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: Icon(icon, size: 50, color: Colors.grey),
    );
  }

  /// Membangun bagian info poster.
  Widget _buildPosterInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100), // Bentuk lingkaran sempurna
          child: poster.photoFile != null &&
                  File(poster.photoFile!.path)
                      .existsSync() // Cek keberadaan file
              ? Image.file(
                  File(poster.photoFile!
                      .path), // Gunakan poster.photoUrl (string path)
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildProfilePlaceholder(), // Placeholder jika gambar rusak
                )
              : _buildProfilePlaceholder(), // Placeholder jika tidak ada gambar
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align ke kiri
            children: [
              Text(
                poster.username,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1, // Pastikan username tidak terlalu panjang
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatPostDate(
                    post.createdAt), // Gunakan fungsi format tanggal
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey, // Tambah warna abu-abu
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Membangun placeholder gambar profil.
  Widget _buildProfilePlaceholder() {
    return Container(
      width: 42,
      height: 42,
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 24, color: Colors.grey),
    );
  }

  /// Membangun bagian judul postingan.
  Widget _buildPostTitle() {
    return Text(
      post.postTitle,
      style: const TextStyle(
        fontSize: 18, // Ukuran sedikit lebih besar
        fontWeight: FontWeight.w700,
        color: Colors.black87, // Warna teks lebih gelap
      ),
      maxLines: 2, // Batasi jumlah baris
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Membangun bagian info lokasi.
  Widget _buildLocationInfo() {
    return GestureDetector(
      onTap: onLocationTap,
      child: Row(
        children: [
          const Icon(
            Icons.pin_drop_rounded,
            size: 18,
            color: Colors.blue, // Warna ikon lokasi yang lebih menonjol
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              post.detailLoc,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue, // Warna teks lokasi yang sama
              ),
              maxLines: 1, // Batasi 1 baris
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun bagian deskripsi postingan.
  Widget _buildPostDescription() {
    return Text(
      post.postDesc,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13, // Ukuran sedikit lebih besar
        color: Colors.black54, // Warna teks sedikit lebih terang
        height: 1.4, // Jarak antar baris
      ),
    );
  }

  /// Membangun baris tombol aksi (like, comment, save).
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Padding di atas divider
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
                  color: isLiked
                      ? Colors.red
                      : Colors.grey[700], // Warna default yang lebih gelap
                ),
                tooltip:
                    isLiked ? 'Batalkan Suka' : 'Suka Postingan Ini', // Tooltip
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  Get.snackbar(
                    'Informasi', // Menggunakan Get.snackbar untuk informasi
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

  /// Helper untuk memformat tanggal
  String _formatPostDate(DateTime dateTime) {
    // Requires intl package: dependency: intl: ^0.18.1
    // You can choose different formats
    final formatter =
        DateFormat('dd MMMM yyyy HH:mm'); // Example: 06 Juni 2025 06:04
    return formatter.format(dateTime.toLocal()); // Convert to local time
  }
}
