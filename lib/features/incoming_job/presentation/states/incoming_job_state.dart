import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';

part 'incoming_job_state.freezed.dart';

@freezed
sealed class IncomingJobState with _$IncomingJobState {
  const IncomingJobState._();

  const factory IncomingJobState({
    IncomingJobModel? currentJob,
    @Default(false) bool isModalVisible,
  }) = _IncomingJobState;
}
