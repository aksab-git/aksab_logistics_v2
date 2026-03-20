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
  
  // ألوان الهوية اللوجستية (تم تصحيح السطر المسبب للخطأ)
  final Color kPrimaryColor = const Color(0xFFB21F2D);
  final Color kSecondaryColor = const Color(0xFF1A2C3D);
  final Color kAccentColor = const Color(0xFF2E7D32); // لون أخضر لوجستي للنجاح/الكميات

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
        _errorMessage = "انتهت الجلسة، يرجى إعادة تسجيل الدخول";
      });
      return;
    }

    final Map<String, dynamic> repData = jsonDecode(userDataString);
    final String repCode = repData['rep_code']?.toString() ?? "";
    final String? token = repData['token'];

    try {
      final url = Uri.parse('https://aksab.pythonanywhere.com/logistics/my-inventory/?rep_code=$repCode');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Token $token', 
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _inventoryItems = data;
          _isLoading = false;
          _errorMessage = "";
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "تعذر جلب البيانات (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "خطأ في الاتصال: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        appBar: AppBar(
          title: const Column(
            children: [
              Text('جرد عهدة السيارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              Text('نظام إدارة الأمانات والعهد', style: TextStyle(fontSize: 10, fontFamily: 'Cairo')),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0,
        ),
        floatingActionButton: _inventoryItems.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: () {
                // سيتم ربطها بصفحة تأكيد الاستلام لاحقاً
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("جاري تحضير صفحة تأكيد استلام العهدة..."))
                );
              },
              backgroundColor: kSecondaryColor,
              icon: const Icon(Icons.fact_check_outlined, color: Colors.white),
              label: const Text("تأكيد استلام الأمانات", style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
        body: Column(
          children: [
            if (!_isLoading && _errorMessage.isEmpty) _buildSummaryHeader(),
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

  Widget _buildSummaryHeader() {
    int totalQty = _inventoryItems.fold(0, (sum, item) => sum + (int.parse(item['stock_quantity'].toString())));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryBox("عدد الأصناف", "${_inventoryItems.length}", Icons.category_outlined),
          _summaryBox("إجمالي القطع", "$totalQty", Icons.inventory_2_outlined),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kPrimaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor)),
          ],
        )
      ],
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2, color: kPrimaryColor, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'] ?? 'صنف غير معرف',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              "SKU: ${item['product_code'] ?? '---'}",
                              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "وحدة: قطعة", 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${item['stock_quantity'] ?? 0}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Text("قطعة", style: TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 50),
          const SizedBox(height: 15),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
          TextButton(onPressed: _fetchInventory, child: const Text("تحديث البيانات")),
        ],
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 80),
          const SizedBox(height: 20),
          const Text("لا توجد أصناف في عهدة السيارة حالياً", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          const Text("تواصل مع أمين المخزن لتحميل العهدة", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}
