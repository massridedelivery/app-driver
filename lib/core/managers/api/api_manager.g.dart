// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiManager)
const apiManagerProvider = ApiManagerProvider._();

final class ApiManagerProvider
    extends $FunctionalProvider<ApiManager, ApiManager, ApiManager>
    with $Provider<ApiManager> {
  const ApiManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiManagerHash();

  @$internal
  @override
  $ProviderElement<ApiManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiManager create(Ref ref) {
    return apiManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiManager>(value),
    );
  }
}

String _$apiManagerHash() => r'6d2ab65768d172032eda518e788d266015322efa';
