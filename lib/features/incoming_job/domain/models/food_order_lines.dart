/// One food item as the driver sees it. The backend's order item is
/// `{name, quantity, unit_price, subtotal, notes}`; older payloads used
/// `{name, qty, price, note}`. Both are read, numbers may arrive as int,
/// double or string.
class FoodOrderLine {
  const FoodOrderLine({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.note,
  });

  final String name;
  final int qty;
  final double unitPrice;

  /// What this line costs: the backend's `subtotal` when sent (it includes
  /// modifiers), else unit price × qty.
  final double lineTotal;
  final String? note;

  factory FoodOrderLine.fromMap(Map<String, dynamic> m) {
    final qty = _num(m['quantity'] ?? m['qty'])?.round() ?? 1;
    final unit = _num(m['unit_price'] ?? m['price']) ?? 0;
    final sub = _num(m['subtotal']);
    final note = (m['notes'] ?? m['note'])?.toString().trim();
    return FoodOrderLine(
      name: m['name']?.toString() ?? '',
      qty: qty < 1 ? 1 : qty,
      unitPrice: unit,
      lineTotal: sub ?? unit * (qty < 1 ? 1 : qty),
      note: (note == null || note.isEmpty) ? null : note,
    );
  }

  static List<FoodOrderLine> listFrom(List<Map<String, dynamic>>? items) =>
      (items ?? const []).map(FoodOrderLine.fromMap).toList();
}

/// Food subtotal / delivery fee / total for an order. The backend's
/// `subtotal` wins when it's set; otherwise the lines are summed.
class FoodOrderTotals {
  const FoodOrderTotals({
    required this.itemsSubtotal,
    required this.deliveryFee,
  });

  final double itemsSubtotal;
  final double deliveryFee;
  double get total => itemsSubtotal + deliveryFee;

  factory FoodOrderTotals.from({
    required List<FoodOrderLine> lines,
    double subtotal = 0,
    double deliveryFee = 0,
  }) {
    final summed = lines.fold<double>(0, (s, l) => s + l.lineTotal);
    return FoodOrderTotals(
      itemsSubtotal: subtotal > 0 ? subtotal : summed,
      deliveryFee: deliveryFee,
    );
  }
}

double? _num(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v.trim()) : null);
