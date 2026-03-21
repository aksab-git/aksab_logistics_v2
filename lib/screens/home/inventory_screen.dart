import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الصفحات والخدمات
import '../incoming_transfers_page.dart';
import '../create_load_request_page.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _inventoryItems = [];
  bool _isLoading = true;
  String _errorMessage = "";
  int _pendingTransfersCount = 0;

  // الهوية اللونية
  final Color kPrimaryColor = const Color(0xFFB21F2D);
  final Color kSecondaryColor = const Color(0xFF1A2C3D);
  final Color kAccentColor = const Color(0xFF2E7D32);
  final Color kWarningColor = Colors.orange.shade700;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    await _fetchInventory();
    await _checkPendingTransfers();
    if (mounted) setState(() => _isLoading = false);
  }

  // 🛠️ جلب بيانات عهدة السيارة (التصحيح هنا)
  Future<void> _fetchInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString == null) {
      setState(() => _errorMessage = "انتهت الجلسة، يرجى إعادة تسجيل الدخول");
      return;
    }

    final Map<String, dynamic> userData = jsonDecode(userDataString);
    final String repCode = userData['rep_code']?.toString() ?? "";
    // تأكدنا من استخدام 'token' كاسم موحد
    final String? token = userData['token']?.toString();

    try {
      // ✅ التصحيح: إضافة الشرطة المائلة قبل علامة الاستفهام ليتوافق مع Django URLs
      final String urlPath = 'https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/my-inventory/?rep_code=$repCode';
      
      final response = await http.get(
        Uri.parse(urlPath), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _inventoryItems = data;
            _errorMessage = "";
          });
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = "تعذر جلب البيانات (خطأ: ${response.statusCode})");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "حدث خطأ في الاتصال بالخادم");
      }
      debugPrint("❌ Inventory Error: $e");
    }
  }

  // 🛠️ فحص العهد المعلقة (تأكيد استلام الأمانات)
  Future<void> _checkPendingTransfers() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return;

    final Map<String, dynamic> userData = jsonDecode(userDataString);
    final String repCode = userData['rep_code']?.toString() ?? "";
    final String? token = userData['token']?.toString();

    try {
      // ✅ نفس التصحيح هنا أيضاً
      final url = Uri.parse('https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/my-transfers/?rep_code=$repCode');
      final response = await http.get(url, headers: {
        if (token != null) 'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        int count = data.where((t) => t['status'] == 'IN_TRANSIT').length;
        if (mounted) {
          setState(() => _pendingTransfersCount = count);
        }
      }
    } catch (_) {}
  }

  void _openCreateLoadRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');
    if (userDataString == null) return;
    final userData = jsonDecode(userDataString);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final productService = ProductService();
    final allProducts = await productService.getAllProducts(userData['token']);

    if (!mounted) return;
    Navigator.pop(context);

    if (allProducts.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateLoadRequestPage(
            userToken: userData['token'],
            repId: int.tryParse(userData['user_id'].toString()) ?? 0,
            myWarehouseId: 1, // يمكن تخصيصه لاحقاً
            availableProducts: allProducts,
          ),
        ),
      ).then((_) => _refreshAll());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في تحميل قائمة المنتجات")),
      );
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
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "requestBtn",
              onPressed: _openCreateLoadRequest,
              backgroundColor: kAccentColor,
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text("طلب تحميل عهدة", style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: "receiveBtn",
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userDataString = prefs.getString('userData');
                if (userDataString == null) return;
                final userData = jsonDecode(userDataString);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IncomingTransfersPage(
                    userToken: userData['token'],
                    repCode: userData['rep_code'].toString(),
                  )),
                ).then((_) => _refreshAll());
              },
              backgroundColor: _pendingTransfersCount > 0 ? kWarningColor : kSecondaryColor,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.fact_check_outlined, color: Colors.white),
                  if (_pendingTransfersCount > 0)
                    Positioned(right: -5, top: -5, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text("$_pendingTransfersCount", style: const TextStyle(fontSize: 10, color: Colors.white)))),
                ],
              ),
              label: Text(_pendingTransfersCount > 0 ? "تأكيد عهدة معلقة ($_pendingTransfersCount)" : "تأكيد استلام الأمانات", style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_isLoading && _errorMessage.isEmpty) _buildSummaryHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : RefreshIndicator(
                      onRefresh: _refreshAll,
                      color: kPrimaryColor,
                      child: _errorMessage.isNotEmpty ? _buildErrorUI() : _inventoryItems.isEmpty ? _buildEmptyUI() : _buildInventoryList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int totalQty = _inventoryItems.fold(0, (sum, item) => sum + (int.tryParse(item['stock_quantity'].toString()) ?? 0));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
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
    return Row(children: [Icon(icon, size: 20, color: kPrimaryColor), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor))])]);
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.1), child: Icon(Icons.inventory_2, color: kPrimaryColor)),
            title: Text(item['product_name'] ?? 'صنف غير معرف', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            subtitle: Text("SKU: ${item['product_code'] ?? '---'}", style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: kSecondaryColor, borderRadius: BorderRadius.circular(10)),
              child: Text("${item['stock_quantity'] ?? 0} قطعة", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorUI() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, color: Colors.orange, size: 50), const SizedBox(height: 15), Text(_errorMessage, style: const TextStyle(fontFamily: 'Cairo')), TextButton(onPressed: _refreshAll, child: const Text("إعادة المحاولة"))]));
  Widget _buildEmptyUI() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 80), const SizedBox(height: 20), const Text("لا توجد بضاعة في عهدة السيارة", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))]));
}

