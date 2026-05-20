class FoodOrderItemModel {
  final String name;
  final int qty;
  final double price;
  final String? note;

  FoodOrderItemModel({
    required this.name,
    required this.qty,
    required this.price,
    this.note,
  });

  factory FoodOrderItemModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderItemModel(
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'price': price,
        if (note != null) 'note': note,
      };
}
