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
      id: json['id'] ?? 0,
      transferNo: json['transfer_no'] ?? '',
      // تأكدنا إن الاسم يقرأ من الحقل الصحيح في الـ API
      productName: json['product_name'] ?? 'صنف غير معرف', 
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

