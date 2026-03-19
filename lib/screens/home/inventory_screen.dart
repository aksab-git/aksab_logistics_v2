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
  String _errorMessage = ""; // لإظهار الخطأ لو السيرفر رد بـ 400 أو 500
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
        _errorMessage = "لم يتم العثور على بيانات المستخدم، يرجى تسجيل الدخول";
      });
      return;
    }
    
    final repData = jsonDecode(userDataString);
    final String repCode = repData['rep_code'] ?? "";

    if (repCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "كود المندوب غير صالح";
      });
      return;
    }

    try {
      // التأكد من الـ URL والـ Parameter: rep_code
      final response = await http.get(
        Uri.parse('https://aksab.pythonanywhere.com/logistics/api/inventory/?rep_code=$repCode'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _inventoryItems = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "فشل السيرفر: ${response.statusCode}\n${response.body}";
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
        appBar: AppBar(
          title: const Text('جرد العهدة الحالية', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                : _inventoryItems.isEmpty
                    ? const Center(child: Text("لا توجد عهدة (أمانات) مسجلة حالياً"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _inventoryItems.length,
                        itemBuilder: (context, index) {
                          final item = _inventoryItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kPrimaryColor.withOpacity(0.1),
                                child: Icon(Icons.inventory_2, color: kPrimaryColor),
                              ),
                              title: Text(item['product_name'] ?? 'منتج غير معروف',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("كود الصنف: ${item['product_code']}"),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${item['quantity']}",
                                      style: TextStyle(color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text("قطعة", style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

