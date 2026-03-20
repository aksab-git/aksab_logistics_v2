import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

const Color kPrimaryColor = Color(0xFFB21F2D);
const Color kSecondaryColor = Color(0xFF1A2C3D);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userRole = prefs.getString('userRole');
    final String? userData = prefs.getString('userData');

    debugPrint("🔄 [CHECK] Existing Role: $userRole");
    debugPrint("🔄 [CHECK] Existing Data: $userData");

    if (userRole != null && userData != null) {
      if (mounted) _navigateUser(userRole);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _navigateUser(String role) {
    if (role == 'sales_rep') {
      Navigator.of(context).pushReplacementNamed('/rep_home');
    } else {
      Navigator.of(context).pushReplacementNamed('/admin_dashboard');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. جلب توكن الإشعارات (FCM)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint("🚀 [FCM] Token Captured: $fcmToken");
      } catch (e) {
        debugPrint("⚠️ [FCM] Failed: $e");
      }

      // 2. إرسال طلب تسجيل الدخول
      final url = Uri.parse('https://aksab.pythonanywhere.com/logistics/login/');
      debugPrint("📡 [API POST] Sending to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'password': password,
          'fcm_token': fcmToken,
        }),
      );

      debugPrint("📥 [API RESPONSE] Status: ${response.statusCode}");
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      debugPrint("📥 [API BODY]: $responseData");

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        
        // 🛠️ هيكلة البيانات بشكل منظم (هنا الحل لمشكلة التوكن)
        Map<String, dynamic> rawData = responseData['data'] ?? {};
        
        // استخراج التوكن من أي مكان محتمل في الرد
        String extractedToken = responseData['token'] ?? responseData['key'] ?? rawData['token'] ?? '';
        
        Map<String, dynamic> structuredUserData = {
          'token': extractedToken,
          'rep_code': rawData['rep_code'] ?? '',
          'fullname': responseData['fullname'] ?? rawData['fullname'] ?? 'مستخدم أكسب',
          'uid': (responseData['user_id'] ?? rawData['id']).toString(),
          'phone': phone,
          'role': responseData['role'],
        };

        // حفظ البيانات منظمة
        debugPrint("💾 [STORAGE] Saving structuredUserData: $structuredUserData");
        await prefs.setString('userData', json.encode(structuredUserData));
        await prefs.setString('userRole', responseData['role']);
        
        if (mounted) _navigateUser(responseData['role']);
      } else {
        _showError(responseData['message'] ?? '❌ بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      debugPrint("❌ [CRITICAL ERROR]: $e");
      _showError('❌ خطأ في الاتصال بالسيرفر: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _phoneController.text.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FA), Color(0xFFEDEFF2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(30.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 70, color: kPrimaryColor),
                      const SizedBox(height: 10),
                      const Text('أكسب ERP',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kSecondaryColor, fontFamily: 'Cairo')),
                      const Text('نظام المبيعات والخدمات اللوجستية',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Cairo')),
                      const SizedBox(height: 30),
                      _buildField(_phoneController, 'رقم الهاتف / المستخدم', Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildField(_passwordController, 'كلمة المرور', Icons.lock_outline, isPass: true),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('دخول النظام', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontFamily: 'Cairo')),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}
