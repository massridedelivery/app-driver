import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';
import 'package:massdrive/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';

/// Serves [avatar] as the profile's avatar_url and counts the reads.
class _FakeProfiles implements ProfileRepository {
  String avatar = 'https://media.test/avatar/d/old.png';
  int reads = 0;

  @override
  Future<DriverProfileEntity> getProfile() async {
    reads++;
    return DriverProfileEntity(userId: 'd', fullName: 'Driver', avatarUrl: avatar);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {}
}

class _UnusedVehicles implements VehicleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Background the app and bring it back, one legal lifecycle step at a time.
void _backgroundAndReturn(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  late _FakeProfiles profiles;

  setUp(() {
    profiles = _FakeProfiles();
    getIt.registerSingleton<ProfileRepository>(profiles);
    getIt.registerSingleton<VehicleRepository>(_UnusedVehicles());
  });
  tearDown(() => getIt.reset());

  test('a document_status push is a profile change; other pushes are not', () {
    expect(
      isDocumentStatusPush({'type': 'document_status', 'doc_type': 'selfie', 'status': 'approved'}),
      isTrue,
    );
    expect(isDocumentStatusPush({'type': 'topup_approved'}), isFalse);
    expect(isDocumentStatusPush({}), isFalse);
  });

  // An admin approving a selfie gives the driver a new avatar_url. The app used
  // to keep showing the old photo until the driver logged in again.
  testWidgets('a document_status push re-reads the profile, without the loader', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(profileControllerProvider.notifier);
    await notifier.fetchProfile();

    final loading = <bool>[];
    container.listen(profileControllerProvider, (_, next) => loading.add(next.isLoading));
    profiles.avatar = 'https://media.test/avatar/d/new.png';
    ProfileUpdates.instance.notifyChanged();
    await tester.pump();

    final state = container.read(profileControllerProvider);
    expect(state.profile?.photoUrl, 'https://media.test/avatar/d/new.png');
    expect(loading, everyElement(isFalse));
  });

  testWidgets('coming back to the foreground re-reads the profile', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).fetchProfile();
    profiles.avatar = 'https://media.test/avatar/d/new.png';

    _backgroundAndReturn(tester);
    await tester.pump();

    expect(profiles.reads, 2);
    expect(
      container.read(profileControllerProvider).profile?.photoUrl,
      'https://media.test/avatar/d/new.png',
    );
  });

  testWidgets('nothing is read before a profile was ever loaded (logged out)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(profileControllerProvider);

    ProfileUpdates.instance.notifyChanged();
    _backgroundAndReturn(tester);
    await tester.pump();

    expect(profiles.reads, 0);
  });
}
