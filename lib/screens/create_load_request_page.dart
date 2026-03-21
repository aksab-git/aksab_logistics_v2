import 'package:flutter/material.dart';
import '../models/load_request_model.dart';
import '../models/product_model.dart'; // تأكد من وجود موديل المنتج هنا
import '../services/load_request_service.dart';
import 'product_search_delegate.dart';

class CreateLoadRequestPage extends StatefulWidget {
  final String userToken;
  final int repId;
  final int myWarehouseId;
  final List<Product> availableProducts; // قائمة المنتجات اللي هيبحث فيها

  const CreateLoadRequestPage({
    super.key, 
    required this.userToken, 
    required this.repId, 
    required this.myWarehouseId,
    required this.availableProducts,
  });

  @override
  _CreateLoadRequestPageState createState() => _CreateLoadRequestPageState();
}

class _CreateLoadRequestPageState extends State<CreateLoadRequestPage> {
  final List<LoadRequestItem> _selectedItems = [];
  final LoadRequestService _service = LoadRequestService();
  bool _isLoading = false;

  // فتح شاشة البحث واختيار صنف
  void _pickProduct() async {
    final Product? selected = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(widget.availableProducts),
    );

    if (selected != null) {
      // التأكد إن الصنف مضافش قبل كدة
      bool exists = _selectedItems.any((item) => item.productId == selected.id);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("هذا الصنف مضاف بالفعل في القائمة"))
        );
        return;
      }

      setState(() {
        _selectedItems.add(LoadRequestItem(
          productId: selected.id,
          productName: selected.name,
          unit: selected.unit,
          quantity: 1,
        ));
      });
    }
  }

  // إرسال طلب التحميل للباكيند
  void _submitRequest() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("برجاء إضافة أصناف أولاً"))
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final requestHeader = LoadRequestHeader(
      repId: widget.repId,
      sourceWarehouseId: 1, // افترضنا أن مخزن الإدارة هو ID 1
      myWarehouseId: widget.myWarehouseId,
      items: _selectedItems,
    );

    bool success = await _service.sendLoadRequest(requestHeader, widget.userToken);
    
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال طلب التحميل بنجاح ✅"))
      );
      Navigator.pop(context); // العودة للشاشة السابقة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في إرسال الطلب، حاول مرة أخرى ❌"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إنشاء طلب تحميل (عُهدة)"),
          backgroundColor: const Color(0xFF1A237E),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: _pickProduct),
          ],
        ),
        body: Column(
          children: [
            // قائمة الأصناف المختارة
            Expanded(
              child: _selectedItems.isEmpty 
                ? const Center(child: Text("اضغط على أيقونة البحث لإضافة أصناف للعهدة"))
                : ListView.builder(
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("الوحدة: ${item.unit}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setState(() => item.quantity > 1 ? item.quantity-- : null),
                              ),
                              Text("${item.quantity}", style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => setState(() => item.quantity++),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => setState(() => _selectedItems.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            // زر الإرسال النهائي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _submitRequest, 
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("تأكيد طلب العُهدة", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

