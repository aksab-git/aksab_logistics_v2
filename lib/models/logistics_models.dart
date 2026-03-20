class InventoryItem {
  final String product;
  final int quantity;
  final String unit;
  final String productCode; // ضفنا الكود عشان مهم للمندوب

  InventoryItem({
    required this.product,
    required this.quantity,
    required this.unit,
    required this.productCode,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      // 1. بندور على الاسم في product_name (اللي الـ Serializer بيبعته)
      product: json['product_name'] ?? 'منتج غير معروف',
      
      // 2. ⚠️ التغيير الأهم: السيرفر بيبعت stock_quantity حسب الكود بتاعك
      quantity: json['stock_quantity'] ?? json['quantity'] ?? 0,
      
      // 3. لو مفيش وحدة من السيرفر، بنثبتها "قطعة" مؤقتاً
      unit: json['unit'] ?? 'قطعة',

      // 4. كود المنتج للبحث والجرد
      productCode: json['product_code'] ?? '---',
    );
  }
}
