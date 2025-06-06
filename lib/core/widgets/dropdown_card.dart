// lib/app/core/components/dropdown_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/modules/main/controllers/info_controller.dart';

class DropdownCard extends StatelessWidget {
  final String cardId;
  final String title;
  final String content;
  final RxMap<String, bool> isExpanded;

  const DropdownCard({
    super.key,
    required this.cardId,
    required this.title,
    required this.content,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Obx(
        () => Column(
          children: [
            ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              trailing: Icon(
                isExpanded[cardId] ?? false
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              onTap: () {
                Get.find<InfoController>().toggleExpanded(cardId);
              },
            ),
            if (isExpanded[cardId] ?? false)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 14.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
