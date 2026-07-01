import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/incoming_job/data/sources/food_delivery_api_service.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'incoming_job_controller.g.dart';

@Riverpod(keepAlive: true)
class IncomingJobController extends _$IncomingJobController {
  StreamSubscription? _socketSubscription;

  @override
  IncomingJobState build() {
    final socket = ref.watch(socketServiceProvider);

    _socketSubscription?.cancel();
    _socketSubscription = socket.messages.listen((msg) {
      if (kDebugMode) {
        debugPrint('IncomingJobController Received Message: type=${msg.type}');
      }

      if (msg.type == 'job_offer') {
        if (kDebugMode) debugPrint('IncomingJobController: 📥 RECEIVED job_offer message');
        _handleJobOffer(msg.raw, msg.data);
      } else if (msg.type == 'food_delivery_offer') {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: 🍔 RECEIVED food_delivery_offer message',
          );
        }
        _handleFoodDeliveryOffer(msg.raw, msg.data);
      } else if (msg.type == 'job_accepted') {
        // Notification that the job is confirmed to us
        try {
          final jobData =
              msg.raw['job'] ?? msg.data?['job'] ?? msg.data ?? msg.raw;
          if (jobData is Map<String, dynamic>) {
            final job = IncomingJobModel.fromJson(jobData);
            state = state.copyWith(currentJob: job);
            if (kDebugMode) {
              debugPrint(
                'IncomingJobController: Job officially accepted: ${job.jobId}',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('IncomingJobController Parse Error (job_accepted): $e');
        }
      } else if (msg.type == 'job_status') {
        final jobId = msg.raw['job_id'] ?? msg.data?['job_id'];
        final status = msg.raw['status'] ?? msg.data?['status'];

        if (kDebugMode) {
          debugPrint(
            'IncomingJobController Status Change: job=$jobId, status=$status',
          );
        }

        if (state.currentJob?.jobId == jobId && status == 'CANCELLED') {
          dismissModal();
        }
      }
    });

    ref.onDispose(() {
      _socketSubscription?.cancel();
    });

    return const IncomingJobState();
  }

  /// Handle ride job_offer event
  void _handleJobOffer(
    Map<String, dynamic> raw,
    Map<String, dynamic>? data,
  ) {
    try {
      final jobData = raw['job'] ?? data?['job'] ?? data ?? raw;
      if (kDebugMode) debugPrint('IncomingJobController: Job Data extracted: $jobData');

      if (jobData is Map<String, dynamic> && jobData.containsKey('id')) {
        final job = IncomingJobModel.fromJson(jobData);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ✅ Ride Job parsed. ID=${job.jobId}',
          );
        }

        receiveJob(job);
        AppRouter.router.go(AppRoutes.incomingJobNamedPage);
      } else {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ⚠️ job_offer data invalid. Data: $jobData',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: ❌ Parse Error (job_offer): $e');
    }
  }

  /// Handle food_delivery_offer event
  void _handleFoodDeliveryOffer(
    Map<String, dynamic> raw,
    Map<String, dynamic>? data,
  ) {
    try {
      final jobData = raw['order'] ?? data?['order'] ?? data ?? raw;
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: Food Order Data extracted: $jobData',
        );
      }

      if (jobData is Map<String, dynamic> && jobData.containsKey('id')) {
        // Ensure service_type marks it as food if not already set
        final enrichedData = Map<String, dynamic>.from(jobData);
        enrichedData['service_type'] ??= 'MassFood';

        final job = IncomingJobModel.fromJson(enrichedData);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: 🍔 Food Job parsed. ID=${job.jobId}, '
            'restaurant=${job.restaurantName}, items=${job.orderItems.length}',
          );
        }

        receiveJob(job);
        AppRouter.router.go(AppRoutes.incomingJobNamedPage);
      } else {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ⚠️ food_delivery_offer data invalid. Data: $jobData',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: ❌ Parse Error (food_delivery_offer): $e',
        );
      }
    }
  }

  void receiveJob(IncomingJobModel job) {
    state = state.copyWith(currentJob: job, isModalVisible: true);
  }

  void resumeJob(IncomingJobModel job) {
    state = state.copyWith(currentJob: job, isModalVisible: false);
  }

  /// Accept a ride job via WebSocket
  void acceptJob() {
    final job = state.currentJob;
    if (job != null) {
      ref.read(socketServiceProvider).acceptJob(job.jobId);
      _sendLocationUpdate();
      
      state = state.copyWith(isModalVisible: false);
      final isFood = job.serviceType.toLowerCase().contains('food');
      if (isFood) {
        AppRouter.router.go(AppRoutes.foodLiveNamedPage);
      } else {
        AppRouter.router.go('/job-live');
      }
    } else {
      state = state.copyWith(isModalVisible: false);
    }
  }

  /// Accept a food delivery job via REST API
  Future<void> acceptFoodJob() async {
    final job = state.currentJob;
    if (job == null) return;

    try {
      final apiService = getIt<FoodDeliveryApiService>();
      await apiService.acceptOrder(job.jobId);
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: 🍔 Food job accepted via REST API: ${job.jobId}',
        );
      }
      _sendLocationUpdate();
      
      state = state.copyWith(isModalVisible: false);
      AppRouter.router.go(AppRoutes.foodLiveNamedPage);
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: ❌ Failed to accept food job: $e');
    }
  }

  void declineJob() {
    final job = state.currentJob;
    if (job != null) {
      ref.read(socketServiceProvider).rejectJob(job.jobId);
      _sendLocationUpdate();
    }
    state = state.copyWith(isModalVisible: false, currentJob: null);
    AppRouter.router.go('/');
  }

  void dismissModal() {
    state = state.copyWith(isModalVisible: false, currentJob: null);
    _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final socketService = ref.read(socketServiceProvider);
      if (socketService.isConnected) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        socketService.sendLocationUpdate(position.latitude, position.longitude);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: Sent location_update after job flow',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: Error sending location update: $e');
    }
  }
}
