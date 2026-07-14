import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';

part 'messenger_state.freezed.dart';

@freezed
sealed class MessengerState with _$MessengerState {
  const factory MessengerState({
    /// Pending offer awaiting accept/reject (pre-accept).
    MessengerOffer? currentOffer,

    /// The accepted order currently being delivered.
    MessengerOrder? activeOrder,
    @Default(false) bool isModalVisible,
    @Default(false) bool isSubmitting,
    @Default('') String errorMessage,
  }) = _MessengerState;
}
