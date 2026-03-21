class LoadRequestHeader {
  final int repId;
  final int sourceWarehouseId;
  final int myWarehouseId;
  final List<LoadRequestItem> items;
  final String? notes;

  LoadRequestHeader({
    required this.repId,
    required this.sourceWarehouseId,
    required this.myWarehouseId,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'requested_by': repId,
      'sender_warehouse': sourceWarehouseId,
      'receiver_warehouse': myWarehouseId,
      'status': 'DRAFT', // الحالة الابتدائية حسب transactions.py
      'notes': notes ?? '',
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class LoadRequestItem {
  final int productId;
  final String productName;
  final String unit;
  int quantity;

  LoadRequestItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity': quantity,
      'unit_at_transfer': unit, // مطابقة للحقل في TransferItem model
    };
  }
}

