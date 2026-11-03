import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/profile/data/sources/profile_photo_uploader.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';
import 'package:massdrive/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';

/// Answers every request with [respond] and remembers what was sent.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Object? Function(RequestOptions) respond;

  _RecordingAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _key = 'avatar/drv-1/new.jpg';

ProfilePhotoUploader _uploader(
  _RecordingAdapter api,
  _RecordingAdapter storage,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = api;
  return ProfilePhotoUploader(dio)
    ..newStorageDio = () => Dio()..httpClientAdapter = storage;
}

Object? _media(RequestOptions o, {bool confirmed = true}) {
  if (o.path.contains('upload-url')) {
    return {'upload_url': 'https://storage.test/presigned/new.jpg', 'file_key': _key};
  }
  if (o.path.contains('media/confirm')) return {'confirmed': confirmed};
  return {};
}

class _FakeProfiles implements ProfileRepository {
  String avatar = 'https://media.test/avatar/drv-1/old.jpg';
  final List<Map<String, dynamic>> updates = [];

  @override
  Future<DriverProfileEntity> getProfile() async =>
      DriverProfileEntity(userId: 'drv-1', fullName: 'Driver', avatarUrl: avatar);

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    updates.add(data);
    avatar = 'https://media.test/${data['avatar_url']}';
  }
}

class _UnusedVehicles implements VehicleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  // ProfileController listens to the app lifecycle.
  TestWidgetsFlutterBinding.ensureInitialized();
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

  // "เปลี่ยนรูปโปรไฟล์" is not the sign-up selfie: it uploads to the public
  // avatar category and never touches /api/driver/documents.
  test('the photo goes up as an avatar and returns its file_key', () async {
    final api = _RecordingAdapter(_media);
    final storage = _RecordingAdapter((_) => {});

    final key = await _uploader(api, storage).upload(jpeg);

    expect(key, _key);
    final mint = api.requests.first;
    expect(mint.path, '/api/media/upload-url');
    expect(mint.queryParameters, {'category': 'avatar', 'content_type': 'image/jpeg'});
    expect(storage.requests.single.method, 'PUT');
    expect(storage.requests.single.contentType, 'image/jpeg');
    expect(api.requests.last.path, '/api/media/confirm');
    expect(api.requests.last.data, {'file_key': _key});
    expect(api.requests.where((r) => r.path.contains('documents')), isEmpty);
  });

  test('an unconfirmed upload is a failure, not a photo', () async {
    final api = _RecordingAdapter((o) => _media(o, confirmed: false));

    expect(
      _uploader(api, _RecordingAdapter((_) => {})).upload(jpeg),
      throwsA(isA<Exception>()),
    );
  });

  group('ProfileController.changePhoto', () {
    late _FakeProfiles profiles;

    setUp(() {
      profiles = _FakeProfiles();
      getIt.registerSingleton<ProfileRepository>(profiles);
      getIt.registerSingleton<VehicleRepository>(_UnusedVehicles());
    });
    tearDown(() => getIt.reset());

    test('sets avatar_url to the bare file_key and shows the new photo', () async {
      getIt.registerSingleton<ProfilePhotoUploader>(
        _uploader(_RecordingAdapter(_media), _RecordingAdapter((_) => {})),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(profileControllerProvider.notifier);
      await notifier.fetchProfile();

      final error = await notifier.changePhoto(jpeg);

      expect(error, isNull);
      expect(profiles.updates, [
        {'avatar_url': _key},
      ]);
      final state = container.read(profileControllerProvider);
      expect(state.profile?.photoUrl, 'https://media.test/$_key');
      expect(state.isUpdating, isFalse);
    });

    test('a failed upload keeps the old photo and says why', () async {
      getIt.registerSingleton<ProfilePhotoUploader>(
        _uploader(
          _RecordingAdapter((o) => _media(o, confirmed: false)),
          _RecordingAdapter((_) => {}),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(profileControllerProvider.notifier);
      await notifier.fetchProfile();

      final error = await notifier.changePhoto(jpeg);

      expect(error, 'อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
      expect(profiles.updates, isEmpty);
      expect(
        container.read(profileControllerProvider).profile?.photoUrl,
        'https://media.test/avatar/drv-1/old.jpg',
      );
    });
  });
}
