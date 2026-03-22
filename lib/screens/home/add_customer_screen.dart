import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- الثوابت اللونية لهوية أكسب ERP ---
const Color kPrimaryColor = Color(0xFFB21F2D);
const Color kSecondaryColor = Color(0xFF1A2C3D);
const Color kSuccessColor = Color(0xFF2E7D32); // تم الإضافة للإصلاح
const Color kErrorColor = Color(0xFFC62828);   // تم الإضافة للإصلاح

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم في النصوص
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  double? _lat;
  double? _lng;
  bool _isGettingLocation = false;
  bool _isSaving = false;

  // 📍 دالة سحب الموقع الجغرافي
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _isGettingLocation = false;
      });
      _showSnackBar("✅ تم تحديد موقع المحل بنجاح", isError: false);
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showSnackBar("❌ فشل سحب الموقع: تأكد من فتح الـ GPS");
    }
  }

  // 💾 دالة حفظ العميل في السيرفر
  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      _showSnackBar("⚠️ برجاء تحديد موقع المحل (GPS) أولاً");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString == null) return;
      
      final userData = jsonDecode(userDataString);
      final String? token = userData['token'];

      final response = await http.post(
        Uri.parse('https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/customers/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'owner_name': _ownerController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'latitude': _lat,
          'longitude': _lng,
        }),
      );

      if (response.statusCode == 201) {
        _showSnackBar("🎉 تم تسجيل العميل بنجاح", isError: false);
        if (mounted) Navigator.pop(context, true); // الرجوع وتحديث القائمة
      } else {
        _showSnackBar("❌ فشل الحفظ: ${response.body}");
      }
    } catch (e) {
      _showSnackBar("❌ خطأ في الاتصال بالسيرفر: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("إضافة محل جديد", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0.5,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, "اسم المحل / المنشأة", Icons.storefront),
                const SizedBox(height: 15),
                _buildTextField(_ownerController, "اسم صاحب المحل", Icons.person_outline),
                const SizedBox(height: 15),
                _buildTextField(_phoneController, "رقم الموبايل", Icons.phone_android, isPhone: true),
                const SizedBox(height: 15),
                _buildTextField(_addressController, "العنوان (وصف تقريبي)", Icons.location_city),
                
                const SizedBox(height: 30),
                
                // --- قسم الـ GPS ---
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _lat != null ? kSuccessColor : Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: _lat != null ? kSuccessColor : Colors.grey),
                          const SizedBox(width: 10),
                          const Text("إحداثيات الموقع الجغرافي", style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isGettingLocation)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else if (_lat != null)
                            const Icon(Icons.check_circle, color: kSuccessColor),
                        ],
                      ),
                      if (_lat != null) ...[
                        const SizedBox(height: 10),
                        Text("Lat: $_lat , Lng: $_lng", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGettingLocation ? null : _getLocation,
                          icon: const Icon(Icons.gps_fixed),
                          label: Text(_lat == null ? "تحديد الموقع الحالي" : "تحديث الموقع"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kSecondaryColor,
                            side: const BorderSide(color: kSecondaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- زرار الحفظ ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("حفظ بيانات العميل", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kSecondaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty) ? "هذا الحقل مطلوب" : null,
    );
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center), 
        backgroundColor: isError ? kErrorColor : kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

