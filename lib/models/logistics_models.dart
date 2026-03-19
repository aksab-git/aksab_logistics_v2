// lib/models/logistics_models.dart

class InventoryItem {
  final String product;
  final int quantity;
  final String unit;

  InventoryItem({required this.product, required this.quantity, required this.unit});

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      product: json['product_name'], // الاسم اللي بعتناه من السيريالايزر
      quantity: json['stock_quantity'],
      unit: json['unit'],
    );
  }
}

