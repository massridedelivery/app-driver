import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:massdrive/features/history_detail/domain/usecases/get_history_detail_usecase.dart';
import 'package:massdrive/features/history_detail/presentation/states/history_detail_event.dart';
import 'package:massdrive/features/history_detail/presentation/states/history_detail_state.dart';

class HistoryDetailBloc extends Bloc<HistoryDetailEvent, HistoryDetailState> {
  final GetHistoryDetailUseCase useCase;

  HistoryDetailBloc(this.useCase) : super(HistoryInitial()) {
    on<LoadHistoryDetail>((event, emit) async {
      emit(HistoryLoading());
      try {
        final result = await useCase(event.id);
        emit(HistoryLoaded(result));
      } catch (e) {
        emit(HistoryError(e.toString()));
      }
    });
  }
}
