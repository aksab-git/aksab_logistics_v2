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
    if (userDataString == null) return;
    
    final repData = jsonDecode(userDataString);
    final repCode = repData['rep_code'];

    try {
      final response = await http.get(
        Uri.parse('https://aksab.pythonanywhere.com/logistics/api/inventory/?rep_code=$repCode'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _inventoryItems = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جرد العهدة الحالية'),
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _inventoryItems.isEmpty
                ? const Center(child: Text("لا توجد عهدة مسجلة حالياً"))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _inventoryItems.length,
                    itemBuilder: (context, index) {
                      final item = _inventoryItems[index];
                      return Card(
                        margin: const EdgeInsets.bottom(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor.withAlpha(30),
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
