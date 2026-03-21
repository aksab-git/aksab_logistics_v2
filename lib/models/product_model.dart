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

  // المابينج من جيسون الباكيند (Django) للفرونت إيند
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'] ?? '',
      unit: json['unit'] ?? '',
      sellingPrice: double.parse((json['selling_price'] ?? 0).toString()),
    );
  }
}

