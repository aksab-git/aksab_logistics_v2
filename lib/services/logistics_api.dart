import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logistics_models.dart';

class LogisticsAPI {
  static const String baseUrl = 'https://aksab.pythonanywhere.com/logistics/api';

  static Future<List<InventoryItem>> fetchMyInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString == null) return [];
      
      final userData = jsonDecode(userDataString);
      final String repCode = userData['rep_code'] ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/inventory/?rep_code=$repCode'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        debugPrint("⚠️ API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Connection Exception: $e");
      return [];
    }
  }
}
