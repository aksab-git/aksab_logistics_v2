import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _inventoryItems = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final Color kPrimaryColor = const Color(0xFFB21F2D);
  final Color kSecondaryColor = const Color(0xFF1A2C3D);

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "انتهت الجلسة، يرجى إعادة تسجيل الدخول لتحديث العهدة";
      });
      return;
    }

    final Map<String, dynamic> repData = jsonDecode(userDataString);
    final String repCode = repData['rep_code']?.toString() ?? "";
    
    // محاولة جلب التوكن بأكثر من مفتاح لضمان التوافق مع السيرفر
    final String? token = repData['token'] ?? repData['access_token'] ?? repData['key']; 

    if (repCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "كود المندوب غير معرف، يرجى مراجعة الإدارة";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final url = Uri.parse('https://aksab.pythonanywhere.com/logistics/my-inventory/?rep_code=$repCode');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // تأكد من المسافة بعد كلمة Token
          if (token != null) 'Authorization': 'Token $token', 
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint("📥 Inventory Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes)); // دعم اللغة العربية
        setState(() {
          _inventoryItems = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _isLoading = false;
          _errorMessage = "خطأ 403: الحساب غير مصرح له بالوصول للعهدة.\nتأكد من تفعيل صلاحيات اللوجستيات لحسابك.";
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = "جلسة العمل غير صالحة، يرجى تسجيل الخروج والدخول مرة أخرى.";
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "السيرفر غير مستجيب حالياً (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "تعذر الاتصال بالشبكة، تأكد من الإنترنت وحاول مرة أخرى.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('جرد العهدة (الأمانات)',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0.5,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : RefreshIndicator(
                onRefresh: _fetchInventory,
                color: kPrimaryColor,
                child: _errorMessage.isNotEmpty
                    ? _buildErrorUI()
                    : _inventoryItems.isEmpty
                        ? _buildEmptyUI()
                        : _buildInventoryList(),
              ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return ListView( // ListView ليدعم RefreshIndicator
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.lock_person_rounded, color: Colors.orange, size: 80),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(_errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'Cairo')),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: ElevatedButton(
            onPressed: _fetchInventory,
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("تحديث البيانات", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUI() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Text("لا توجد أمانات في عهدتك حالياً",
              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2_outlined, color: kPrimaryColor),
            ),
            title: Text(item['product_name'] ?? 'صنف غير مسمى',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("كود الصنف: ${item['product_code'] ?? '---'}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${item['quantity'] ?? 0}",
                    style: TextStyle(color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("قطعة", style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
