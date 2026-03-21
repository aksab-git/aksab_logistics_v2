import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_model.dart';

class TransferService {
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics";

  Future<List<StockTransfer>> getMyIncomingTransfers(String token, String repCode) async {
    // ✅ الرابط الدقيق بناءً على الـ urls.py والـ ViewSet
    final url = Uri.parse('$baseUrl/my-transfers/?rep_code=$repCode');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        // تحويل البيانات لـ Model (السيرفر يفلتر الحالات برمجياً الآن)
        return data.map((item) => StockTransfer.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> confirmReceipt(int id, String token) async {
    // ✅ التأكيد يتم على ID الإذن بالكامل
    final url = Uri.parse('$baseUrl/my-transfers/$id/');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'COMPLETED'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

