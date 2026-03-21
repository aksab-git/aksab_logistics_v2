import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/load_request_model.dart';

class LoadRequestService {
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics";

  Future<bool> sendLoadRequest(LoadRequestHeader request, String token) async {
    // الرابط الموحد لأذون التحويل
    final url = Uri.parse('$baseUrl/my-transfers/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      // إذا نجح السيرفر في إنشاء الإذن (201 Created)
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

