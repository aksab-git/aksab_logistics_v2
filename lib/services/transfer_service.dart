import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_model.dart';

class TransferService {
  // ✅ الدومين فقط لضمان بناء روابط سليمة
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics";

  // جلب العهد الواردة (المعلقة)
  Future<List<StockTransfer>> getMyIncomingTransfers(String token, String repCode) async {
    // ✅ إضافة الـ / قبل الـ ? لضمان قبول دجانجو للطلب
    final url = Uri.parse('$baseUrl/my-transfers/?rep_code=$repCode');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        
        // تحويل البيانات لـ Model مع فلترة الحالات المعلقة فقط (في الطريق)
        return data
            .map((item) => StockTransfer.fromJson(item))
            .where((t) => t.status == 'IN_TRANSIT' || t.status == 'PENDING') // دعم الحالتين
            .toList();
      } else {
        return []; // إرجاع قائمة فارغة بدل الـ Exception لضمان استقرار التطبيق
      }
    } catch (e) {
      return [];
    }
  }

  // تأكيد استلام الأمانات (تحويل العهدة لذمة المندوب)
  Future<bool> confirmReceipt(int id, String token) async {
    // ✅ إضافة الـ / في نهاية الرابط ضرورية جداً في الـ PATCH
    final url = Uri.parse('$baseUrl/my-transfers/$id/');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        // ✅ الحالة اللي السيرفر مستنيها هي COMPLETED عشان ينقل العهدة فعلياً لمخزن السيارة
        body: jsonEncode({'status': 'COMPLETED'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

