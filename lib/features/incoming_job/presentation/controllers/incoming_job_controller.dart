import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';

part 'incoming_job_controller.g.dart';

@riverpod
class IncomingJobController extends _$IncomingJobController {
  StreamSubscription? _socketSubscription;

  @override
  IncomingJobState build() {
    final socket = ref.watch(socketServiceProvider);
    
    _socketSubscription?.cancel();
    _socketSubscription = socket.messages.listen((msg) {
      if (msg.type == 'job_offer') {
        try {
          final jobData = msg.data['job'] ?? msg.data;
          final job = IncomingJobModel.fromJson(jobData);
          receiveJob(job);
        } catch (e) {
          debugPrint('IncomingJobController Parse Error (job_offer): $e');
        }
      } else if (msg.type == 'job_status') {
        final jobId = msg.data['job_id'];
        final status = msg.data['status'];
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
