import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الشاشات المطلوبة
import 'add_customer_screen.dart';

// ألوان الهوية الخاصة بك
const Color kPrimaryColor = Color(0xFFB21F2D);
const Color kSecondaryColor = Color(0xFF1A2C3D);
const Color kBgColor = Color(0xFFF8F9FA);

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  List<dynamic> _customers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  // 📡 جلب قائمة العملاء من السيرفر
  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString == null) return;

      final userData = jsonDecode(userDataString);
      final String? token = userData['token'];

      final response = await http.get(
        Uri.parse('https://marginal-cathryn-aksab-e60772e8.koyeb.app/logistics/customers/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          // فك تشفير البيانات مع دعم اللغة العربية
          _customers = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "فشل في جلب البيانات: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "خطأ في الاتصال بالسيرفر: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          title: const Text("قائمة العملاء", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0.5,
          actions: [
            IconButton(
              onPressed: _fetchCustomers,
              icon: const Icon(Icons.refresh),
              tooltip: "تحديث",
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _error != null
                ? _buildErrorWidget()
                : _customers.isEmpty
                    ? _buildEmptyWidget()
                    : RefreshIndicator(
                        onRefresh: _fetchCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return _buildCustomerCard(customer);
                          },
                        ),
                      ),
        // ➕ زرار إضافة عميل جديد مربوط بالشاشة الجديدة
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // الانتقال لشاشة الإضافة وانتظار النتيجة
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
            );

            // إذا تم الحفظ بنجاح، قم بتحديث القائمة
            if (result == true) {
              _fetchCustomers();
            }
          },
          label: const Text("إضافة عميل", style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.person_add_alt_1),
          backgroundColor: kPrimaryColor,
          elevation: 4,
        ),
      ),
    );
  }

  // --- كارت العميل المنظم ---
  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kSecondaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.store_rounded, color: kSecondaryColor, size: 28),
        ),
        title: Text(
          customer['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📞 ${customer['phone']}", style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 2),
              Text(
                "📍 ${customer['address'] ?? 'بدون عنوان مسجل'}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          // مستقبلاً: فتح تفاصيل العميل أو بدء عملية بيع
        },
      ),
    );
  }

  // --- واجهة الخطأ ---
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: kPrimaryColor, size: 60),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(fontSize: 16)),
          TextButton(onPressed: _fetchCustomers, child: const Text("إعادة المحاولة")),
        ],
      ),
    );
  }

  // --- واجهة قائمة فارغة ---
  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("لا يوجد عملاء مسجلين تحت عهدتك", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text("ابدأ بإضافة أول عميل الآن", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

