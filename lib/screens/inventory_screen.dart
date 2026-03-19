import 'package:flutter/material.dart';
// تصحيح المسارات لتكون متوافقة مع هيكلة الملفات عندك
import '../models/logistics_models.dart';
import '../services/logistics_api.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key}); // إضافة الـ key لتحسين الأداء

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة عهدة المندوب (ERP)'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: 'العهدة الحالية'),
              Tab(icon: Icon(Icons.download_for_offline), text: 'استلام أمانات'), // استبدال الإيموجي بأيقونة رسمية
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCurrentStock(),
            _buildPendingTransfers(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStock() {
    return FutureBuilder<List<InventoryItem>>(
      future: LogisticsAPI.fetchMyInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("خطأ في الاتصال بالسيرفر ⚠️"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("لا توجد بضاعة في العهدة"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(item.product, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("${item.quantity} ${item.unit}", 
                  style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTransfers() {
    return const Center(child: Text("هنا ستظهر العهد المرسلة للمندوب لتأكيدها ✅"));
  }
}

