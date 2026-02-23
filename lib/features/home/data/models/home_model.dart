import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/home/domain/entities/home_entity.dart';

part 'home_model.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class HomeModel {
  final int? id;
  final String? title;

  const HomeModel({this.id, this.title});

  factory HomeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeModelFromJson(json);
}

extension HomeModelToHomeEntityMapper on HomeModel {
  HomeEntity toEntity() {
    return HomeEntity(id: id ?? 0, title: title ?? '');
  }
}
