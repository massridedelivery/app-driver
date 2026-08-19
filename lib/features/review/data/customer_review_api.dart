import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Which vertical a completed job belongs to — selects the review endpoint.
enum ReviewService { ride, food, messenger }

/// Posts a driver→customer review after a completed job/order.
///
/// The endpoints are pending backend (SCRUM-70); callers treat a failure as
/// non-fatal so a driver is never blocked on the review step.
class CustomerReviewApi {
  Dio get _dio => getIt<Dio>();

  Future<void> submit({
    required ReviewService service,
    required String jobId,
    required int rating,
    List<String> tags = const [],
    String? comment,
  }) async {
    final template = switch (service) {
      ReviewService.ride => Endpoints.driverRateRideJob,
      ReviewService.food => Endpoints.driverReviewFoodOrder,
      ReviewService.messenger => Endpoints.driverReviewMessengerOrder,
    };
    final path = template.replaceAll(':id', jobId);
    await _dio.post(
      path,
      data: {
        'rating': rating,
        'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }
}
