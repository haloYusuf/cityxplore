import 'package:cityxplore/app/modules/detail/controllers/detail_post_controller.dart';
import 'package:get/get.dart';

class DetailPostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DetailPostController(),
    );
  }
}
