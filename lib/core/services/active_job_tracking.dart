import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/services/location_service.dart';

/// Wraps a job screen (ride / food / parcel): while it is up, location runs
/// on the trip profile — every 3 s, high accuracy — instead of the idle one.
class ActiveJobTracking extends ConsumerStatefulWidget {
  const ActiveJobTracking({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ActiveJobTracking> createState() => _ActiveJobTrackingState();
}

class _ActiveJobTrackingState extends ConsumerState<ActiveJobTracking> {
  // Read here: `ref` is off limits in dispose.
  late final LocationService _location;

  @override
  void initState() {
    super.initState();
    _location = ref.read(locationServiceProvider)..beginActiveJob();
  }

  @override
  void dispose() {
    _location.endActiveJob();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
