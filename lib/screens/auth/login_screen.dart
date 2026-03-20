import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 1. دالة جلب توكن الإشعارات (FCM) لربط الجهاز بالعهدة
  Future<String?> _getDeviceToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      // التأكد من الحصول على الإذن (لاندرويد 13 فما فوق)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        debugPrint("🚀 Device FCM Token: $token");
        return token;
      }
    } catch (e) {
      debugPrint("❌ Failed to get FCM Token: $e");
    }
    return null;
  }

  // 2. دالة الدخول للمنظومة
  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("يرجى إدخال بيانات الدخول");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // جلب توكن الجهاز قبل الإرسال
      String? fcmToken = await _getDeviceToken();

      final response = await http.post(
        Uri.parse('https://aksab.pythonanywhere.com/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'fcm_token': fcmToken, // 🔑 الربط اللحظي لتلقي تنبيهات العهدة
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('fullname', data['fullname']);
        
        // حفظ نقاط التأمين الحالية للعهدة
        if (data['data'] != null) {
          await prefs.setString('insurance_points', data['data']['insurance_points'].toString());
          await prefs.setString('rep_code', data['data']['rep_code'].toString());
        }

        if (mounted) {
          if (data['role'] == 'sales_rep') {
            Navigator.pushReplacementNamed(context, '/rep_home');
          } else {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          }
        }
      } else {
        _showSnackBar(data['message'] ?? "خطأ في بيانات المنظومة");
      }
    } catch (e) {
      _showSnackBar("فشل في مزامنة البيانات مع السيرفر");
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
            children: [
              const Icon(Icons.inventory_2_outlined, size: 90, color: Color(0xFFB21F2D)),
              const SizedBox(height: 10),
              const Text("أكسب ERP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text("إدارة عهدة المندوب والتحصيل", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف المسجل",
                  prefixIcon: const Icon(Icons.person_pin_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "كلمة المرور",
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("دخول وتأكيد الاتصال", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
