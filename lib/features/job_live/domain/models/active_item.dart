/// Vertical of an active job/order (SCRUM-45 §3).
enum ActiveJobType {
  ride,
  food,
  messenger,
  unknown;

  static ActiveJobType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'RIDE':
        return ActiveJobType.ride;
      case 'FOOD':
        return ActiveJobType.food;
      case 'MESSENGER':
        return ActiveJobType.messenger;
      default:
        return ActiveJobType.unknown;
    }
  }
}

/// Lean cross-vertical index item from `GET /api/driver/active` (SCRUM-45).
/// Carries just enough to route: probe here for `type`+`id`+`status`, then
/// fetch full detail from the per-vertical endpoint.
class ActiveItem {
  final String id;
  final ActiveJobType type;

  /// Vertical-specific status (e.g. RIDE: ACCEPTED/ARRIVED_AT_PICK_UP/PICKED_UP).
  final String status;

  /// Counterparty — always present on the driver route.
  final String customerId;

  /// Sort key; the API returns items newest-first.
  final DateTime? createdAt;

  const ActiveItem({
    required this.id,
    required this.type,
    required this.status,
    required this.customerId,
    this.createdAt,
  });

  factory ActiveItem.fromJson(Map<String, dynamic> json) => ActiveItem(
        id: json['id']?.toString() ?? '',
        type: ActiveJobType.fromApi(json['type']?.toString()),
        status: json['status']?.toString() ?? '',
        customerId: json['customer_id']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
