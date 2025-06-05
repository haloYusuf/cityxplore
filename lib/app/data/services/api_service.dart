import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final _addressUrl = 'https://nominatim.openstreetmap.org';
  final _timeUrl = 'https://api.ipgeolocation.io/v2';
  final _apiKey = 'e2c749c66cf040908d7452d2445a2b70';

  Future<String> getDetailAddress({
    required String latitude,
    required String longitude,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$_addressUrl/reverse?lat=$latitude&lon=$longitude&format=json',
        ),
      );

      if (res.statusCode < 300) {
        final data = json.decode(res.body);
        final value = data['address'];
        if (value != null) {
          return '${value['county']}, ${value['state']}, ${value['country']}';
        } else {
          return '-';
        }
      } else {
        return '-';
      }
    } catch (e) {
      return '-';
    }
  }

  Future<Map<String, dynamic>?> getTimeZone({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.parse(
      '$_timeUrl/timezone?apiKey=$_apiKey&lat=$latitude&long=$longitude',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        Get.snackbar(
            'Error API', 'Gagal memuat zona waktu: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return null;
      }
    } catch (e) {
      Get.snackbar(
          'Error Jaringan', 'Tidak dapat terhubung ke API zona waktu: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    }
  }
}
