import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/load_request_model.dart';

class LoadRequestService {
  final String baseUrl = "https://aksab.pythonanywhere.com/logistics/stock-transfers/";

  // 1. إرسال طلب تحميل جديد (اللي كان موجود عندك)
  Future<bool> sendLoadRequest(LoadRequestHeader request, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error sending load request: $e");
      return false;
    }
  }

  // 2. الجديد: تأكيد استلام صنف محدد (تأمين عهدة)
  // بننادي على الأكشن confirm-item اللي ضفناه في الباكيند
  Future<bool> confirmItemReceipt(int transferId, int itemId, String token) async {
    final String url = "$baseUrl$transferId/confirm-item/";
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'item_id': itemId, // الـ ID بتاع الصنف اللي المندوب علم عليه
        }),
      );

      if (response.statusCode == 200) {
        print("Item confirmed successfully");
        return true;
      } else {
        print("Failed to confirm item: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error confirming item: $e");
      return false;
    }
  }
}

