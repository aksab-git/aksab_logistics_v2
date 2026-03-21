import 'package:flutter/material.dart';
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

  // ✅ نافذة كشف الأعطال تظهر فوق التطبيق (Debug Panel)
  void _showDebugPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("سجل البيانات الخام (Debug)", 
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Colors.white24),
              const Text("الطلب المرسل للمندوب:", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              Text(widget.repCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("رد السيرفر الحالي:", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                child: SelectableText(
                  TransferService.lastRawResponse,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تأكيد استلام الأمانات (العهد)", 
            style: TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A237E), 
          foregroundColor: Colors.white,
          actions: [
            // ✅ زرار الكشاف التقني
            IconButton(icon: const Icon(Icons.bug_report, color: Colors.orangeAccent), onPressed: _showDebugPanel),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData)
          ],
        ),
        // ✅ زرار عائم للوصول السريع للـ Debug
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange[800],
          onPressed: _showDebugPanel,
          child: const Icon(Icons.code, color: Colors.white),
        ),
        body: FutureBuilder<List<StockTransfer>>(
          future: _transfers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            // ✅ تم تصحيح هذا الجزء لإزالة const التي تسببت في فشل البناء
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      "لا توجد عهد معلقة حالياً", 
                      style: TextStyle(
                        fontFamily: 'Cairo', 
                        color: Colors.grey[600], 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showDebugPanel, 
                      icon: const Icon(Icons.terminal),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      label: const Text("فحص الرد التقني", style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                    ),
                    if (snapshot.hasError) 
                      TextButton(onPressed: _refreshData, child: const Text("إعادة المحاولة", style: TextStyle(fontFamily: 'Cairo')))
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildTransferCard(snapshot.data![index]),
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
      elevation: 4,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text("إذن رقم: ${item.transferNo}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontFamily: 'Cairo')),
        subtitle: Text("الحالة: ${item.statusDisplay}", 
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.orange)),
        children: [
          const Divider(),
          ...item.items.map((product) => ListTile(
            leading: product.productImage != null 
              ? Image.network(
                  product.productImage!, 
                  width: 40, 
                  errorBuilder: (c, e, s) => const Icon(Icons.inventory_2, color: Colors.grey),
                )
              : const Icon(Icons.inventory_2, color: Colors.grey),
            title: Text(product.productName, 
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
            trailing: Text("${product.quantity} ${product.unitAtTransfer}", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo')),
          )),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () => _confirmReceiptDialog(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("تأكيد استلام كامل الإذن",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReceiptDialog(StockTransfer item) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد العهدة", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Text(
            "هل أنت متأكد من استلام كافة الأصناف في الإذن رقم ${item.transferNo}؟ سيتم نقلها لعهدتك الشخصية فوراً.",
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("إلغاء", style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                bool success = await _service.confirmReceipt(item.id, widget.userToken);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم تأكيد العهدة بنجاح ✅", style: TextStyle(fontFamily: 'Cairo')))
                    );
                    _refreshData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text("تأكيد", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}

