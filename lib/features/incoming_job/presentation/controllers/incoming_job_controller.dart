import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';
import 'package:massdrive/router/app_routes.dart';

part 'incoming_job_controller.g.dart';

@Riverpod(keepAlive: true)
class IncomingJobController extends _$IncomingJobController {
  StreamSubscription? _socketSubscription;

  @override
  IncomingJobState build() {
    final socket = ref.watch(socketServiceProvider);
    
    _socketSubscription?.cancel();
    _socketSubscription = socket.messages.listen((msg) {
      debugPrint('IncomingJobController Received Message: type=${msg.type}');
      
      if (msg.type == 'job_offer') {
        debugPrint('IncomingJobController: Detected job_offer! Checking data...');
        try {
          // Priority: raw['job'], data['job'], data, raw
          final jobData = msg.raw['job'] ?? msg.data?['job'] ?? msg.data ?? msg.raw;
          
          if (jobData is Map<String, dynamic> && jobData.containsKey('id')) {
             final job = IncomingJobModel.fromJson(jobData);
             debugPrint('IncomingJobController: Job parsed. ID=${job.jobId}. Status: PENDING');
             receiveJob(job);
             
             // Automatically navigate to the Incoming Job screen
             debugPrint('IncomingJobController: Navigating to ${AppRoutes.incomingJobNamedPage}');
             AppRouter.router.push(AppRoutes.incomingJobNamedPage);
          } else {
             debugPrint('IncomingJobController: job_offer data invalid or missing id. Data: $jobData');
          }
        } catch (e) {
          debugPrint('IncomingJobController Parse Error (job_offer): $e');
        }
      } else if (msg.type == 'job_accepted') {
        // Notification that the job is confirmed to us
        try {
          final jobData = msg.raw['job'] ?? msg.data?['job'] ?? msg.data ?? msg.raw;
          if (jobData is Map<String, dynamic>) {
            final job = IncomingJobModel.fromJson(jobData);
            state = state.copyWith(currentJob: job);
            debugPrint('IncomingJobController: Job officially accepted: ${job.jobId}');
          }
        } catch (e) {
          debugPrint('IncomingJobController Parse Error (job_accepted): $e');
        }
      } else if (msg.type == 'job_status') {
        final jobId = msg.raw['job_id'] ?? msg.data?['job_id'];
        final status = msg.raw['status'] ?? msg.data?['status'];
        
        debugPrint('IncomingJobController Status Change: job=$jobId, status=$status');
        
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

  void receiveJob(IncomingJobModel job) {
    state = state.copyWith(
      currentJob: job,
      isModalVisible: true,
    );
  }

  void acceptJob() {
    final job = state.currentJob;
    if (job != null) {
      ref.read(socketServiceProvider).acceptJob(job.jobId);
    }
    state = state.copyWith(isModalVisible: false);
  }

  void declineJob() {
    final job = state.currentJob;
    if (job != null) {
      ref.read(socketServiceProvider).rejectJob(job.jobId);
    }
    state = state.copyWith(isModalVisible: false, currentJob: null);
  }

  void dismissModal() {
    state = state.copyWith(isModalVisible: false, currentJob: null);
  }
}
