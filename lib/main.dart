import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:cityxplore/app/routes/route_page.dart';
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
  runApp(MainApp());
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
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
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
