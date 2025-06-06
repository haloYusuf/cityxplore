import 'package:get/get.dart';

class InfoController extends GetxController {
  final RxMap<String, bool> isExpanded = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    isExpanded['kesan'] = false;
    isExpanded['pesan'] = false;
    isExpanded['developer'] = false;
  }

  void toggleExpanded(String cardId) {
    if (isExpanded.containsKey(cardId)) {
      isExpanded[cardId] = !isExpanded[cardId]!;
      _collapseOtherCards(
        cardId,
      );
    }
  }

  void _collapseOtherCards(String currentCardId) {
    isExpanded.forEach((key, value) {
      if (key != currentCardId && value == true) {
        isExpanded[key] = false;
      }
    });
  }

  String getKesanContent() {
    return 'Love Hate Relationship dengan Mobile Dev, kadang asik sendiri kadang kesel sendiri:)';
  }

  String getPesanContent() {
    return 'Semoga bisa lebih panjang waktunya:)';
  }

  // --- BARU: Data untuk Info Developer ---
  String getDeveloperPhotoAsset() {
    return 'assets/images/yusuf.jpg';
  }

  String getDeveloperName() {
    return 'Diandra Yusuf Arrafi';
  }

  String getDeveloperNIM() {
    return '123220031';
  }

  String getDeveloperBio() {
    return 'Saya adalah Diandra yusuf Arrafi, seorang pengembang aplikasi ini dengan NIM ${getDeveloperNIM()}. Semoga nilai saya (A)man';
  }
}
