import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat
import 'package:flutter/material.dart'; // Untuk IconData

import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/modules/main/controllers/home_controller.dart';

class DetailPostController extends GetxController {
  final DbHelper _dbHelper = Get.find<DbHelper>();
  final HomeController _homeController = Get.find<HomeController>();

  late Post post; // Pastikan ini diinisialisasi melalui Get.arguments

  final Rx<User?> poster = Rx<User?>(null);

  final RxBool isLiked = false.obs;
  final RxBool isSaved = false.obs;

  // Data untuk Konversi Waktu
  final RxList<String> availableTimeZoneNames = <String>[].obs; // BARU: Inisialisasi RxList
  final RxString selectedTimeZoneName = ''.obs; // BARU: Inisialisasi RxString
  final RxString formattedSelectedTimeZoneTime = ''.obs; // BARU: Inisialisasi RxString

  // Map internal untuk menyimpan hasil format waktu (tidak diobservasi secara langsung)
  final Map<String, String> _formattedTimeByTimeZone = {};
  final Map<String, IconData> _iconByTimeZone = {};


  // Data untuk Konversi Mata Uang
  final RxList<String> availableCurrencyNames = <String>['USD', 'EUR', 'JPY'].obs; // BARU: Inisialisasi RxList
  final RxString selectedCurrencyName = 'USD'.obs; // BARU: Inisialisasi RxString
  final RxDouble displayConvertedPrice = 0.0.obs; // BARU: Inisialisasi RxDouble

  // Map internal untuk menyimpan hasil konversi mata uang
  final Map<String, double> _convertedCurrencyValues = {};

  @override
  void onInit() {
    super.onInit();
    // Penting: Pastikan post diinisialisasi sebelum memanggil _loadPostDetails
    if (Get.arguments is Post) {
      post = Get.arguments as Post;
      _loadPostDetails();
    } else {
      Get.back(); // Kembali jika tidak ada post yang diterima
      Get.snackbar('Error', 'Postingan tidak ditemukan.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _loadPostDetails() async {
    // Ambil data user pembuat post
    final user = await _dbHelper.getUserById(post.uid);
    poster.value = user;

    // Set status like dan save awal dari HomeController
    if (post.postId != null) {
      isLiked.value = _homeController.isPostLiked(post.postId!);
      isSaved.value = _homeController.isPostSaved(post.postId!);
    }

    _prepareTimeZones(); // Ganti _convertTimeZones menjadi _prepareTimeZones
    _prepareCurrencyConversions(); // Ganti _convertCurrency menjadi _prepareCurrencyConversions

    // Set nilai default setelah data disiapkan
    if (availableTimeZoneNames.isNotEmpty && selectedTimeZoneName.value.isEmpty) {
      selectedTimeZoneName.value = availableTimeZoneNames.first;
      _updateSelectedTimeZoneTime();
    }
    if (availableCurrencyNames.isNotEmpty && selectedCurrencyName.value.isEmpty) {
      // Set USD sebagai default jika ada, jika tidak, pakai yang pertama
      if (availableCurrencyNames.contains('USD')) {
        selectedCurrencyName.value = 'USD';
      } else {
        selectedCurrencyName.value = availableCurrencyNames.first;
      }
      _updateSelectedCurrencyPrice();
    }
  }

  // BARU: Metode untuk menyiapkan data zona waktu
  void _prepareTimeZones() {
    // Daftar zona waktu target dengan offset dari UTC (dalam jam)
    // Ini adalah offset tetap, tidak memperhitungkan Daylight Saving Time (DST)
    final Map<String, double> offsets = {
      'UTC': 0.0,
      'America/New_York': -5.0, // EST
      'Europe/London': 0.0,    // GMT
      'Asia/Tokyo': 9.0,       // JST
      'Asia/Singapore': 8.0,   // SST
      'Australia/Sydney': 10.0, // AEST
      'Asia/Jakarta': 7.0,     // WIB
    };

    final baseTimeUtc = post.createdAt.toUtc(); // Jadikan waktu dasar UTC

    _formattedTimeByTimeZone.clear();
    availableTimeZoneNames.clear();
    _iconByTimeZone.clear();

    // Tambahkan zona waktu asli postingan sebagai opsi pertama (jika ada)
    if (post.timeZone != null && post.timeZone!.isNotEmpty) {
      double originalOffsetHours = _getOffsetHoursForTimeZoneName(post.timeZone!);
      final originalTime = baseTimeUtc.add(Duration(hours: originalOffsetHours.toInt()));
      final formattedOriginalTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(originalTime);

      _formattedTimeByTimeZone['${post.timeZone!} (Original)'] = formattedOriginalTime;
      _iconByTimeZone['${post.timeZone!} (Original)'] = Icons.access_time;
      availableTimeZoneNames.add('${post.timeZone!} (Original)');
    }

    // Konversi ke zona waktu target lainnya
    for (String tzName in offsets.keys) {
      double offsetHours = offsets[tzName]!;

      // Hindari duplikasi jika zona waktu target sama dengan zona waktu asli postingan
      if (post.timeZone != null && tzName == post.timeZone) {
         continue;
      }

      try {
        final convertedTime = baseTimeUtc.add(Duration(hours: offsetHours.toInt()));
        final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').add_jm().format(convertedTime);

        _formattedTimeByTimeZone[tzName] = formattedTime;
        _iconByTimeZone[tzName] = _getIconForTimeZone(tzName);
        availableTimeZoneNames.add(tzName);
      } catch (e) {
        print('Error converting to $tzName: $e');
        _formattedTimeByTimeZone[tzName] = 'Error';
        _iconByTimeZone[tzName] = Icons.error;
        availableTimeZoneNames.add(tzName);
      }
    }
  }

  // Mendapatkan offset jam (bulat) berdasarkan nama zona waktu (sederhana)
  // Ini hanya untuk demo, tidak akurat untuk semua zona waktu/DST.
  double _getOffsetHoursForTimeZoneName(String tzName) {
    if (tzName.contains('New_York')) return -5.0;
    if (tzName.contains('London')) return 0.0;
    if (tzName.contains('Tokyo')) return 9.0;
    if (tzName.contains('Singapore')) return 8.0;
    if (tzName.contains('Sydney')) return 10.0;
    if (tzName.contains('Jakarta')) return 7.0;
    if (tzName.contains('UTC')) return 0.0;
    return 0.0; // Default atau jika tidak dikenal
  }

  // Mengupdate waktu yang ditampilkan berdasarkan selectedTimeZoneName
  void _updateSelectedTimeZoneTime() {
    formattedSelectedTimeZoneTime.value = _formattedTimeByTimeZone[selectedTimeZoneName.value] ?? 'Waktu tidak tersedia';
  }

  // Mengubah pilihan zona waktu dari dropdown
  void changeTimeZone(String? newTzName) {
    if (newTzName != null && availableTimeZoneNames.contains(newTzName)) {
      selectedTimeZoneName.value = newTzName;
      _updateSelectedTimeZoneTime();
    }
  }

  IconData getIconForSelectedTimeZone() {
    return _iconByTimeZone[selectedTimeZoneName.value] ?? Icons.error;
  }

  IconData _getIconForTimeZone(String tzName) {
    if (tzName.contains('Asia')) return Icons.travel_explore;
    if (tzName.contains('Europe')) return Icons.location_city;
    if (tzName.contains('America')) return Icons.landscape;
    if (tzName.contains('Australia')) return Icons.sunny;
    if (tzName.contains('UTC')) return Icons.public;
    return Icons.access_time;
  }

  // BARU: Metode untuk menyiapkan data konversi mata uang
  void _prepareCurrencyConversions() {
    final double idrPrice = post.postPrice;

    // Kurs konversi dummy (dalam aplikasi nyata, ini dari API eksternal)
    const double usdToIdrRate = 16000.0;
    const double eurToIdrRate = 17500.0;
    const double jpyToIdrRate = 100.0;

    _convertedCurrencyValues.clear();
    availableCurrencyNames.clear(); // Bersihkan daftar untuk dropdown

    _convertedCurrencyValues['IDR'] = idrPrice;
    _convertedCurrencyValues['USD'] = idrPrice / usdToIdrRate;
    _convertedCurrencyValues['EUR'] = idrPrice / eurToIdrRate;
    _convertedCurrencyValues['JPY'] = idrPrice / jpyToIdrRate;

    // Isi daftar nama mata uang untuk dropdown
    availableCurrencyNames.assignAll(_convertedCurrencyValues.keys.toList());
    
    // Pastikan IDR selalu di awal jika ada
    if (availableCurrencyNames.contains('IDR')) {
      availableCurrencyNames.remove('IDR');
      availableCurrencyNames.insert(0, 'IDR');
    }

    // Set nilai default setelah data disiapkan
    if (availableCurrencyNames.isNotEmpty && selectedCurrencyName.value.isEmpty) {
      // Set USD sebagai default jika ada, jika tidak, pakai yang pertama
      if (availableCurrencyNames.contains('USD')) {
        selectedCurrencyName.value = 'USD';
      } else {
        selectedCurrencyName.value = availableCurrencyNames.first;
      }
      _updateSelectedCurrencyPrice(); // Update harga yang ditampilkan
    }
  }

  // Mengupdate harga yang ditampilkan berdasarkan selectedCurrencyName
  void _updateSelectedCurrencyPrice() {
    displayConvertedPrice.value = _convertedCurrencyValues[selectedCurrencyName.value] ?? 0.0;
  }

  // Mengubah pilihan mata uang dari dropdown
  void changeCurrency(String? newCurrencyName) {
    if (newCurrencyName != null && availableCurrencyNames.contains(newCurrencyName)) {
      selectedCurrencyName.value = newCurrencyName;
      _updateSelectedCurrencyPrice();
    }
  }

  String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'IDR': return 'Rp';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'JPY': return '¥';
      default: return '';
    }
  }

  void toggleLike() {
    _homeController.toggleLike(post);
    isLiked.value = !isLiked.value;
  }

  void toggleSave() {
    _homeController.toggleSave(post);
    isSaved.value = !isSaved.value;
  }

  void launchLocationOnMap() {
    _homeController.launchGoogleMaps(post.latitude, post.longitude);
  }
}
