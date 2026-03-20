import 'dart:convert';
import 'package:http/http.dart' as http;
// السطر الناقص اللي وقف الـ Build:
import '../models/transfer_model.dart';

class TransferService {
  final String baseUrl = "https://aksab.pythonanywhere.com/logistics";

  // جلب العهد الواردة (المعلقة)
  Future<List<StockTransfer>> getMyIncomingTransfers(String token, String repCode) async {
    final url = Uri.parse('$baseUrl/my-transfers/?rep_code=$repCode');
    
    final response = await http.get(url, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      // فلترة العهد اللي "في الطريق" فقط لتقليل اللخبطة
      return data.map((item) => StockTransfer.fromJson(item))
                 .where((t) => t.status == 'IN_TRANSIT').toList();
    } else {
      throw Exception("فشل في جلب بيانات العهد");
    }
  }

  // تأكيد استلام الأمانات
  Future<bool> confirmReceipt(int id, String token) async {
    final url = Uri.parse('$baseUrl/my-transfers/$id/');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'COMPLETED'}),
    );
    return response.statusCode == 200;
  }
}

