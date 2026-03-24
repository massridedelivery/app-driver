// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeApiService)
const homeApiServiceProvider = HomeApiServiceProvider._();

final class HomeApiServiceProvider
    extends $FunctionalProvider<HomeApiService, HomeApiService, HomeApiService>
    with $Provider<HomeApiService> {
  const HomeApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeApiServiceHash();

  @$internal
  @override
  $ProviderElement<HomeApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeApiService create(Ref ref) {
    return homeApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeApiService>(value),
    );
  }
}

String _$homeApiServiceHash() => r'09333b0497cc1e6b527244daf98ffe26b23d059c';
