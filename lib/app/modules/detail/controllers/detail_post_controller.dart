import 'package:cityxplore/core/widgets/error_dialog.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:flutter/material.dart'; // Required for IconData

import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/modules/main/controllers/home_controller.dart';
import 'package:cityxplore/app/data/services/api_service.dart';

class DetailPostController extends GetxController {
  // Dependencies injected using Get.find()
  final DbHelper _dbHelper = Get.find<DbHelper>();
  final HomeController _homeController = Get.find<HomeController>();
  final ApiService _apiService = ApiService();

  // Late initialization for 'post' as it's passed via Get.arguments
  late Post post;

  // Observable properties for UI updates
  final Rx<User?> poster = Rx<User?>(null); // Details of the user who posted
  final RxBool isLiked = false.obs; // Tracks if the current user liked the post
  final RxBool isSaved = false.obs; // Tracks if the current user saved the post

  // Time zone conversion properties
  final RxList<String> availableTimeZoneNames = <String>[].obs;
  final RxString selectedTimeZoneName = ''.obs;
  final RxString formattedSelectedTimeZoneTime = ''.obs;

  // Internal maps to cache formatted times and icons for time zones
  final Map<String, String> _formattedTimeByTimeZone = {};
  final Map<String, IconData> _iconByTimeZone = {};

  // Currency conversion properties
  final RxList<String> availableCurrencyNames = <String>[].obs;
  final RxString selectedCurrencyName = ''.obs;
  final RxDouble displayConvertedPrice = 0.0.obs;

  // Internal map to cache converted currency values
  final Map<String, double> _convertedCurrencyValues = {};
  final RxBool _isConvertingCurrency = false.obs; // Loading indicator for currency conversion
  bool get isConvertingCurrency => _isConvertingCurrency.value; 

  // Static constants for time zone offsets (for demonstration, not comprehensive)
  static const Map<String, double> _timeZoneOffsets = {
    'UTC': 0.0,
    'America/New_York': -5.0,
    'Europe/London': 0.0,
    'Asia/Tokyo': 9.0,
    'Asia/Singapore': 8.0,
    'Australia/Sydney': 10.0,
    'Asia/Jakarta': 7.0, // WIB timezone
  };

  @override
  void onInit() {
    super.onInit();
    // Check if 'post' argument is provided and is of type Post
    if (Get.arguments is Post) {
      post = Get.arguments as Post;
      _loadPostDetails(); // Load post-related details asynchronously
    } else {
      Get.back(); // Navigate back if no valid post is provided
      showErrorMessage('Postingan tidak ditemukan atau data tidak valid.', title: 'Error Navigasi');
    }
  }

  // Fetches and initializes all post-related data
  Future<void> _loadPostDetails() async {
    try {
      // Fetch poster user data asynchronously
      final userFuture = _dbHelper.getUserById(post.uid);
      poster.value = await userFuture; // Await the user data

      // Set like and save status synchronously from HomeController's cache
      if (post.postId != null) {
        isLiked.value = _homeController.isPostLiked(post.postId!);
        isSaved.value = _homeController.isPostSaved(post.postId!);
      }

      // Prepare time zone conversions
      _prepareTimeZones();
      // Prepare currency conversions asynchronously (calls API)
      await _prepareCurrencyConversions();

      // Set default selected time zone if not already set and options are available
      if (availableTimeZoneNames.isNotEmpty && selectedTimeZoneName.value.isEmpty) {
        selectedTimeZoneName.value = availableTimeZoneNames.first;
      }
      _updateSelectedTimeZoneTime(); // Update displayed time based on default selection

      // Set default selected currency if not already set and options are available
      if (availableCurrencyNames.isNotEmpty && selectedCurrencyName.value.isEmpty) {
        // Prioritize IDR as default, otherwise pick the first available
        if (availableCurrencyNames.contains('IDR')) {
          selectedCurrencyName.value = 'IDR';
        } else if (availableCurrencyNames.isNotEmpty) {
          selectedCurrencyName.value = availableCurrencyNames.first;
        }
      }
      _updateSelectedCurrencyPrice(); // Update displayed price based on default selection
    } catch (e) {
      showErrorMessage('Gagal memuat detail postingan: $e', title: 'Error Detail Post');
    }
  }

  // --- Time Zone Conversion Logic ---

  // Populates available time zones and their formatted times
  void _prepareTimeZones() {
    _formattedTimeByTimeZone.clear();
    availableTimeZoneNames.clear(); // Ensure the list is cleared for fresh data
    _iconByTimeZone.clear();

    final baseTimeUtc = post.createdAt.toUtc(); // Convert post creation time to UTC

    final Set<String> addedTimeZoneNames = {}; // Use a set to track unique time zone names

    // Add the original post's time zone as the first option
    if (post.timeZone != null && post.timeZone!.isNotEmpty) {
      final originalOffsetHours = _getOffsetHoursForTimeZoneName(post.timeZone!);
      final originalTime = baseTimeUtc.add(Duration(hours: originalOffsetHours.toInt()));
      final formattedOriginalTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(originalTime);

      final originalTzOption = '${post.timeZone!} (Original)';
      _formattedTimeByTimeZone[originalTzOption] = formattedOriginalTime;
      _iconByTimeZone[originalTzOption] = Icons.access_time;
      availableTimeZoneNames.add(originalTzOption);
      addedTimeZoneNames.add(originalTzOption); // Add to set
    }

    // Convert and add other predefined time zones
    for (final entry in _timeZoneOffsets.entries) {
      final String tzName = entry.key;
      final double offsetHours = entry.value;

      // Skip if this timezone is the same as the original post's timezone (unless it's UTC)
      if (addedTimeZoneNames.contains(tzName) || (post.timeZone != null && tzName == post.timeZone && tzName != "UTC")) {
        continue;
      }

      try {
        final convertedTime = baseTimeUtc.add(Duration(hours: offsetHours.toInt()));
        final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(convertedTime);

        _formattedTimeByTimeZone[tzName] = formattedTime;
        _iconByTimeZone[tzName] = _getIconForTimeZone(tzName);
        availableTimeZoneNames.add(tzName);
        addedTimeZoneNames.add(tzName); // Add to set
      } catch (e) {
        print('Error converting time to $tzName: $e'); // Using print as per original code's style
        _formattedTimeByTimeZone[tzName] = 'Error';
        _iconByTimeZone[tzName] = Icons.error;
        availableTimeZoneNames.add(tzName);
        addedTimeZoneNames.add(tzName); // Add to set
      }
    }
    // If no initial selection, set it to the first available time zone
    if (selectedTimeZoneName.value.isEmpty && availableTimeZoneNames.isNotEmpty) {
        selectedTimeZoneName.value = availableTimeZoneNames.first;
    }
  }

  // Helper to get offset hours for a given time zone name from static map
  double _getOffsetHoursForTimeZoneName(String tzName) {
    return _timeZoneOffsets[tzName] ?? 0.0;
  }

  // Updates the observable formatted time string based on selectedTimeZoneName
  void _updateSelectedTimeZoneTime() {
    formattedSelectedTimeZoneTime.value = _formattedTimeByTimeZone[selectedTimeZoneName.value] ?? 'Waktu tidak tersedia';
  }

  // Callback for when the time zone dropdown selection changes
  void changeTimeZone(String? newTzName) {
    if (newTzName != null && availableTimeZoneNames.contains(newTzName)) {
      selectedTimeZoneName.value = newTzName;
      _updateSelectedTimeZoneTime();
    }
  }

  // Returns the appropriate icon for the currently selected time zone
  IconData getIconForSelectedTimeZone() {
    return _iconByTimeZone[selectedTimeZoneName.value] ?? Icons.error;
  }

  // Helper to get an icon based on time zone name
  IconData _getIconForTimeZone(String tzName) {
    if (tzName.contains('Asia')) return Icons.travel_explore;
    if (tzName.contains('Europe')) return Icons.location_city;
    if (tzName.contains('America')) return Icons.landscape;
    if (tzName.contains('Australia')) return Icons.sunny;
    if (tzName.contains('UTC')) return Icons.public;
    return Icons.access_time;
  }

  // --- Currency Conversion Logic ---

  // Fetches exchange rates from API and populates converted values
  Future<void> _prepareCurrencyConversions() async {
    _isConvertingCurrency.value = true; // Set loading state
    _convertedCurrencyValues.clear();
    availableCurrencyNames.clear(); // Ensure list is clear

    final double idrPrice = post.postPrice;

    final Set<String> addedCurrencyNames = {}; // Use a set to track unique currency names

    // Always add IDR as a base option
    _convertedCurrencyValues['IDR'] = idrPrice;
    availableCurrencyNames.add('IDR');
    addedCurrencyNames.add('IDR');

    try {
      // Get exchange rates from API with USD as base currency
      final Map<String, double>? apiRates = await _apiService.getExchangeRates(baseCurrency: 'USD');

      // If API rates are successfully retrieved and contain IDR
      if (apiRates != null && apiRates.containsKey('IDR')) {
        final double idrToUsdRate = apiRates['IDR']!; // 1 USD = X IDR
        final double priceInUsd = idrPrice / idrToUsdRate; // Convert original IDR price to USD

        // Add USD, EUR, JPY by converting from the USD equivalent price
        if (!addedCurrencyNames.contains('USD')) {
          _convertedCurrencyValues['USD'] = priceInUsd;
          availableCurrencyNames.add('USD');
          addedCurrencyNames.add('USD');
        }
        if (apiRates.containsKey('EUR') && !addedCurrencyNames.contains('EUR')) {
          _convertedCurrencyValues['EUR'] = priceInUsd * apiRates['EUR']!;
          availableCurrencyNames.add('EUR');
          addedCurrencyNames.add('EUR');
        }
        if (apiRates.containsKey('JPY') && !addedCurrencyNames.contains('JPY')) {
          _convertedCurrencyValues['JPY'] = priceInUsd * apiRates['JPY']!;
          availableCurrencyNames.add('JPY');
          addedCurrencyNames.add('JPY');
        }

        // Sort available currency names, prioritizing IDR and USD
        availableCurrencyNames.sort((a, b) {
          if (a == 'IDR') return -1;
          if (b == 'IDR') return 1;
          if (a == 'USD') return -1;
          if (b == 'USD') return 1;
          return a.compareTo(b);
        });
      } else {
        // Fallback if API fails or IDR rate is not found
        showErrorMessage('Gagal mendapatkan kurs mata uang terbaru. Menggunakan nilai default.', title: 'Error Kurs');
        _addFallbackCurrencies(idrPrice, addedCurrencyNames);
      }
    } catch (e) {
      // Fallback on network errors
      showErrorMessage('Terjadi kesalahan saat mengambil kurs mata uang: $e', title: 'Error Koneksi Kurs');
      _addFallbackCurrencies(idrPrice, addedCurrencyNames);
    } finally {
      _isConvertingCurrency.value = false; // Reset loading state
    }

    // Set selectedCurrencyName to the first available currency if not already set
    if (selectedCurrencyName.value.isEmpty && availableCurrencyNames.isNotEmpty) {
      selectedCurrencyName.value = availableCurrencyNames.first;
    }
  }

  // Helper to add fallback currency values and names
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


  // Updates the observable displayConvertedPrice based on selectedCurrencyName
  void _updateSelectedCurrencyPrice() {
    displayConvertedPrice.value = _convertedCurrencyValues[selectedCurrencyName.value] ?? 0.0;
  }

  // Callback for when the currency dropdown selection changes
  void changeCurrency(String? newCurrencyName) {
    if (newCurrencyName != null && availableCurrencyNames.contains(newCurrencyName)) {
      selectedCurrencyName.value = newCurrencyName;
      _updateSelectedCurrencyPrice();
    }
  }

  // Returns the appropriate currency symbol for a given currency code
  String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'IDR': return 'Rp';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'JPY': return '¥';
      default: return '';
    }
  }

  // --- Action Toggles (Like, Save) ---

  // Toggles the like status of the post
  void toggleLike() {
    isLiked.value = !isLiked.value; // Optimistic update
    _homeController.toggleLike(post); // Delegate to HomeController for DB operation
  }

  // Toggles the save status of the post
  void toggleSave() {
    isSaved.value = !isSaved.value; // Optimistic update
    _homeController.toggleSave(post); // Delegate to HomeController for DB operation
  }

  // Launches Google Maps for the post's location
  void launchLocationOnMap() {
    _homeController.launchGoogleMaps(post.latitude, post.longitude);
  }
}