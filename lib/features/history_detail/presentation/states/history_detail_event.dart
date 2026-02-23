abstract class HistoryDetailEvent {}

class LoadHistoryDetail extends HistoryDetailEvent {
  final String id;

  LoadHistoryDetail(this.id);
}
