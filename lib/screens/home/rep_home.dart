import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// --- استيراد الشاشات الأخرى ---
import 'inventory_screen.dart';
import 'customers_list_screen.dart'; // تأكد من إنشاء هذا الملف كما في الرد السابق

// --- الثوابت اللونية لهوية أكسب ERP ---
const Color kPrimaryColor = Color(0xFFB21F2D); // الأحمر الملكي
const Color kSecondaryColor = Color(0xFF1A2C3D); // الكحلي الغامق
const Color kSuccessColor = Color(0xFF2E7D32);
const Color kErrorColor = Color(0xFFC62828);
const Color kBgColor = Color(0xFFF4F7F9); // خلفية أفتح قليلاً

class RepHomeScreen extends StatefulWidget {
  const RepHomeScreen({super.key});

  @override
  State<RepHomeScreen> createState() => _RepHomeScreenState();
}

class _RepHomeScreenState extends State<RepHomeScreen> {
  Map<String, dynamic>? repData;
  bool _isLoading = true;
  bool _isDayOpen = false;
  String _statusMessage = 'جاري التحقق من حالة الوردية...';
  String _insurancePoints = "0";

  @override
  void initState() {
    super.initState();
    _checkUserDataAndDayStatus();
  }

  // --- دالة تسجيل الخروج ---
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    bool confirm = await showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text("تسجيل الخروج"),
              content: const Text("هل تريد إغلاق الجلسة ومسح بيانات الدخول؟"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("خروج", style: TextStyle(color: kErrorColor)),
                ),
              ],
            ),
          ),
        ) ?? false;

    if (confirm) {
      await prefs.clear();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // --- طلب صلاحيات الموقع ---
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("❌ يرجى تفعيل الـ GPS أولاً");
      return false;
    }
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    if (status.isPermanentlyDenied) {
      _showSnackBar("❌ يرجى تفعيل إذن الموقع من الإعدادات");
      openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  // --- التحقق من حالة اليومية ---
  Future<void> _checkUserDataAndDayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    setState(() {
      repData = jsonDecode(userDataString);
      _isDayOpen = prefs.getBool('isDayOpen') ?? false;
      _insurancePoints = repData?['insurance_points']?.toString() ?? "0";
      _statusMessage = _isDayOpen ? 'الوردية مفتوحة - التتبع نشط' : 'يرجى بدء الوردية لإدارة العهدة';
      _isLoading = false;
    });
  }

  // --- فتح أو إغلاق اليومية ---
  Future<void> _toggleDay() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final String? token = repData?['token'];

      final response = await http.post(
        Uri.parse('https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/work-day/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: json.encode({
          'rep_code': repData!['rep_code'],
          'action': _isDayOpen ? 'end' : 'start',
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _isDayOpen = !_isDayOpen;
          prefs.setBool('isDayOpen', _isDayOpen);
          _statusMessage = _isDayOpen ? 'تم بدء الوردية بنجاح' : 'تم إنهاء الوردية وتصفية العهدة';
        });
        _showSnackBar(_isDayOpen ? "🚀 رحلة مبيعات سعيدة!" : "✅ تم إغلاق اليومية بنجاح");
      } else {
        _showSnackBar("❌ فشل المزامنة: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("❌ خطأ في الاتصال: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          title: const Text('أكسب ERP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: kErrorColor),
              onPressed: _logout,
              tooltip: "خروج",
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 20),
                      _buildInsuranceCard(),
                      const SizedBox(height: 25),
                      _buildActionButton(),
                      const SizedBox(height: 35),
                      _buildActionGrid(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(_isDayOpen ? Icons.check_circle : Icons.pause_circle_filled,
              color: _isDayOpen ? kSuccessColor : Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSecondaryColor, Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kSecondaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text("رصيد الأمانات الحالي", style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 10),
          Text(_insurancePoints,
              style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
          const Text("نقطة تأمين", style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _toggleDay,
        icon: Icon(_isDayOpen ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 30),
        label: Text(_isDayOpen ? "إنهاء وردية العمل" : "بدء وردية العمل",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDayOpen ? kErrorColor : kSuccessColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _menuItem("تأكيد استلام", Icons.qr_code_scanner, Colors.blue, () {
          _showSnackBar("قريباً: مسح باركود العهدة");
        }),
        _menuItem("جرد العهدة", Icons.inventory_2_rounded, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
        }),
        _menuItem("العملاء", Icons.storefront_rounded, Colors.orange.shade700, () {
          // 🚀 الربط الحقيقي بشاشة العملاء
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersListScreen()));
        }),
        _menuItem("التقارير", Icons.analytics_rounded, Colors.indigo, () {
          _showSnackBar("قريباً: تقارير مبيعات المندوب");
        }),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: kSecondaryColor,
      ),
    );
  }
}

