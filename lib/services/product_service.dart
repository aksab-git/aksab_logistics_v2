import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart'; // ده الموديل اللي هنعمله في الخطوة الجاية

class ProductService {
  // ده رابط الـ API اللي بيجيب كل المنتجات (تأكد إنه مطابق للباكيند)
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/all-products/";

  Future<List<Product>> getAllProducts(String? token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        print("Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }
}

