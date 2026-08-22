// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentApiService)
const paymentApiServiceProvider = PaymentApiServiceProvider._();

final class PaymentApiServiceProvider
    extends
        $FunctionalProvider<
          PaymentApiService,
          PaymentApiService,
          PaymentApiService
        >
    with $Provider<PaymentApiService> {
  const PaymentApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentApiServiceHash();

  @$internal
  @override
  $ProviderElement<PaymentApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentApiService create(Ref ref) {
    return paymentApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentApiService>(value),
    );
  }
}

String _$paymentApiServiceHash() => r'fda682b33e2515aa0c730be75ea11055d5985027';
