import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_model.dart';

class TransferService {
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics";
  
  // ✅ مخزن ثابت لعرض الرد على الشاشة للمعاينة
  static String lastRawResponse = "لم يتم إجراء أي طلب بعد";

  Future<List<StockTransfer>> getMyIncomingTransfers(String token, String repCode) async {
    final url = Uri.parse('$baseUrl/my-transfers/?rep_code=$repCode');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      });

      // ✅ تخزين الرد التقني كاملاً
      lastRawResponse = "URL: $url\nStatus: ${response.statusCode}\nBody: ${utf8.decode(response.bodyBytes)}";

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => StockTransfer.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      lastRawResponse = "حدث خطأ استثنائي:\n$e";
      return [];
    }
  }

  Future<bool> confirmReceipt(int id, String token) async {
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
      lastRawResponse = "Confirm Result: ${response.statusCode}\n${response.body}";
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

