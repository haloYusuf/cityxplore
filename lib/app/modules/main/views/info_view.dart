import 'package:cityxplore/app/modules/main/controllers/info_controller.dart';
import 'package:cityxplore/core/widgets/dropdown_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InfoView extends StatelessWidget {
  InfoView({super.key});
  final controller = Get.put(InfoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informasi Aplikasi',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DropdownCard(
              cardId: 'kesan',
              title: 'Kesan Pengguna',
              content: controller.getKesanContent(),
              isExpanded: controller.isExpanded,
            ),
            DropdownCard(
              cardId: 'pesan',
              title: 'Pesan dan Saran',
              content: controller.getPesanContent(),
              isExpanded: controller.isExpanded,
            ),
            Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Obx(
                () => Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Tentang Developer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      trailing: Icon(
                        controller.isExpanded['developer'] ?? false
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      onTap: () {
                        controller.toggleExpanded('developer');
                      },
                    ),
                    if (controller.isExpanded['developer'] ?? false)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50.0),
                              child: Image.asset(
                                controller.getDeveloperPhotoAsset(),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.getDeveloperName(),
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NIM: ${controller.getDeveloperNIM()}',
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Bio Developer (dari getDeveloperBio)
                            Text(
                              controller.getDeveloperBio(),
                              style: const TextStyle(fontSize: 14.0),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
