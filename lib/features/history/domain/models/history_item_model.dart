enum PaymentType { grabPay, cash }

enum HistoryStatus { completed, cancelled }

enum ServiceType { ride, food }

class HistoryItemModel {
  final String id;
  final DateTime dateTime;
  final String title;
  final double? amount;
  final PaymentType? paymentType;
  final HistoryStatus status;
  final ServiceType serviceType;
  final String? rawType; // 'FARE_PAYMENT', 'COMMISSION_DEDUCTION', 'TOPUP', 'WITHDRAWAL', etc.

  /// Trip/job this transaction belongs to (`job_id`), used to load the trip
  /// detail. Null for non-trip entries (top-up, withdrawal).
  final String? jobId;

  /// `ride` | `food` | `messenger` when the API says so.
  final String? service;

  /// The job's vehicle type (e.g. "motorcycle"), joined from the trip list.
  final String? vehicleTypeName;

  /// The job's backend whole-baht `driver_net`, joined from the trip list.
  final int? tripNet;

  final String? pickupAddress;

  HistoryItemModel({
    required this.id,
    required this.dateTime,
    required this.title,
    this.amount,
    this.paymentType,
    required this.status,
    this.serviceType = ServiceType.ride,
    this.rawType,
    this.jobId,
    this.service,
    this.vehicleTypeName,
    this.tripNet,
    this.pickupAddress,
  });

  /// Belongs to a trip (fare, commission…). Top-ups, adjustments and
  /// withdrawals have no job and live in their own history screens.
  bool get isTripEntry => jobId != null && jobId!.isNotEmpty;

  HistoryItemModel withTrip({String? vehicleTypeName, int? tripNet}) =>
      HistoryItemModel(
    id: id,
    dateTime: dateTime,
    title: title,
    amount: amount,
    paymentType: paymentType,
    status: status,
    serviceType: serviceType,
    rawType: rawType,
    jobId: jobId,
    service: service,
    vehicleTypeName: vehicleTypeName,
    tripNet: tripNet,
    pickupAddress: pickupAddress,
  );
}

