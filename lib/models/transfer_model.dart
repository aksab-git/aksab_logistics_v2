class StockTransfer {
  final int id;
  final String transferNo;
  final String productName;
  final int quantity;
  final String status;
  final String createdAt;

  StockTransfer({
    required this.id,
    required this.transferNo,
    required this.productName,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      transferNo: json['transfer_no'],
      productName: json['product_name'] ?? json['product'].toString(), // حسب الـ Serializer
      quantity: json['quantity'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

