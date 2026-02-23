import 'package:massdrive/features/home/domain/entities/home_entity.dart';

class HomeScreenState {
  final bool isLoading;
  final HomeEntity? data;

  const HomeScreenState({this.isLoading = true, this.data});

  HomeScreenState copyWith({bool? isLoading, HomeEntity? data}) {
    return HomeScreenState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
    );
  }
}
