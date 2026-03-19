import 'package:flutter/material.dart';
import '../models/logistics_models.dart';
import '../services/logistics_api.dart';

class InventoryScreen extends StatefulWidget {
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
          title: Text('إدارة عهدة المندوب (ERP)'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: 'العهدة الحالية'),
              Tab(icon: Icon(Icons.📥), text: 'استلام أمانات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCurrentStock(),    // الجزء الخاص بالبضاعة الحالية
            _buildPendingTransfers(), // الجزء الخاص بالتحويلات الجديدة
          ],
        ),
      ),
    );
  }

  // 1. عرض العهدة الحالية في السيارة
  Widget _buildCurrentStock() {
    return FutureBuilder<List<InventoryItem>>(
      future: LogisticsAPI.fetchMyInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("خطأ في الاتصال بالسيرفر ⚠️"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("لا توجد بضاعة في العهدة"));

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(item.product, style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("${item.quantity} ${item.unit}", 
                  style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  // 2. عرض التحويلات المعلقة (قيد التحضير)
  Widget _buildPendingTransfers() {
    return Center(child: Text("هنا ستظهر العهد المرسلة للمندوب لتأكيدها ✅"));
  }
}

