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
  
  // متغيرات للتصحيح (Debug Variables) لغرض العرض في الـ UI
  String debugRepCode = "جاري الفحص...";
  String debugTokenStatus = "غير موجود";
  String debugFullUrl = "";

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

    // 🕵️ كونسول: فحص البيانات المحفوظة
    debugPrint("🔍 [DEBUG] Raw UserData from Prefs: $userDataString");

    if (userDataString == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "انتهت الجلسة، يرجى إعادة تسجيل الدخول";
      });
      return;
    }

    final Map<String, dynamic> repData = jsonDecode(userDataString);
    final String repCode = repData['rep_code']?.toString() ?? "";
    final String? token = repData['token'] ?? repData['key']; 

    setState(() {
      debugRepCode = repCode.isEmpty ? "🔴 فارغ" : repCode;
      debugTokenStatus = (token != null && token.length > 10) ? "🟢 صالح (ينتهي بـ ${token.substring(token.length - 5)})" : "🔴 غير صالح";
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final url = Uri.parse('https://aksab.pythonanywhere.com/logistics/my-inventory/?rep_code=$repCode');
      debugFullUrl = url.toString();

      // 🕵️ كونسول: تفاصيل الـ Request
      debugPrint("🚀 [API REQUEST] URL: $debugFullUrl");
      debugPrint("🚀 [API REQUEST] Headers: {'Authorization': 'Token ${token?.substring(0, 5)}...', 'Content-Type': 'application/json'}");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Token $token', 
        },
      ).timeout(const Duration(seconds: 15));

      // 🕵️ كونسول: تفاصيل الـ Response
      debugPrint("📥 [API RESPONSE] Status Code: ${response.statusCode}");
      debugPrint("📥 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("✅ [DEBUG] Items Count: ${data.length}");
        setState(() {
          _inventoryItems = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _isLoading = false;
          _errorMessage = "خطأ 403: السيرفر يرفض وصول هذا المندوب.\nتأكد من ربط الحساب بمخزن السيارة في Django Admin.";
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "خطأ غير متوقع (${response.statusCode})\nالرد: ${response.body}";
        });
      }
    } catch (e) {
      debugPrint("❌ [CRITICAL ERROR]: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "حدث خطأ أثناء الاتصال: $e";
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
          title: const Text('جرد عهدة السيارة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0.5,
        ),
        body: Column(
          children: [
            // 🟥 الجزء ده للتصحيح فقط (Debug Panel) - هيفهمنا الموبايل باعت إيه
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🛠️ فحص الربط:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  Text("كود المندوب المسجل: $debugRepCode", style: const TextStyle(fontSize: 11)),
                  Text("حالة التوكن: $debugTokenStatus", style: const TextStyle(fontSize: 11)),
                  Text("الرابط المستخدم: $debugFullUrl", style: const TextStyle(fontSize: 10, color: Colors.blue), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
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
          ],
        ),
      ),
    );
  }

  // --- باقي الـ Widgets (List, Error, Empty) كما هي ---
  Widget _buildErrorUI() {
    return ListView(children: [
      const SizedBox(height: 50),
      const Icon(Icons.bug_report, color: Colors.orange, size: 60),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
      ),
      Center(child: ElevatedButton(onPressed: _fetchInventory, child: const Text("إعادة المحاولة")))
    ]);
  }

  Widget _buildEmptyUI() {
    return ListView(children: [
      const SizedBox(height: 100),
      const Center(child: Text("المخزن فارغ برمجياً (JSON [])", style: TextStyle(color: Colors.grey))),
    ]);
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          child: ListTile(
            title: Text(item['product_name'] ?? 'صنف مجهول'),
            subtitle: Text("كود: ${item['product_code']}"),
            trailing: Text("${item['stock_quantity'] ?? 0} قطعة", 
              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
          ),
        );
      },
    );
  }
}
