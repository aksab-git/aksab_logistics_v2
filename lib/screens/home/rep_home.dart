import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// --- الثوابت اللونية لهوية أكسب ERP ---
const Color kPrimaryColor = Color(0xFFB21F2D);
const Color kSecondaryColor = Color(0xFF1A2C3D);
const Color kSuccessColor = Color(0xFF2E7D32);
const Color kErrorColor = Color(0xFFC62828);
const Color kBgColor = Color(0xFFF8F9FA);

class RepHomeScreen extends StatefulWidget {
  const RepHomeScreen({super.key});

  @override
  State<RepHomeScreen> createState() => _RepHomeScreenState();
}

class _RepHomeScreenState extends State<RepHomeScreen> {
  Map<String, dynamic>? repData;
  bool _isLoading = true;
  bool _isDayOpen = false;
  String _statusMessage = 'جاري التحقق من حالة العهدة...';
  String _insurancePoints = "0";

  @override
  void initState() {
    super.initState();
    _checkUserDataAndDayStatus();
  }

  // --- نظام أذونات الموقع المعدل للعمل فوراً ---
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("❌ يرجى تفعيل الـ GPS أولاً");
      return false;
    }

    // تعديل: طلب إذن الموقع (أثناء الاستخدام) لأنه أضمن وأسرع
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      _showSnackBar("❌ يرجى تفعيل إذن الموقع من إعدادات الهاتف");
      openAppSettings();
      return false;
    }
    return status.isGranted;
  }

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
      _statusMessage = _isDayOpen ? 'يوم العمل مفتوح - التتبع نشط' : 'يرجى بدء الوردية لاستلام العهدة';
      _isLoading = false;
    });
  }

  Future<void> _toggleDay() async {
    // 1. التحقق من الأذونات أولاً
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() => _isLoading = true);

    try {
      // 2. الحصول على الموقع الحالي بدقة متوسطة لسرعة الاستجابة
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 3. إرسال البيانات لسيرفر Django
      final response = await http.post(
        Uri.parse('https://aksab.pythonanywhere.com/logistics/api/work-day/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rep_code': repData!['rep_code'],
          'action': _isDayOpen ? 'end' : 'start',
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _isDayOpen = !_isDayOpen;
          prefs.setBool('isDayOpen', _isDayOpen);
          _statusMessage = _isDayOpen ? 'تم بدء الوردية بنجاح' : 'تم إنهاء الوردية وتصفية العهدة';
        });
        _showSnackBar(_isDayOpen ? "🚀 بدأت ورديتك - بالتوفيق" : "✅ تم إنهاء الوردية بنجاح");
      } else {
        _showSnackBar("❌ فشل في تحديث الحالة: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("❌ خطأ في الاتصال بالسيرفر: $e");
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
          title: const Text('أكسب ERP', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0,
        ),
        body: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusHeader(),
                    const SizedBox(height: 20),
                    _buildInsuranceCard(),
                    const SizedBox(height: 20),
                    _buildActionButton(),
                    const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: [
          Icon(_isDayOpen ? Icons.online_prediction : Icons.offline_bolt,
              color: _isDayOpen ? kSuccessColor : kErrorColor),
          const SizedBox(width: 10),
          Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInsuranceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text("نقاط تأمين العهدة الحالية", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text(_insurancePoints, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Text("نقطة تأمين", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _toggleDay,
        icon: Icon(_isDayOpen ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined, size: 28),
        label: Text(_isDayOpen ? "إنهاء وردية العمل" : "بدء يوم عمل جديد",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDayOpen ? kErrorColor : kSuccessColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _menuItem("تأكيد عهدة", Icons.qr_code_scanner, Colors.blue),
        _menuItem("قائمة العملاء", Icons.people_alt_outlined, Colors.orange),
        _menuItem("إدارة الأمانات", Icons.inventory_2_outlined, Colors.teal),
        _menuItem("تقارير اليوم", Icons.bar_chart_outlined, Colors.purple),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

