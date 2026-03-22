import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/load_request_model.dart';
import '../models/product_model.dart';
import '../services/load_request_service.dart';
import '../services/product_service.dart';
import 'product_search_delegate.dart';

class CreateLoadRequestPage extends StatefulWidget {
  final String userToken;
  final int repId;
  final int myWarehouseId;
  final List<Product>? availableProducts;

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
  final ProductService _productService = ProductService();
  final TextEditingController _notesController = TextEditingController();
  
  List<Product> _allProducts = [];
  bool _isLoading = false;
  bool _isFetchingProducts = true;

  // متغيرات للفحص (Debugging)
  String _debugRawResponse = "لا توجد بيانات بعد";
  String _debugError = "";

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isFetchingProducts = true;
      _debugError = "";
    });

    print("🚀 جاري سحب المنتجات باستخدام توكن: ${widget.userToken.substring(0, 5)}...");
    
    try {
      final products = await _productService.getAllProducts(widget.userToken);
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isFetchingProducts = false;
          _debugRawResponse = "تم جلب ${products.length} منتج بنجاح";
        });
        print("✅ تم جلب ${_allProducts.length} منتج");
      }
    } catch (e) {
      print("❌ خطأ في صفحة التحميل: $e");
      if (mounted) {
        setState(() {
          _isFetchingProducts = false;
          _debugError = e.toString();
          _debugRawResponse = "حدث خطأ أثناء الاتصال: $e";
        });
      }
    }
  }

  // نافذة لعرض تفاصيل الخطأ (الرادار)
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("رادار فحص المنتجات", style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("عدد المنتجات المحملة: ${_allProducts.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              const Text("حالة الاستجابة:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_debugRawResponse, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              if (_debugError.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("الخطأ التقني:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text(_debugError, style: const TextStyle(fontSize: 10, color: Colors.red)),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")),
        ],
      ),
    );
  }

  void _pickProduct() async {
    if (_allProducts.isEmpty && !_isFetchingProducts) {
       _loadProducts(); // محاولة التحميل مرة أخرى لو القائمة فاضية
    }

    final Product? selected = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(_allProducts),
    );

    if (selected != null) {
      bool exists = _selectedItems.any((item) => item.productId == selected.id);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("هذا الصنف مضاف بالفعل", style: TextStyle(fontFamily: 'Cairo')))
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
    if (_selectedItems.isEmpty) return;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال بنجاح ✅")));
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل في الإرسال ❌")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إنشاء طلب تحميل", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          actions: [
            // زر الرادار الصغير للفحص
            IconButton(icon: const Icon(Icons.bug_report, color: Colors.orange), onPressed: _showDebugInfo),
            if (_isFetchingProducts)
              const Center(child: Padding(padding: EdgeInsets.all(15), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
            else
              IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: _pickProduct),
          ],
        ),
        body: Column(
          children: [
            if (_isFetchingProducts)
              const LinearProgressIndicator(backgroundColor: Colors.orange, color: Colors.blue),
            Expanded(
              child: _selectedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_business_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(_isFetchingProducts ? "جاري جلب قائمة المنتجات..." : "اضغط على علامة السلة لإضافة أصناف", 
                               style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            subtitle: Text("الوحدة: ${item.unit}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => item.quantity > 1 ? item.quantity-- : null)),
                                Text("${item.quantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => setState(() => item.quantity++)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => setState(() => _selectedItems.removeAt(index))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _notesController,
                decoration: const InputDecoration(hintText: "ملاحظات اختياري...", border: OutlineInputBorder()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال الطلب", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

