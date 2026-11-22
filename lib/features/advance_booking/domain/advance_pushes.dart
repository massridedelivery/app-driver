import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/app_routes.dart';

/// Pushes about the driver's rides booked ahead (`data.type`, with
/// `job_id`). Each opens "งานของฉัน" (`screen=advance_jobs`,
/// `route` = `deeplink` = `/advance-jobs`).
const advanceBookingPushTypes = {
  'drv_free_release', // 30 min before the free release ends
  'drv_t60', // an hour before pickup: "กำลังไป" opens
  'drv_set_off', // 15 min before set_off_by
  'advance_job_released', // didn't set off in time: given to another driver
  'advance_job_cancelled', // the customer cancelled
  'advance_job_assigned', // the back office gave the driver a ride
  'advance_job_unassigned', // the back office took it back, no fee
};

/// The pushes after which the ride is still the driver's, in "งานของฉัน":
/// the reminders and a back-office assignment. After released / cancelled /
/// unassigned it is gone from the list.
const _pushesKeepingRide = {
  'drv_free_release',
  'drv_t60',
  'drv_set_off',
  'advance_job_assigned',
};

/// A push for the driver's rides booked ahead — the current names, or the
/// older `advance_booking_drv_*` reminders (which pointed at /live/{job_id}).
bool isAdvanceBookingPush(Map<String, dynamic> data) {
  final type = data['type']?.toString() ?? '';
  return advanceBookingPushTypes.contains(type) ||
      type.startsWith('advance_booking_drv_');
}

/// The ride to highlight in "งานของฉัน" for [data]: its `job_id` when the
/// ride is still the driver's, null when the push says it left them.
String? advancePushHighlight(Map<String, dynamic> data) {
  if (!isAdvanceBookingPush(data)) return null;
  final type = data['type']?.toString() ?? '';
  final keeps =
      _pushesKeepingRide.contains(type) ||
      type.startsWith('advance_booking_drv_');
  final id = data['job_id']?.toString().trim() ?? '';
  return keeps && id.isNotEmpty ? id : null;
}

/// Where tapping [data] goes: "งานของฉัน", with `?job=` for the ride to
/// highlight.
String advanceJobsLocation(Map<String, dynamic> data) =>
    advanceJobsLocationFor(advancePushHighlight(data));

String advanceJobsLocationFor(String? jobId) => jobId == null
    ? AppRoutes.advanceJobsNamedPage
    : '${AppRoutes.advanceJobsNamedPage}?job=${Uri.encodeQueryComponent(jobId)}';

/// Bumped by an advance booking push: the board and "งานของฉัน" re-read.
/// A plain notifier: the push service has no Riverpod.
class AdvanceBookingUpdates extends ChangeNotifier {
  AdvanceBookingUpdates._();
  static final AdvanceBookingUpdates instance = AdvanceBookingUpdates._();

  /// The ride the latest event asks an open "งานของฉัน" to highlight (a
  /// tapped push); null for a plain refresh.
  String? get highlightJobId => _highlightJobId;
  String? _highlightJobId;

  void notifyChanged({String? highlightJobId}) {
    _highlightJobId = highlightJobId;
    notifyListeners();
  }
}
