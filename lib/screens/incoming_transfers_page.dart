import 'package:flutter/material.dart';

class IncomingTransfersPage extends StatefulWidget {
  final String userToken;
  final String repCode;

  IncomingTransfersPage({required this.userToken, required this.repCode});

  @override
  _IncomingTransfersPageState createState() => _IncomingTransfersPageState();
}

class _IncomingTransfersPageState extends State<IncomingTransfersPage> {
  final TransferService _service = TransferService();
  late Future<List<StockTransfer>> _transfers;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _transfers = _service.getMyIncomingTransfers(widget.userToken, widget.repCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تأكيد استلام الأمانات (العهد)", style: TextStyle(fontSize: 18)),
        backgroundColor: Color(0xFF1A237E), // كحلي لوجستي
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      body: FutureBuilder<List<StockTransfer>>(
        future: _transfers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("حدث خطأ في الاتصال بالخادم"));
          if (snapshot.data!.isEmpty) return Center(child: Text("لا توجد عهد معلقة في الطريق حالياً"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildTransferCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransferCard(StockTransfer item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("إذن رقم: ${item.transferNo}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: Text("في عهدة الطريق", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            Divider(height: 25),
            Text(item.productName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("الكمية المخصصة: ${item.quantity}", style: TextStyle(fontSize: 20, color: Color(0xFF1A237E), fontWeight: FontWeight.w900)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirmReceiptDialog(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32), // أخضر تأكيد
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("تأكيد استلام الأمانات (العهد)", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReceiptDialog(StockTransfer item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.security, color: Colors.orange), Text(" تأكيد العهدة")]),
        content: Text("تأكيد العهدة: أنت تؤكد الآن استلام الشحنة في عهدتك الشخصية. سيتم خصم (نقاط أمان) من حسابك تعادل قيمة الشحنة لضمان النقل الآمن. لا يمكن التراجع بعد التأكيد."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _service.confirmReceipt(item.id, widget.userToken);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم استلام العهدة بنجاح ✅")));
                _refreshData();
              }
            },
            child: Text("تأكيد الاستلام"),
          ),
        ],
      ),
    );
  }
}

