import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logistics_models.dart';

class LogisticsAPI {
  // 🔗 المسار الأساسي (الدومين فقط) لضمان عدم تكرار المسارات في الـ Functions
  static const String baseUrl = 'https://marginal-cathryn-aksab-e60772e8.koyeb.app';

  static Future<List<InventoryItem>> fetchMyInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      
      if (userDataString == null) {
        debugPrint("⚠️ No user data found in SharedPreferences");
        return [];
      }

      final userData = jsonDecode(userDataString);
      final String repCode = userData['rep_code'] ?? '';
      final String? token = userData['token'] ?? userData['key'];

      // 🕵️ كونسول للتصحيح - لاحظ إضافة /logistics/ هنا يدوياً لضمان الدقة
      final fullUrl = '$baseUrl/logistics/my-inventory/?rep_code=$repCode';
      debugPrint("🚀 Fetching inventory from: $fullUrl");

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 🔑 التوكن ضروري جداً لتخطي حماية Django Rest Framework
          if (token != null) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // فك التشفير ودعم اللغة العربية (UTF-8)
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        // تحويل الـ JSON إلى قائمة من الـ Model
        return data.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        debugPrint("⚠️ API Error Status: ${response.statusCode}");
        debugPrint("📥 Server Response: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Connection Exception: $e");
      return [];
    }
  }

  // يمكنك إضافة وظائف أخرى هنا مثل fetchMyTransfers بنفس النمط
}

