import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // دالة الدخول للمنظومة
  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("يرجى إدخال رقم الهاتف وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://aksab.pythonanywhere.com/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'password': _passwordController.text,
          // 'fcm_token': "يمكن إضافته هنا لاحقاً للإشعارات",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // 1. حفظ التوكن والبيانات في ذاكرة الهاتف (Session)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('fullname', data['fullname']);
        
        // حفظ بيانات العهدة الصريحة
        if (data['data'] != null) {
          await prefs.setString('insurance_points', data['data']['insurance_points'].toString());
        }

        // 2. التوجيه بناءً على الصلاحية
        if (mounted) {
          if (data['role'] == 'sales_rep') {
            Navigator.pushReplacementNamed(context, '/rep_home');
          } else if (data['role'] == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          }
        }
      } else {
        _showSnackBar(data['message'] ?? "بيانات الدخول غير صحيحة");
      }
    } catch (e) {
      _showSnackBar("فشل الاتصال بخادم المنظومة: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center), backgroundColor: const Color(0xFFB21F2D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار المنظومة (يمكن استبداله بـ Image.asset)
              const Icon(Icons.local_shipping_rounded, size: 80, color: Color(0xFFB21F2D)),
              const SizedBox(height: 16),
              const Text(
                "أكسب ERP",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A2C3D)),
              ),
              const Text("منظومة إدارة العهدة والخدمات اللوجستية", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف / اسم المستخدم",
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "كلمة المرور",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB21F2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تأكيد الدخول للمنظومة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("نسيت كلمة المرور؟ اتصل بمدير النظام", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }
}
