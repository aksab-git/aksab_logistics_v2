import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logistics_models.dart';

class LogisticsAPI {
  // 🔗 المسار الأساسي كما هو محدد في urls.py بالديجانجو
  static const String baseUrl = 'https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics';

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

      // 🕵️ كونسول للتصحيح
      debugPrint("🚀 Fetching inventory for Rep: $repCode");

      final response = await http.get(
        Uri.parse('$baseUrl/my-inventory/?rep_code=$repCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 🔑 ضروري جداً عشان الـ 403 تختفي
          if (token != null) 'Authorization': 'Token $token', 
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // فك التشفير ودعم العربي
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        // 🛠️ تحويل الـ JSON إلى List من الـ Model اللي راجعناه
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
}
