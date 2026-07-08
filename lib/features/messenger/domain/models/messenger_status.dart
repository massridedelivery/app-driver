/// Messenger order lifecycle (SCRUM-41 §1).
/// Note: messenger uses `ARRIVED_AT_PICKUP` (no middle underscore), unlike RIDE.
enum MessengerStatus {
  pending,
  accepted,
  arrivedAtPickup,
  pickedUp,
  delivered,
  cancelled,
  unknown;

  static MessengerStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return MessengerStatus.pending;
      case 'ACCEPTED':
        return MessengerStatus.accepted;
      case 'ARRIVED_AT_PICKUP':
        return MessengerStatus.arrivedAtPickup;
      case 'PICKED_UP':
        return MessengerStatus.pickedUp;
      case 'DELIVERED':
        return MessengerStatus.delivered;
      case 'CANCELLED':
        return MessengerStatus.cancelled;
      default:
        return MessengerStatus.unknown;
    }
  }
}
