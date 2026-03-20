import 'package:flutter/material.dart';
// الأسطر الهامة جداً لنجاح الـ Build
import '../services/transfer_service.dart';
import '../models/transfer_model.dart';

class IncomingTransfersPage extends StatefulWidget {
  final String userToken;
  final String repCode;

  const IncomingTransfersPage({super.key, required this.userToken, required this.repCode});

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تأكيد استلام الأمانات (العهد)", style: TextStyle(fontSize: 18, fontFamily: 'Cairo')),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A237E), // كحلي لوجستي
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            )
          ],
        ),
        body: FutureBuilder<List<StockTransfer>>(
          future: _transfers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("حدث خطأ في الاتصال بالخادم", style: TextStyle(fontFamily: 'Cairo')));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("لا توجد عهد معلقة في الطريق حالياً", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return _buildTransferCard(item);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransferCard(StockTransfer item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("إذن رقم: ${item.transferNo}", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontFamily: 'Cairo')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800, 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: const Text("في عهدة الطريق", 
                    style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo')),
                ),
              ],
            ),
            const Divider(height: 25),
            Text(item.productName, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("الكمية المخصصة: ", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                Text("${item.quantity}", 
                  style: const TextStyle(fontSize: 20, color: Color(0xFF1A237E), fontWeight: FontWeight.w900)),
                const Text(" قطعة", style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirmReceiptDialog(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // أخضر تأكيد
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("تأكيد استلام الأمانات (العهد)", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.orange),
              const SizedBox(width: 10),
              const Text("تأكيد العهدة", style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
          content: const Text(
            "تأكيد العهدة: أنت تؤكد الآن استلام الشحنة في عهدتك الشخصية. سيتم تخصيص (نقاط أمان) من حسابك تعادل قيمة الشحنة لضمان النقل الآمن. لا يمكن التراجع بعد التأكيد.",
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("إلغاء", style: TextStyle(fontFamily: 'Cairo', color: Colors.red))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () async {
                Navigator.pop(context);
                bool success = await _service.confirmReceipt(item.id, widget.userToken);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم استلام العهدة بنجاح ✅", style: TextStyle(fontFamily: 'Cairo')))
                    );
                    _refreshData();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("فشل في تأكيد الاستلام، حاول مرة أخرى", style: TextStyle(fontFamily: 'Cairo')))
                    );
                  }
                }
              },
              child: const Text("تأكيد الاستلام", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}

