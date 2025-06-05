import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cityxplore/app/data/services/api_service.dart';
import 'package:cityxplore/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:latlong2/latlong.dart';

class PostController extends GetxController {
  // Dependencies
  final AuthService _authService = Get.find<AuthService>();
  final DbHelper _dbHelper = Get.find<DbHelper>();
  final ApiService _apiService = ApiService();

  final Rx<CameraController?> _cameraController = Rx<CameraController?>(null);
  CameraController? get cameraController => _cameraController.value;

  final RxBool _isCameraInit = false.obs;
  bool get isCameraInit => _isCameraInit.value;

  final Rx<XFile?> _capturedImageFile = Rx<XFile?>(null);
  XFile? get capturedImageFile => _capturedImageFile.value;

  Timer? _mainTimer;
  var currentLocation = Rx<LatLng?>(null);
  String _curLat = '';
  String _curLong = '';

  List<CameraDescription> _cameras = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final RxBool isFree = false.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
    _initializeLocTracking();
    ever(isFree, (bool value) {
      if (value) {
        priceController.text = '0';
      }
    });
  }

  @override
  void onClose() {
    _cameraController.value?.dispose();
    titleController.dispose();
    priceController.dispose();
    descController.dispose();
    super.onClose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        Get.snackbar(
          'Error',
          'Tidak ada kamera yang ditemukan di perangkat ini.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        _isCameraInit.value = false;
        return;
      }

      CameraDescription defaultCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras[0],
      );

      _cameraController.value = CameraController(
        defaultCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController.value!.initialize();
      _isCameraInit.value = true;
      update();
    } on CameraException catch (e) {
      _isCameraInit.value = false;
      Get.snackbar(
        'Error Kamera',
        'Gagal inisialisasi kamera: ${e.description}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _initializeLocTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    _mainTimer = Timer.periodic(
      Duration(seconds: 1),
      (t) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          currentLocation.value = LatLng(
            position.latitude,
            position.longitude,
          );
          if (_curLat.isEmpty && _curLong.isEmpty) {
            _setCurrentValue(
              lat: position.latitude.toString(),
              long: position.longitude.toString(),
            );
          } else {
            if (_curLat != position.latitude.toString() ||
                _curLong != position.longitude.toString()) {
              _setCurrentValue(
                lat: position.latitude.toString(),
                long: position.longitude.toString(),
              );
            }
          }
        } catch (e) {
          _setCurrentEmpty();
          Get.snackbar(
            'Error!',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: Icon(
              Icons.error,
              color: Colors.white,
            ),
          );
        }
      },
    );
  }

  void _setCurrentValue({
    required String lat,
    required String long,
  }) {
    _curLat = lat;
    _curLong = long;
  }

  void _setCurrentEmpty() {
    _curLat = '';
    _curLong = '';
  }

  Future<void> takePhoto() async {
    if (!isCameraInit ||
        cameraController == null ||
        cameraController!.value.isTakingPicture) {
      Get.snackbar(
        'Perhatian',
        'Kamera belum siap atau sedang sibuk.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final XFile image = await cameraController!.takePicture();
      _capturedImageFile.value = image;
      Get.snackbar(
        'Sukses',
        'Foto berhasil diambil!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on CameraException catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil foto: ${e.description}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void resetImage() {
    _capturedImageFile.value = null;
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      Get.snackbar('Info', 'Hanya ada satu kamera yang tersedia.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white);
      return;
    }

    final CameraDescription currentCamera =
        _cameraController.value!.description;

    CameraDescription newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => _cameras[0],
    );

    await _cameraController.value?.dispose();

    _cameraController.value = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController.value!.initialize();
      _isCameraInit.value = true;
      update();
    } on CameraException catch (e) {
      _isCameraInit.value = false;
      Get.snackbar(
        'Error Kamera',
        'Gagal mengganti kamera: ${e.description}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void toggleFree() {
    isFree.value = !isFree.value;
    if (isFree.value) {
      priceController.text = '0';
      priceController.clearComposing();
    } else {
      priceController.clear();
    }
  }

  Future<void> _showLocalNotification(String title, String body,
      {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'com.cityxplore.new_post_alerts',
      'Postingan Baru',
      channelDescription: 'Notifikasi untuk postingan baru di CityXplore',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> sharePost() async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.uid == null) {
      Get.snackbar(
        'Error',
        'Anda harus login untuk membuat postingan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (capturedImageFile == null) {
      Get.snackbar(
        'Error',
        'Mohon ambil atau pilih gambar untuk postingan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Nama Tempat tidak boleh kosong.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (priceController.text.isEmpty && !isFree.value) {
      Get.snackbar(
        'Error',
        'Harga Masuk tidak boleh kosong jika tidak gratis.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (descController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Mohon tambahkan deskripsi postingan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      final double price =
          isFree.value ? 0.0 : (double.tryParse(priceController.text) ?? 0.0);
      String detailLoc = await _apiService.getDetailAddress(
        latitude: _curLat,
        longitude: _curLong,
      );
      final newPost = Post(
        uid: _authService.currentUser!.uid!,
        latitude: double.parse(_curLat),
        longitude: double.parse(_curLong),
        detailLoc: detailLoc,
        postTitle: titleController.text,
        postDesc: descController.text,
        postPrice: price,
        postImage: capturedImageFile!.path,
        createdAt: DateTime.now(),
      );

      final postId = await _dbHelper.insertPost(newPost);

      if (postId > 0) {
        await _showLocalNotification(
          'Postingan Berhasil!',
          'Postingan "${newPost.postTitle}" Anda telah berhasil dibagikan.',
          payload:
              postId.toString(), // Anda bisa meneruskan postId sebagai payload
        );
        resetImage();
        titleController.clear();
        priceController.clear();
        descController.clear();
        isFree.value = false;
      } else {
        Get.snackbar(
          'Error',
          'Gagal menyimpan postingan.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat membagikan postingan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
