import 'package:cityxplore/app/modules/detail/controllers/detail_post_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailPostView extends GetView<DetailPostController> {
  const DetailPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () {
            // Tampilkan loading spinner jika post atau poster belum dimuat
            if (controller.poster.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final post = controller.post;
            final poster = controller.poster.value!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Postingan
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: post.postImageFile != null
                      ? Image.file(
                          post.postImageFile!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 16),

                // Informasi Poster dan Judul
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: poster.photoFile != null
                          ? Image.file(
                              poster.photoFile!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 30, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 30, color: Colors.grey),
                            ),
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
                ),
                const SizedBox(height: 16),

                // Detail Harga dan Lokasi
                _buildInfoRow(
                  Icons.monetization_on,
                  post.postPrice == 0 ? 'Gratis' : 'Rp ${post.postPrice.toStringAsFixed(0)}',
                  color: post.postPrice == 0 ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: controller.launchLocationOnMap,
                  child: _buildInfoRow(
                    Icons.pin_drop,
                    post.detailLoc,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 16),

                // Deskripsi Postingan
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
                const SizedBox(height: 24),

                // Konversi Waktu dengan Dropdown (Tampilan Vertikal)
                const Text(
                  'Waktu Post (Zona Waktu Lain):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column( // BARU: Column untuk tata letak vertikal
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row( // Baris untuk ikon dan dropdown
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
                              value: controller.selectedTimeZoneName.value,
                              onChanged: controller.changeTimeZone,
                              items: controller.availableTimeZoneNames.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              isExpanded: true,
                              underline: Container(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // BARU: Jarak antara dropdown dan nilai
                    Obx(() => Text(
                          controller.formattedSelectedTimeZoneTime.value, // Nilai waktu yang dipilih
                          style: const TextStyle(fontSize: 14),
                        )),
                  ],
                ),
                const SizedBox(height: 24),

                // Konversi Mata Uang dengan Dropdown (Tampilan Vertikal)
                const Text(
                  'Harga dalam Mata Uang Lain:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column( // BARU: Column untuk tata letak vertikal
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row( // BARU: Row untuk dropdown
                      children: [
                        Expanded(
                          child: Obx(
                            () => DropdownButton<String>(
                              value: controller.selectedCurrencyName.value,
                              onChanged: controller.changeCurrency,
                              items: controller.availableCurrencyNames.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              isExpanded: true,
                              underline: Container(),
                            ),
                          ),
                        ),
                        // Tidak ada SizedBox(width: 8) di sini karena nilai ada di baris baru
                      ],
                    ),
                    const SizedBox(height: 8), // BARU: Jarak antara dropdown dan nilai
                    Obx(() => Text(
                          // Nilai mata uang yang dipilih
                          '${controller.getCurrencySymbol(controller.selectedCurrencyName.value)}${controller.displayConvertedPrice.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        )),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Aksi (Like & Save)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Obx(() => IconButton(
                            onPressed: controller.toggleLike,
                            icon: Icon(
                              controller.isLiked.value ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 30,
                              color: controller.isLiked.value ? Colors.red : Colors.grey,
                            ),
                          )),
                    ),
                    Expanded(
                      child: Obx(() => IconButton(
                            onPressed: controller.toggleSave,
                            icon: Icon(
                              controller.isSaved.value ? Icons.bookmark_rounded : Icons.bookmark_border,
                              size: 30,
                              color: controller.isSaved.value ? Colors.blue : Colors.grey,
                            ),
                          )),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color, TextDecoration? decoration}) {
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
