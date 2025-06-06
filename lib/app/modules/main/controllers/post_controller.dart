import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cityxplore/app/data/services/api_service.dart';
import 'package:cityxplore/core/utils/price_input_formatter.dart';
import 'package:cityxplore/core/widgets/error_dialog.dart';
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

  // Observable properties
  final Rx<CameraController?> _cameraController = Rx<CameraController?>(null);
  CameraController? get cameraController => _cameraController.value;

  final RxBool _isCameraInit = false.obs;
  bool get isCameraInit => _isCameraInit.value;

  final Rx<XFile?> _capturedImageFile = Rx<XFile?>(null);
  XFile? get capturedImageFile => _capturedImageFile.value;

  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  String _curLat = '';
  String _curLong = '';

  List<CameraDescription> _cameras = [];

  // Text editing controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final RxBool isFree = false.obs;

  final RxBool isLoading = false.obs;

  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
    _initializeLocTracking();
    // Hapus ever listener ini karena formatter akan menangani tampilan '0'
    // saat isFree berubah.
    // ever(isFree, (bool value) {
    //   if (value) {
    //     priceController.text = '0';
    //   }
    // });
  }

  @override
  void onClose() {
    _cameraController.value?.dispose();
    titleController.dispose();
    priceController.dispose();
    descController.dispose();
    _locationTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        showErrorMessage(
          'Tidak ada kamera yang ditemukan di perangkat ini.',
          title: 'Error Kamera',
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
      showErrorMessage(
        'Gagal inisialisasi kamera: ${e.description}',
        title: 'Error Kamera',
      );
    } catch (e) {
      _isCameraInit.value = false;
      showErrorMessage(
        'Terjadi kesalahan tak terduga saat inisialisasi kamera: $e',
        title: 'Error Kamera',
      );
    }
  }

  void _initializeLocTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showErrorMessage(
          'Aplikasi membutuhkan izin lokasi untuk berfungsi dengan baik.',
          title: 'Izin Lokasi Ditolak',
        );
        return;
      }
    }

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          currentLocation.value = LatLng(
            position.latitude,
            position.longitude,
          );
          if ((_curLat != position.latitude.toStringAsFixed(6) ||
              _curLong != position.longitude.toStringAsFixed(6))) {
            _setCurrentValue(
              lat: position.latitude.toString(),
              long: position.longitude.toString(),
            );
          }
        } catch (e) {
          _setCurrentEmpty();
          showErrorMessage(
            'Gagal mendapatkan lokasi saat ini: $e',
            title: 'Error Lokasi',
          );
          _locationTimer?.cancel();
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
    update();
  }

  void _setCurrentEmpty() {
    _curLat = '';
    _curLong = '';
    update();
  }

  Future<void> takePhoto() async {
    if (!isCameraInit ||
        cameraController == null ||
        cameraController!.value.isTakingPicture) {
      showErrorMessage(
        'Kamera belum siap atau sedang sibuk.',
        title: 'Perhatian',
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
      showErrorMessage(
        'Gagal mengambil foto: ${e.description}',
        title: 'Error',
      );
    } catch (e) {
      showErrorMessage(
        'Terjadi kesalahan tak terduga saat mengambil foto: $e',
        title: 'Error',
      );
    }
  }

  void resetImage() {
    _capturedImageFile.value = null;
    update();
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

    final int currentIndex = _cameras.indexOf(currentCamera);
    final int nextIndex = (currentIndex + 1) % _cameras.length;
    CameraDescription newCamera = _cameras[nextIndex];

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
      showErrorMessage(
        'Gagal mengganti kamera: ${e.description}',
        title: 'Error Kamera',
      );
    } catch (e) {
      _isCameraInit.value = false;
      showErrorMessage(
        'Terjadi kesalahan tak terduga saat mengganti kamera: $e',
        title: 'Error Kamera',
      );
    }
  }

  void toggleFree() {
    isFree.value = !isFree.value;
    if (isFree.value) {
      priceController.text = '0';
      priceController.selection = TextSelection.collapsed(
          offset: priceController.text.length); // Pindahkan kursor ke akhir
    } else {
      priceController.clear();
    }
    update();
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
      showErrorMessage(
        'Anda harus login untuk membuat postingan.',
        title: 'Autentikasi Diperlukan',
      );
      return;
    }
    if (capturedImageFile == null) {
      showErrorMessage(
        'Mohon ambil atau pilih gambar untuk postingan.',
        title: 'Gambar Diperlukan',
      );
      return;
    }
    if (titleController.text.trim().isEmpty) {
      showErrorMessage(
        'Nama Tempat tidak boleh kosong.',
        title: 'Validasi Input',
      );
      return;
    }
    if (priceController.text.trim().isEmpty && !isFree.value) {
      showErrorMessage(
        'Harga Masuk tidak boleh kosong jika tidak gratis.',
        title: 'Validasi Input',
      );
      return;
    }
    if (descController.text.trim().isEmpty) {
      showErrorMessage(
        'Mohon tambahkan deskripsi postingan.',
        title: 'Validasi Input',
      );
      return;
    }
    if (currentLocation.value == null ||
        (_curLat.isEmpty || _curLong.isEmpty)) {
      showErrorMessage(
        'Tidak dapat menentukan lokasi saat ini. Pastikan GPS aktif dan izin diberikan.',
        title: 'Error Lokasi',
      );
      return;
    }

    // Ambil nilai numerik dari priceController.text setelah diformat
    final String cleanPriceText =
        priceController.text.replaceAll(RegExp(r'\D'), '');
    final double price =
        isFree.value ? 0.0 : (double.tryParse(cleanPriceText) ?? 0.0);

    // Validasi batas harga maksimum
    if (price > PriceInputFormatter.maxPrice) {
      showErrorMessage(
        'Harga melebihi batas maksimum yang diizinkan (${PriceInputFormatter.maxPrice.toStringAsFixed(0)}).',
        title: 'Harga Tidak Valid',
      );
      return;
    }

    isLoading.value = true;

    try {
      final Future<String> detailLocFuture = _apiService.getDetailAddress(
        latitude: _curLat,
        longitude: _curLong,
      );

      final Future<Map<String, dynamic>?> timezoneResponseFuture =
          _apiService.getTimeZone(
        latitude: double.tryParse(_curLat) ?? 0.0,
        longitude: double.tryParse(_curLong) ?? 0.0,
      );

      final List<dynamic> results = await Future.wait([
        detailLocFuture,
        timezoneResponseFuture,
      ]);

      final String detailLoc = results[0];
      final Map<String, dynamic>? timezoneResponse = results[1];

      String timeZoneName = 'N/A';
      DateTime postCreatedAt = DateTime.now();

      if (timezoneResponse != null && timezoneResponse['time_zone'] != null) {
        timeZoneName = timezoneResponse['time_zone']['name'] ?? 'N/A';
        String dateTimeString = timezoneResponse['time_zone']['date_time'];
        try {
          postCreatedAt = DateTime.parse(dateTimeString.replaceAll(' ', 'T'));
        } catch (e) {
          debugPrint(
              'Failed to parse timezone date_time string: $e. Using current local time.');
          postCreatedAt = DateTime.now();
        }
      } else {
        debugPrint(
            'Failed to get timezone from API, using current local time and N/A timezone.');
      }

      final newPost = Post(
        uid: _authService.currentUser!.uid!,
        latitude: double.parse(_curLat),
        longitude: double.parse(_curLong),
        detailLoc: detailLoc,
        postTitle: titleController.text.trim(),
        postDesc: descController.text.trim(),
        postPrice: price, // Gunakan harga yang sudah dibersihkan dan divalidasi
        postImage: capturedImageFile!.path,
        createdAt: postCreatedAt,
        timeZone: timeZoneName,
      );

      final postId = await _dbHelper.insertPost(newPost);

      if (postId > 0) {
        await _showLocalNotification(
          'Postingan Berhasil!',
          'Postingan "${newPost.postTitle}" Anda telah berhasil dibagikan.',
          payload: postId.toString(),
        );
        resetImage();
        titleController.clear();
        priceController.clear();
        descController.clear();
        isFree.value = false;
        Get.back();
      } else {
        showErrorMessage(
          'Gagal menyimpan postingan. Terjadi masalah dengan database.',
          title: 'Gagal Posting',
        );
      }
    } catch (e) {
      showErrorMessage(
        'Terjadi kesalahan saat membagikan postingan: $e',
        title: 'Error Posting',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
