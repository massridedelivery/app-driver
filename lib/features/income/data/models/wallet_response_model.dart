import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/income/domain/entities/wallet_response.dart';

part 'wallet_response_model.g.dart';

@JsonSerializable(createFactory: true, fieldRename: FieldRename.snake)
class WalletResponseModel {
  final String cashBalance;
  final String creditBalance;

  const WalletResponseModel({
    required this.cashBalance,
    required this.creditBalance,
  });

  factory WalletResponseModel.fromJson(Map<String, dynamic> json) =>
      _$WalletResponseModelFromJson(json);

  WalletResponse toEntity() {
    return WalletResponse(
      cashBalance: cashBalance,
      creditBalance: creditBalance,
    );
  }
}
