import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> allProducts;

  ProductSearchDelegate(this.allProducts) {
    // ✅ طباعة للتأكد إن فيه بضاعة جاية من السيرفر للبحث
    print("SearchDelegate initialized with ${allProducts.length} products");
  }

  @override
  String get searchFieldLabel => "ابحث باسم الصنف أو الكود (SKU)...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    // فلترة الأصناف بناءً على الاسم أو الـ SKU (كود الصنف)
    final suggestions = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      final skuLower = p.sku.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower) || skuLower.contains(searchLower);
    }).toList();

    if (suggestions.isEmpty) {
      return const Center(
        child: Text("لم يتم العثور على أصناف مطابقة", 
          style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final product = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1A237E)),
            title: Text(product.name, 
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text("كود: ${product.sku} | الوحدة: ${product.unit}",
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            onTap: () {
              // ✅ طباعة الصنف المختار للتأكد
              print("Selected Product: ${product.name} (ID: ${product.id})");
              close(context, product);
            },
          );
        },
      ),
    );
  }
}

