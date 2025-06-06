import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:cityxplore/app/routes/route_page.dart';
import 'package:cityxplore/core/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app/data/services/db_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Get.putAsync<DbHelper>(
    () async => DbHelper(),
    permanent: true,
  );
  await Get.putAsync<AuthService>(
    () async => await AuthService().init(),
    permanent: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  await _requestNotificationPermissions();
  runApp(MainApp());
}

Future<void> _requestNotificationPermissions() async {
  bool? granted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  if (granted == false) {
    showErrorMessage(
      'Agar aplikasi berfungsi optimal, mohon aktifkan izin notifikasi di pengaturan perangkat Anda.',
      title: 'Izin Notifikasi Diperlukan',
    );
  }
}

void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  Get.dialog(
    AlertDialog(
      title: Text(title ?? ''),
      content: Text(body ?? ''),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final dbHelper = Get.find<DbHelper>();
  // 1. Periksa apakah ada payload
  if (notificationResponse.payload != null &&
      notificationResponse.payload!.isNotEmpty) {
    debugPrint('Notification payload: ${notificationResponse.payload}');

    final int? postId = int.tryParse(notificationResponse.payload!);

    if (postId != null) {
      final Post? post = await dbHelper.getPostById(postId);

      if (post != null) {
        Get.toNamed(RouteName.detailPost, arguments: post);
      } else {
        Get.snackbar(
          'Error',
          'Postingan tidak ditemukan setelah mengetuk notifikasi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Data notifikasi tidak valid.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  } else {
    Get.snackbar(
      'Info',
      'Notifikasi tidak memiliki informasi detail.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey,
      colorText: Colors.white,
    );
  }
}

class MainApp extends StatelessWidget {
  MainApp({super.key});
  final authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CityXplore',
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      initialRoute:
          authService.currentUser == null ? RouteName.login : RouteName.main,
      getPages: RoutePage.listPages,
    );
  }
}
