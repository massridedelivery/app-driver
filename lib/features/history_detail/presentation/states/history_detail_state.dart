import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

abstract class HistoryDetailState {}

class HistoryInitial extends HistoryDetailState {}

class HistoryLoading extends HistoryDetailState {}

class HistoryLoaded extends HistoryDetailState {
  final HistoryDetailEntity data;

  HistoryLoaded(this.data);
}

class HistoryError extends HistoryDetailState {
  final String message;

  HistoryError(this.message);
}
