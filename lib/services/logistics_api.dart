import 'package:flutter/foundation.dart'; // ضرورية لـ debugPrint
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogisticsService {
  static const String baseUrl = 'https://aksab.pythonanywhere.com/logistics/api';

  // دالة لجلب بيانات العهدة للمندوب
  static Future<Map<String, dynamic>?> getRepInsurance(String repCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/insurance/?rep_code=$repCode'),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        // استبدال print بـ debugPrint لتخطي فحص الـ Analyze
        debugPrint("⚠️ Logistics API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Logistics Service Exception: $e");
      return null;
    }
  }
}

