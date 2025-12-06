class OrderModel {
  final String id;
  final bool isParcel;
  final List<OrderItem> items;
  final double total;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.isParcel,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      isParcel: json['isParcel'] ?? true, // defaulted to true if null logic
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      total: (json['total'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  OrderItem({required this.name, required this.quantity});
  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      OrderItem(name: json['name'], quantity: json['quantity']);
}
