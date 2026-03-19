import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logistics_models.dart'; // استيراد الموديل الصحيح

class LogisticsAPI {
  // الرابط المباشر للسيرفر
  static const String baseUrl = 'https://aksab.pythonanywhere.com';

  static Future<List<InventoryItem>> fetchMyInventory() async {
    final prefs = await SharedPreferences.getInstance();
    // جلب بيانات المستخدم المخزنة عند اللوجن
    final userDataString = prefs.getString('userData');
    
    if (userDataString == null) throw Exception('يجب تسجيل الدخول أولاً');
    
    final userData = jsonDecode(userDataString);
    final String token = userData['token'] ?? ''; // تأكد أن الكي اسمه token

    final response = await http.get(
      Uri.parse('$baseUrl/api/logistics/my-inventory/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // utf8.decode عشان العربي يظهر صح
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => InventoryItem.fromJson(item)).toList();
    } else {
      throw Exception('فشل الاتصال بالسيرفر: ${response.statusCode}');
    }
  }
}

