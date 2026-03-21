import 'package:flutter/material.dart';
import '../models/product_model.dart'; // تأكد من وجود موديل المنتج

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> allProducts;

  ProductSearchDelegate(this.allProducts);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];
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
    final suggestions = allProducts.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase()) || 
             p.sku.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text("SKU: ${product.sku} - الوحدة: ${product.unit}"),
          onTap: () => close(context, product),
        );
      },
    );
  }
}

