import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final _addressUrl = 'https://nominatim.openstreetmap.org';

  Future<String> getDetailAddress({
    required String latitude,
    required String longitude,
  }) async {
    final dataUrl =
        '$_addressUrl/reverse?lat=$latitude&lon=$longitude&format=json';
    try {
      final res = await http.get(Uri.parse(dataUrl));

      if (res.statusCode < 300) {
        final data = json.decode(res.body);
        final value = data['address'];
        if (value != null) {
          return '${value['state']}, ${value['country']}';
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
}
