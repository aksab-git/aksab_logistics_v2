import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  // ✅ تم تعديل الرابط ليكون مطابقاً للـ Router في الباك إند
  // تأكد أن الرابط ينتهي بـ / قبل أي Query Parameters
  final String baseUrl = "https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/products/";

  Future<List<Product>> getAllProducts(String? token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // فك تشفير البيانات لضمان قراءة اللغة العربية بشكل صحيح
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // تحويل الـ JSON إلى List من الـ Product Model
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        // طباعة رقم الخطأ في الـ Console للمساعدة في التتبع
        print("❌ Product Fetch Error: ${response.statusCode}");
        print("❌ Response Body: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Product Service Exception: $e");
      return [];
    }
  }
}

