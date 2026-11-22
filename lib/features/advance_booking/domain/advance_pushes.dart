import 'package:flutter/foundation.dart';

/// Pushes about the driver's rides booked ahead (`data.type`). Each opens
/// "งานของฉัน" (`screen=advance_jobs`, `deeplink=/advance-jobs`).
const advanceBookingPushTypes = {
  'drv_free_release', // 30 min before the free release ends
  'drv_t60', // an hour before pickup: "กำลังไป" opens
  'drv_set_off', // 15 min before set_off_by
  'advance_job_released', // didn't set off in time: given to another driver
  'advance_job_cancelled', // the customer cancelled
  'advance_job_assigned', // the back office gave the driver a ride
  'advance_job_unassigned', // the back office took it back, no fee
};

/// A push for the driver's rides booked ahead — the current names, or the
/// older `advance_booking_drv_*` reminders (which pointed at /live/{job_id}).
bool isAdvanceBookingPush(Map<String, dynamic> data) {
  final type = data['type']?.toString() ?? '';
  return advanceBookingPushTypes.contains(type) ||
      type.startsWith('advance_booking_drv_');
}

/// Bumped by an advance booking push: the board and "งานของฉัน" re-read.
/// A plain notifier: the push service has no Riverpod.
class AdvanceBookingUpdates extends ChangeNotifier {
  AdvanceBookingUpdates._();
  static final AdvanceBookingUpdates instance = AdvanceBookingUpdates._();

  void notifyChanged() => notifyListeners();
}
