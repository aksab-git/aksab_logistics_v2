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

  // 1. جلب توكن الجهاز للإشعارات (FCM) لربطه بعهدة المندوب
  Future<String?> _getFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        return await messaging.getToken();
      }
    } catch (e) {
      debugPrint("⚠️ FCM Error: $e");
    }
    return null;
  }

  // 2. دالة الدخول وتأمين بيانات العهدة
  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("يرجى إدخال بيانات الدخول للمنظومة");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // الحصول على توكن الإشعارات لربطه بالحساب لحظة الدخول
      String? deviceToken = await _getFCMToken();

      final response = await http.post(
        Uri.parse('https://aksab.pythonanywhere.com/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'fcm_token': deviceToken, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          
          // حفظ البيانات الأساسية
          await prefs.setString('token', data['token']?.toString() ?? '');
          await prefs.setString('role', data['role']?.toString() ?? '');
          await prefs.setString('fullname', data['fullname']?.toString() ?? 'مندوب أكسب');
          await prefs.setString('user_id', data['user_id']?.toString() ?? '');

          // حفظ بيانات العهدة الصريحة من حقل 'data' في السيرفر
          if (data['data'] != null) {
            var repData = data['data'];
            // تأمين نقاط التأمين (تأمين عهدة الطلب)
            await prefs.setString('insurance_points', (repData['insurance_points'] ?? '0.00').toString());
            await prefs.setString('rep_code', (repData['rep_code'] ?? '').toString());
            await prefs.setString('phone', (repData['phone'] ?? '').toString());
          }

          if (mounted) {
            // التوجيه بناءً على الصلاحيات المعطاة
            if (data['role'] == 'sales_rep') {
              Navigator.pushReplacementNamed(context, '/rep_home');
            } else if (data['role'] == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
            }
          }
        } else {
          _showSnackBar(data['message'] ?? "بيانات الدخول غير صحيحة");
        }
      } else {
        _showSnackBar("خطأ في الاتصال بالمنظومة (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Login Exception: $e");
      _showSnackBar("حدث خطأ أثناء مزامنة البيانات، يرجى المحاولة لاحقاً");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFFB21F2D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 80, color: Color(0xFFB21F2D)),
                const SizedBox(height: 20),
                const Text(
                  "أكسب ERP",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A2C3D)),
                ),
                const Text(
                  "نظام إدارة عهدة المناديب والتحصيل",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 50),
                
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "رقم الهاتف / اسم المستخدم",
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB21F2D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "تأكيد الدخول للمنظومة",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "بمجرد دخولك، أنت توافق على شروط إدارة العهدة",
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
