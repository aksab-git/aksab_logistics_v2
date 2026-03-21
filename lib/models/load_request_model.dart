class LoadRequestItem {
  final int productId;
  final String productName;
  final String unit;
  int quantity;

  LoadRequestItem({
    required this.productId,
    required this.productName,
    required this.unit,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'product': productId,
    'quantity': quantity,
    'unit_at_transfer': unit,
  };
}

class LoadRequestHeader {
  final int repId;
  final int sourceWarehouseId;
  final int myWarehouseId;
  final List<LoadRequestItem> items;

  LoadRequestHeader({
    required this.repId,
    required this.sourceWarehouseId,
    required this.myWarehouseId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'requested_by': repId,
    'sender_warehouse': sourceWarehouseId,
    'receiver_warehouse': myWarehouseId,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

