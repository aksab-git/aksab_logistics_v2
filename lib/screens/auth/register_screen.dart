import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // إضافة مكتبة الربط بالسيرفر
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'delivery_agent'; // القيمة الافتراضية للخدمات اللوجستية
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  final Color aksabRed = const Color(0xFFB21F2D);

  // تحديث المسميات لتكون لوجستية
  final Map<String, String> _roles = {
    'delivery_agent': 'مندوب توصيل (إدارة عهدة)',
    'delivery_supervisor': 'مشرف لوجستي',
    'delivery_manager': 'مدير عمليات التوزيع',
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // الرابط الخاص بسيرفر PythonAnywhere
      final url = Uri.parse("https://Aksab.pythonanywhere.com/api/logistics/register/");

      // إرسال البيانات للباكيند (Django) بالمصطلحات المطلوبة
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": _nameController.text.trim(),
          "phone_number": _phoneController.text.trim(),
          "password": _passwordController.text, // سيتم تشفيرها في الديجانجو
          "address": _addressController.text.trim(),
          "user_type": _selectedRole,
          "insurance_points": 0, // تأمين عهدة الطلب الابتدائي
          "status": "pending",
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _message = "✅ تم طلب فتح سجل العهدة بنجاح. في انتظار تفعيل (نقاط الأمان) من الإدارة.";
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isSuccess = false;
          _message = "❌ فشل في فتح العهدة: ${errorData['error'] ?? 'خطأ في السيرفر'}";
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = "❌ عذراً، تعذر الاتصال بسيرفر العهدة: ${e.toString()}";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("تفعيل نظام إدارة العهدة"),
        backgroundColor: aksabRed,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_rounded, size: 60, color: aksabRed),
                    const SizedBox(height: 20),
                    _buildField(_nameController, "الاسم بالكامل للمسؤول عن العهدة", Icons.person),
                    _buildField(_phoneController, "رقم التواصل", Icons.phone, isPhone: true),
                    _buildField(_passwordController, "كلمة مرور النظام", Icons.lock, isPass: true),
                    _buildField(_addressController, "منطقة التغطية اللوجستية", Icons.location_on),
                    const Divider(height: 30),
                    const Text("تحديد نوع المسؤولية:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ..._roles.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: _selectedRole,
                        activeColor: aksabRed,
                        onChanged: (val) => setState(() => _selectedRole = val!),
                      );
                    }).toList(),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(_message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _isSuccess ? Colors.green : aksabRed, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aksabRed,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("تأكيد طلب العهدة", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        textAlign: TextAlign.right,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: aksabRed),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) => (v == null || v.isEmpty) ? "هذا الحقل مطلوب" : null,
      ),
    );
  }
}

