import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

DriverProfileEntity _profile(Map<String, dynamic> extra) =>
    DriverProfileEntity.fromJson({
      'user_id': 'u1',
      'full_name': 'Test Driver',
      ...extra,
    });

void main() {
  group('DriverProfileEntity.photoUrl', () {
    test('reads avatar_url from the profile payload', () {
      final p = _profile({
        'avatar_url': 'https://cdn.example.com/avatar/u1/a.jpg',
      });
      expect(p.avatarUrl, 'https://cdn.example.com/avatar/u1/a.jpg');
      expect(p.photoUrl, 'https://cdn.example.com/avatar/u1/a.jpg');
    });

    test('falls back to a profile_photo document', () {
      final p = _profile({
        'documents': [
          {
            'type': 'id_card',
            'status': 'approved',
            'media_url': 'https://x/id.jpg',
          },
          {
            'type': 'profile_photo',
            'status': 'approved',
            'media_url': 'https://x/me.jpg',
          },
        ],
      });
      expect(p.photoUrl, 'https://x/me.jpg');
    });

    test('prefers avatar_url over the document', () {
      final p = _profile({
        'avatar_url': 'https://x/new.jpg',
        'documents': [
          {
            'type': 'profile_photo',
            'status': 'approved',
            'media_url': 'https://x/old.jpg',
          },
        ],
      });
      expect(p.photoUrl, 'https://x/new.jpg');
    });

    test('null when there is no photo, or avatar_url is a bare file key', () {
      expect(_profile({}).photoUrl, isNull);
      expect(_profile({'avatar_url': ''}).photoUrl, isNull);
      expect(_profile({'avatar_url': 'avatar/u1/a.jpg'}).photoUrl, isNull);
    });
  });
}
