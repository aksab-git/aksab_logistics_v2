import 'dart:convert';
import 'package:http/http.dart' as http;

class LogisticsService {
  // رابط السيرفر الجديد بتاعك
  static const String baseUrl = "https://Aksab.pythonanywhere.com/api/logistics";

  // وظيفة تسجيل المندوب وفتح "سجل تأمين عهدة"
  static Future<bool> registerDelegate({
    required String fullName,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "phone_number": phone,
        "insurance_points": 0, // نقاط التأمين الابتدائية
        "user_type": "delivery_agent",
      }),
    );

    if (response.statusCode == 201) {
      print("تم فتح عهدة المندوب بنجاح");
      return true;
    } else {
      print("خطأ في الربط اللوجستي: ${response.body}");
      return false;
    }
  }
}

