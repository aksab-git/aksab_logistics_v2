class InventoryItem {
  final String product;
  final int quantity;
  final String unit;

  InventoryItem({
    required this.product,
    required this.quantity,
    required this.unit,
  });

  // تحويل البيانات القادمة من Django JSON إلى كائن Dart
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      product: json['product_name'] ?? json['product'] ?? 'منتج غير معروف',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'قطعة',
    );
  }
}
