class Product {
  final int id;
  final String name;
  final String sku;
  final String unit;
  final double sellingPrice;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.sellingPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'صنف غير معروف',
      sku: json['sku'] ?? json['product_code'] ?? '', // مرونة في اسم الكود
      unit: json['unit'] ?? '',
      // دعم لأسماء الحقول المختلفة (price أو selling_price) لضمان عدم حدوث Error
      sellingPrice: double.tryParse((json['selling_price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
    );
  }
}

