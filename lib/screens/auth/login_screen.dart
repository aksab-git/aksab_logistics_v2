import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kPrimaryColor = Color(0xFFB21F2D);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _debugLog = "جاهز للفحص..."; // 🛠️ ده المربع اللي هيظهر فيه كل حاجة
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _debugLog = "جاري الاتصال بالسيرفر...";
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
      );

      // 🛠️ هنا الفضيحة: بنعرض الـ Status والـ Body على الشاشة
      setState(() {
        _debugLog = "Status: ${response.statusCode}\n\nBody:\n${utf8.decode(response.bodyBytes)}";
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        
        if (responseData['status'] == 'success') {
          // محاولة استخراج التوكن
          String token = responseData['token'] ?? responseData['key'] ?? (responseData['data'] != null ? responseData['data']['token'] : "لا يوجد توكن في الرد!");
          
          setState(() {
            _debugLog += "\n\n✅ تم الاستخراج: $token";
          });
          
          // حفظ البيانات والانتقال
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userData', json.encode(responseData));
          // هنا ممكن تضيف كود الانتقال
        }
      }
    } catch (e) {
      setState(() {
        _debugLog = "❌ خطأ اتصال: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مختبر الدخول")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "الهاتف")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "الباسورد"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _login, child: const Text("دخول وفحص")),
            const SizedBox(height: 20),
            // 🛠️ ده المربع اللي هيظهر فيه الرد
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.black87,
                child: SingleChildScrollView(
                  child: Text(_debugLog, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
