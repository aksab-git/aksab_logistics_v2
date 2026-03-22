import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/load_request_model.dart';

class LoadRequestService {
  // الرابط الأساسي للباك إند
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics";

  /// 🆕 الدالة الجديدة التي تستقبل Map مباشرة (لحل مشكلة الـ Build)
  Future<bool> sendLoadRequestRaw(Map<String, dynamic> data, String token) async {
    // نرسل الطلب إلى stock-transfers لإنشاء طلب تحميل جديد
    final url = Uri.parse('$baseUrl/stock-transfers/');
    
    try {
      print("📡 جاري إرسال الطلب إلى: $url");
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      // طباعة الرد للفحص في الكونسول (رادار السيرفر)
      print("📡 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");

      // نجاح الإنشاء في Django هو 201 Created
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("❌ حدث خطأ أثناء الاتصال بالسيرفر: $e");
      return false;
    }
  }

  /// 🔄 الدالة القديمة (تم تحديثها لتستخدم الدالة الجديدة)
  Future<bool> sendLoadRequest(LoadRequestHeader request, String token) async {
    // تحويل الكائن (Model) إلى خريطة (Map) وإرساله
    return await sendLoadRequestRaw(request.toJson(), token);
  }
}

