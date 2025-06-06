import 'package:cityxplore/core/widgets/error_dialog.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/modules/main/controllers/home_controller.dart';
import 'package:cityxplore/app/data/services/api_service.dart';

class DetailPostController extends GetxController {
  final DbHelper _dbHelper = Get.find<DbHelper>();
  final HomeController _homeController = Get.find<HomeController>();
  final ApiService _apiService = ApiService();

  late Post post;

  final Rx<User?> poster = Rx<User?>(null);
  final RxBool isLiked = false.obs;
  final RxBool isSaved = false.obs;

  final RxList<String> availableTimeZoneNames = <String>[].obs;
  final RxString selectedTimeZoneName = ''.obs;
  final RxString formattedSelectedTimeZoneTime = ''.obs;

  final Map<String, String> _formattedTimeByTimeZone = {};
  final Map<String, IconData> _iconByTimeZone = {};

  final RxList<String> availableCurrencyNames = <String>[].obs;
  final RxString selectedCurrencyName = ''.obs;
  final RxDouble displayConvertedPrice = 0.0.obs;

  final Map<String, double> _convertedCurrencyValues = {};
  final RxBool _isConvertingCurrency = false.obs;
  bool get isConvertingCurrency => _isConvertingCurrency.value;

  static const Map<String, double> _timeZoneOffsets = {
    'UTC': 0.0,
    'America/New_York': -5.0,
    'Europe/London': 0.0,
    'Asia/Tokyo': 9.0,
    'Asia/Singapore': 8.0,
    'Australia/Sydney': 10.0,
    'Asia/Jakarta': 7.0,
  };

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Post) {
      post = Get.arguments as Post;
      _loadPostDetails();
    } else {
      Get.back();
      showErrorMessage('Postingan tidak ditemukan atau data tidak valid.',
          title: 'Error Navigasi');
    }
  }

  Future<void> _loadPostDetails() async {
    try {
      final userFuture = _dbHelper.getUserById(post.uid);
      poster.value = await userFuture;

      if (post.postId != null) {
        isLiked.value = _homeController.isPostLiked(post.postId!);
        isSaved.value = _homeController.isPostSaved(post.postId!);
      }

      _prepareTimeZones();
      await _prepareCurrencyConversions();
      if (availableTimeZoneNames.isNotEmpty &&
          selectedTimeZoneName.value.isEmpty) {
        selectedTimeZoneName.value = availableTimeZoneNames.first;
      }
      _updateSelectedTimeZoneTime();

      if (availableCurrencyNames.isNotEmpty &&
          selectedCurrencyName.value.isEmpty) {
        if (availableCurrencyNames.contains('IDR')) {
          selectedCurrencyName.value = 'IDR';
        } else if (availableCurrencyNames.isNotEmpty) {
          selectedCurrencyName.value = availableCurrencyNames.first;
        }
      }
      _updateSelectedCurrencyPrice();
    } catch (e) {
      showErrorMessage('Gagal memuat detail postingan: $e',
          title: 'Error Detail Post');
    }
  }

  void _prepareTimeZones() {
    _formattedTimeByTimeZone.clear();
    availableTimeZoneNames.clear();
    _iconByTimeZone.clear();

    final baseTimeUtc = post.createdAt.toUtc();

    final Set<String> addedTimeZoneNames = {};

    if (post.timeZone != null && post.timeZone!.isNotEmpty) {
      final originalOffsetHours =
          _getOffsetHoursForTimeZoneName(post.timeZone!);
      final originalTime =
          baseTimeUtc.add(Duration(hours: originalOffsetHours.toInt()));
      final formattedOriginalTime =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(originalTime);

      final originalTzOption = '${post.timeZone!} (Original)';
      _formattedTimeByTimeZone[originalTzOption] = formattedOriginalTime;
      _iconByTimeZone[originalTzOption] = Icons.access_time;
      availableTimeZoneNames.add(originalTzOption);
      addedTimeZoneNames.add(originalTzOption);
    }

    // Convert and add other predefined time zones
    for (final entry in _timeZoneOffsets.entries) {
      final String tzName = entry.key;
      final double offsetHours = entry.value;

      if (addedTimeZoneNames.contains(tzName) ||
          (post.timeZone != null &&
              tzName == post.timeZone &&
              tzName != "UTC")) {
        continue;
      }

      try {
        final convertedTime =
            baseTimeUtc.add(Duration(hours: offsetHours.toInt()));
        final formattedTime =
            DateFormat('dd/MM/yyyy HH:mm:ss').format(convertedTime);

        _formattedTimeByTimeZone[tzName] = formattedTime;
        _iconByTimeZone[tzName] = _getIconForTimeZone(tzName);
        availableTimeZoneNames.add(tzName);
        addedTimeZoneNames.add(tzName);
      } catch (e) {
        _formattedTimeByTimeZone[tzName] = 'Error';
        _iconByTimeZone[tzName] = Icons.error;
        availableTimeZoneNames.add(tzName);
        addedTimeZoneNames.add(tzName);
      }
    }

    if (selectedTimeZoneName.value.isEmpty &&
        availableTimeZoneNames.isNotEmpty) {
      selectedTimeZoneName.value = availableTimeZoneNames.first;
    }
  }

  double _getOffsetHoursForTimeZoneName(String tzName) {
    return _timeZoneOffsets[tzName] ?? 0.0;
  }

  void _updateSelectedTimeZoneTime() {
    formattedSelectedTimeZoneTime.value =
        _formattedTimeByTimeZone[selectedTimeZoneName.value] ??
            'Waktu tidak tersedia';
  }

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

  Future<void> _prepareCurrencyConversions() async {
    _isConvertingCurrency.value = true;
    _convertedCurrencyValues.clear();
    availableCurrencyNames.clear();

    final double idrPrice = post.postPrice;

    final Set<String> addedCurrencyNames = {};

    _convertedCurrencyValues['IDR'] = idrPrice;
    availableCurrencyNames.add('IDR');
    addedCurrencyNames.add('IDR');

    try {
      final Map<String, double>? apiRates =
          await _apiService.getExchangeRates(baseCurrency: 'USD');

      if (apiRates != null && apiRates.containsKey('IDR')) {
        final double idrToUsdRate = apiRates['IDR']!;
        final double priceInUsd = idrPrice / idrToUsdRate;

        if (!addedCurrencyNames.contains('USD')) {
          _convertedCurrencyValues['USD'] = priceInUsd;
          availableCurrencyNames.add('USD');
          addedCurrencyNames.add('USD');
        }
        if (apiRates.containsKey('EUR') &&
            !addedCurrencyNames.contains('EUR')) {
          _convertedCurrencyValues['EUR'] = priceInUsd * apiRates['EUR']!;
          availableCurrencyNames.add('EUR');
          addedCurrencyNames.add('EUR');
        }
        if (apiRates.containsKey('JPY') &&
            !addedCurrencyNames.contains('JPY')) {
          _convertedCurrencyValues['JPY'] = priceInUsd * apiRates['JPY']!;
          availableCurrencyNames.add('JPY');
          addedCurrencyNames.add('JPY');
        }

        availableCurrencyNames.sort((a, b) {
          if (a == 'IDR') return -1;
          if (b == 'IDR') return 1;
          if (a == 'USD') return -1;
          if (b == 'USD') return 1;
          return a.compareTo(b);
        });
      } else {
        showErrorMessage(
            'Gagal mendapatkan kurs mata uang terbaru. Menggunakan nilai default.',
            title: 'Error Kurs');
        _addFallbackCurrencies(idrPrice, addedCurrencyNames);
      }
    } catch (e) {
      showErrorMessage('Terjadi kesalahan saat mengambil kurs mata uang: $e',
          title: 'Error Koneksi Kurs');
      _addFallbackCurrencies(idrPrice, addedCurrencyNames);
    } finally {
      _isConvertingCurrency.value = false;
    }

    if (selectedCurrencyName.value.isEmpty &&
        availableCurrencyNames.isNotEmpty) {
      selectedCurrencyName.value = availableCurrencyNames.first;
    }
  }

  void _addFallbackCurrencies(double idrPrice, Set<String> addedCurrencyNames) {
    if (!addedCurrencyNames.contains('USD')) {
      _convertedCurrencyValues['USD'] = idrPrice / 16000.0;
      availableCurrencyNames.add('USD');
      addedCurrencyNames.add('USD');
    }
    if (!addedCurrencyNames.contains('EUR')) {
      _convertedCurrencyValues['EUR'] = idrPrice / 17500.0;
      availableCurrencyNames.add('EUR');
      addedCurrencyNames.add('EUR');
    }
    if (!addedCurrencyNames.contains('JPY')) {
      _convertedCurrencyValues['JPY'] = idrPrice / 100.0;
      availableCurrencyNames.add('JPY');
      addedCurrencyNames.add('JPY');
    }
    availableCurrencyNames.sort((a, b) {
      if (a == 'IDR') return -1;
      if (b == 'IDR') return 1;
      return a.compareTo(b);
    });
  }

  void _updateSelectedCurrencyPrice() {
    displayConvertedPrice.value =
        _convertedCurrencyValues[selectedCurrencyName.value] ?? 0.0;
  }

  void changeCurrency(String? newCurrencyName) {
    if (newCurrencyName != null &&
        availableCurrencyNames.contains(newCurrencyName)) {
      selectedCurrencyName.value = newCurrencyName;
      _updateSelectedCurrencyPrice();
    }
  }

  String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'IDR':
        return 'Rp';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      default:
        return '';
    }
  }

  void toggleLike() {
    isLiked.value = !isLiked.value;
    _homeController.toggleLike(post);
  }

  void toggleSave() {
    isSaved.value = !isSaved.value;
    _homeController.toggleSave(post);
  }

  void launchLocationOnMap() {
    _homeController.launchGoogleMaps(post.latitude, post.longitude);
  }
}
