import 'package:cityxplore/app/modules/auth/bindings/login_binding.dart';
import 'package:cityxplore/app/modules/auth/bindings/register_binding.dart';
import 'package:cityxplore/app/modules/auth/views/login_view.dart';
import 'package:cityxplore/app/modules/auth/views/register_view.dart';
import 'package:cityxplore/app/modules/detail/bindings/detail_post_binding.dart';
import 'package:cityxplore/app/modules/detail/views/detail_post_view.dart';
import 'package:cityxplore/app/modules/main/bindings/main_binding.dart';
import 'package:cityxplore/app/modules/main/views/main_view.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:get/get.dart';

class RoutePage {
  static List<GetPage<dynamic>> listPages = [
    GetPage(
      name: RouteName.main,
      binding: MainBinding(),
      page: () => const MainView(),
    ),
    GetPage(
      name: RouteName.login,
      binding: LoginBinding(),
      page: () => const LoginView(),
    ),
    GetPage(
      name: RouteName.register,
      binding: RegisterBinding(),
      page: () => const RegisterView(),
    ),
    GetPage(
      name: RouteName.detailPost,
      binding: DetailPostBinding(),
      page: () => const DetailPostView(),
    ),
  ];
}
