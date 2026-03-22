import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ألوان الهوية الخاصة بك
const Color kPrimaryColor = Color(0xFFB21F2D);
const Color kSecondaryColor = Color(0xFF1A2C3D);

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
        appBar: AppBar(
          title: const Text("قائمة العملاء", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _fetchCustomers,
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _customers.isEmpty
                    ? const Center(child: Text("لا يوجد عملاء مسجلين حالياً"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: kSecondaryColor,
                                child: Icon(Icons.store, color: Colors.white),
                              ),
                              title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("📞 ${customer['phone']}\n📍 ${customer['address'] ?? 'بدون عنوان'}"),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // هنا مستقبلاً هنفتح شاشة "بدء زيارة" أو "فاتورة" للعميل ده
                              },
                            ),
                          );
                        },
                      ),
        // ➕ زرار إضافة عميل جديد
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCustomerScreen()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("جاري تحضير شاشة الإضافة..."))
            );
          },
          label: const Text("إضافة عميل"),
          icon: const Icon(Icons.person_add_alt_1),
          backgroundColor: kPrimaryColor,
        ),
      ),
    );
  }
}

