import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _debugLog = "جاهز للفحص... اضغط دخول"; 
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _debugLog = "📡 جاري طلب الاتصال بالسيرفر...";
    });

    try {
      final url = Uri.parse('https://aksab.pythonanywhere.com/logistics/login/');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      // 🛑 هنا عدلنا طريقة العرض عشان نتفادى خطأ الـ Null
      String responseBody = "";
      try {
        responseBody = utf8.decode(response.bodyBytes);
      } catch (e) {
        responseBody = "تعذر فك تشفير البيانات (Raw): ${response.body}";
      }

      setState(() {
        _debugLog = "✅ رد السيرفر وصل:\n"
            "------------------------\n"
            "الرمز (Status): ${response.statusCode}\n"
            "المحتوى (Body):\n$responseBody\n"
            "------------------------";
      });

    } catch (e) {
      setState(() {
        _debugLog = "❌ خطأ فني في الاتصال:\n$e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("مختبر فحص السيرفر")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "رقم الهاتف")),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "كلمة المرور")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("دخول وفحص الـ JSON", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("تقرير الفحص المباشر:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _debugLog,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
