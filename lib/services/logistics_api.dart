// lib/services/logistics_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart'; // تأكد إن فيه الـ BASE_URL والـ Token

class LogisticsAPI {
  static Future<List<InventoryItem>> fetchMyInventory() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/logistics/my-inventory/'),
      headers: {
        'Authorization': 'Token $YOUR_STORED_TOKEN', // التوكن اللي خدناه من اللوجن
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes)); // لضمان دعم العربي
      return data.map((item) => InventoryItem.fromJson(item)).toList();
    } else {
      throw Exception('فشل الاتصال بالسيرفر: ${response.statusCode}');
    }
  }
}

