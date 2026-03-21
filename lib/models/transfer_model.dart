import 'dart:convert';

class StockTransfer {
  final int id;
  final String transferNo;
  final String senderName;
  final String receiverName;
  final String status;
  final String statusDisplay;
  final List<TransferItem> items; // القائمة الجديدة للأصناف
  final String createdAt;

  StockTransfer({
    required this.id,
    required this.transferNo,
    required this.senderName,
    required this.receiverName,
    required this.status,
    required this.statusDisplay,
    required this.items,
    required this.createdAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<TransferItem> itemsList = list.map((i) => TransferItem.fromJson(i)).toList();

    return StockTransfer(
      id: json['id'],
      transferNo: json['transfer_no'],
      senderName: json['sender_name'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      status: json['status'],
      statusDisplay: json['status_display'] ?? '',
      items: itemsList,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TransferItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final String unitAtTransfer;
  final bool isReceived;

  TransferItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitAtTransfer,
    required this.isReceived,
  });

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'],
      productId: json['product'],
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      quantity: json['quantity'],
      unitAtTransfer: json['unit_at_transfer'] ?? '',
      isReceived: json['is_received'] ?? false,
    );
  }
}

