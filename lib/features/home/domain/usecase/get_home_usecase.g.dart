// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_home_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getHomeUseCase)
const getHomeUseCaseProvider = GetHomeUseCaseProvider._();

final class GetHomeUseCaseProvider
    extends $FunctionalProvider<GetHomeUseCase, GetHomeUseCase, GetHomeUseCase>
    with $Provider<GetHomeUseCase> {
  const GetHomeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getHomeUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getHomeUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetHomeUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetHomeUseCase create(Ref ref) {
    return getHomeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetHomeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetHomeUseCase>(value),
    );
  }
}

String _$getHomeUseCaseHash() => r'1c677392bd0082af122ad67ab19541a411abc220';
