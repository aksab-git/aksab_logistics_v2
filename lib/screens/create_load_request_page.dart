import 'package:flutter/material.dart';
import '../models/load_request_model.dart';
import '../models/product_model.dart';
import '../services/load_request_service.dart';
import '../services/product_service.dart'; // ✅ أضفنا استيراد خدمة المنتجات
import 'product_search_delegate.dart';

class CreateLoadRequestPage extends StatefulWidget {
  final String userToken;
  final int repId;
  final int myWarehouseId;
  final List<Product>? availableProducts; // ✅ جعلناها اختيارية

  const CreateLoadRequestPage({
    super.key,
    required this.userToken,
    required this.repId,
    required this.myWarehouseId,
    this.availableProducts,
  });

  @override
  _CreateLoadRequestPageState createState() => _CreateLoadRequestPageState();
}

class _CreateLoadRequestPageState extends State<CreateLoadRequestPage> {
  final List<LoadRequestItem> _selectedItems = [];
  final LoadRequestService _service = LoadRequestService();
  final ProductService _productService = ProductService(); // ✅ تعريف الخدمة
  final TextEditingController _notesController = TextEditingController();
  
  List<Product> _allProducts = []; // القائمة المحلية التي سيتم البحث فيها
  bool _isLoading = false;
  bool _isFetchingProducts = true; // ✅ متغير لحالة تحميل المنتجات

  @override
  void initState() {
    super.initState();
    // ✅ إذا كانت المنتجات ممررة جاهزة نستخدمها، وإلا نسحبها من السيرفر
    if (widget.availableProducts != null && widget.availableProducts!.isNotEmpty) {
      _allProducts = widget.availableProducts!;
      _isFetchingProducts = false;
    } else {
      _loadProducts();
    }
  }

  // ✅ دالة سحب المنتجات من السيرفر
  Future<void> _loadProducts() async {
    setState(() => _isFetchingProducts = true);
    try {
      final products = await _productService.getAllProducts(widget.userToken);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isFetchingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل في تحديث قائمة المنتجات")),
        );
      }
    }
  }

  void _pickProduct() async {
    // 🛡️ منع البحث لو القائمة لسه بتتحمل
    if (_isFetchingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى الانتظار حتى اكتمال تحميل المنتجات..."))
      );
      return;
    }

    final Product? selected = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(_allProducts), // استخدام القائمة المحلية
    );

    if (selected != null) {
      bool exists = _selectedItems.any((item) => item.productId == selected.id);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("هذا الصنف مضاف بالفعل في القائمة", style: TextStyle(fontFamily: 'Cairo')))
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

  void _submitRequest() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("برجاء إضافة أصناف أولاً", style: TextStyle(fontFamily: 'Cairo')))
      );
      return;
    }

    setState(() => _isLoading = true);

    final requestHeader = LoadRequestHeader(
      repId: widget.repId,
      sourceWarehouseId: 1, 
      myWarehouseId: widget.myWarehouseId,
      items: _selectedItems,
      notes: _notesController.text,
    );

    bool success = await _service.sendLoadRequest(requestHeader, widget.userToken);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال طلب التحميل بنجاح ✅ (بإنتظار الموافقة)", style: TextStyle(fontFamily: 'Cairo')))
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في إرسال الطلب، حاول مرة أخرى ❌", style: TextStyle(fontFamily: 'Cairo')))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إنشاء طلب تحميل (عُهدة)", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          actions: [
            // ✅ إظهار علامة تحميل بسيطة في الـ AppBar لو لسه بيسحب المنتجات
            if (_isFetchingProducts)
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            else
              IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: _pickProduct),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: const Text(
                "ملاحظة: سيظهر الطلب كـ (DRAFT) في لوحة الإدارة للمراجعة والموافقة.",
                style: TextStyle(fontSize: 12, color: Colors.orange, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _selectedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            _isFetchingProducts ? "جاري تحديث قائمة المنتجات..." : "اضغط على الزر بالأعلى لإضافة أصناف",
                            style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            subtitle: Text("الوحدة: ${item.unit}", style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  onPressed: () => setState(() => item.quantity > 1 ? item.quantity-- : null),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
                                  child: Text("${item.quantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => setState(() => item.quantity++),
                                ),
                                const VerticalDivider(),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                                  onPressed: () => setState(() => _selectedItems.removeAt(index)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: "إضافة ملاحظات للإدارة (اختياري)...",
                  hintStyle: TextStyle(fontSize: 13, fontFamily: 'Cairo'),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("إرسال طلب التحميل للمراجعة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            )
          ],
        ),
      ),
    );
  }
}

