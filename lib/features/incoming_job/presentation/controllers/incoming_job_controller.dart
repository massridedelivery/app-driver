import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';

part 'incoming_job_controller.g.dart';

@riverpod
class IncomingJobController extends _$IncomingJobController {
  @override
  IncomingJobState build() {
    return const IncomingJobState();
  }

  void receiveJob(IncomingJobModel job) {
    state = state.copyWith(
      currentJob: job,
      isModalVisible: true,
    );
  }

  void acceptJob() {
    // TODO: Send acceptance through socket API
    state = state.copyWith(isModalVisible: false);
  }

  void declineJob() {
    // TODO: Send decline through socket API
    state = state.copyWith(isModalVisible: false, currentJob: null);
  }

  void dismissModal() {
    state = state.copyWith(isModalVisible: false, currentJob: null);
  }
}
