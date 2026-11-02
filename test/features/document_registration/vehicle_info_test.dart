import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/constants/thai_provinces.dart';
import 'package:massdrive/features/document_registration/data/repositories/document_registration_repository_impl.dart';
import 'package:massdrive/features/document_registration/data/sources/document_registration_api.dart';
import 'package:massdrive/features/document_registration/domain/models/vehicle_info.dart';
import 'package:massdrive/features/profile/data/sources/profile_api_service.dart';

class _FakeProfileApi implements ProfileApiService {
  final sent = <Map<String, dynamic>>[];

  @override
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    sent.add(data);
    return Response(requestOptions: RequestOptions(), data: const {});
  }

  @override
  Future<Response<Map<String, dynamic>>> getProfile() =>
      throw UnimplementedError();
}

class _UnusedDocsApi implements DocumentRegistrationApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

VehicleInfo _info({
  String plate = '1กข 1234',
  String province = 'กรุงเทพมหานคร',
  String color = 'ดำ',
}) => VehicleInfo(
  vehicleType: 'motorcycle',
  model: 'Honda Wave 110i',
  year: 2020,
  licensePlate: plate,
  province: province,
  color: color,
);

void main() {
  group('VehicleInfo', () {
    test('carries province and colour through copyWith and toMap/fromMap', () {
      final info = _info();
      expect(info.province, 'กรุงเทพมหานคร');
      expect(info.color, 'ดำ');

      final moved = info.copyWith(province: 'เชียงใหม่', color: 'แดง');
      expect(moved.province, 'เชียงใหม่');
      expect(moved.color, 'แดง');
      expect(moved.licensePlate, '1กข 1234');

      final back = VehicleInfo.fromMap(info.toMap());
      expect(back.province, info.province);
      expect(back.color, info.color);
      expect(back.model, info.model);
      expect(back.year, info.year);
    });

    test('is complete only with plate, province and colour', () {
      expect(_info().isComplete, isTrue);
      expect(_info(province: '').isComplete, isFalse);
      expect(_info(color: ' ').isComplete, isFalse);
      expect(_info(plate: '').isComplete, isFalse);
    });

    test('changesFrom sends only edited fields, never ""', () {
      final saved = _info();
      expect(saved.changesFrom(saved), isEmpty);
      expect(saved.copyWith(color: 'ขาว').changesFrom(saved), {
        'vehicle_color': 'ขาว',
      });
      expect(saved.copyWith(province: '').changesFrom(saved), isEmpty);
      // A driver with no vehicle yet: everything they filled in.
      expect(saved.changesFrom(null).keys, hasLength(5));
    });
  });

  group('isVehicleStepComplete', () {
    test('false without a province, even with a plate and the book', () {
      expect(
        isVehicleStepComplete(
          saved: _info(province: ''),
          registrationBookUploaded: true,
        ),
        isFalse,
      );
    });

    test('false without a colour, the book, or any vehicle', () {
      expect(
        isVehicleStepComplete(
          saved: _info(color: ''),
          registrationBookUploaded: true,
        ),
        isFalse,
      );
      expect(
        isVehicleStepComplete(saved: _info(), registrationBookUploaded: false),
        isFalse,
      );
      expect(
        isVehicleStepComplete(saved: null, registrationBookUploaded: true),
        isFalse,
      );
    });

    test('true with plate, province, colour and the book', () {
      expect(
        isVehicleStepComplete(saved: _info(), registrationBookUploaded: true),
        isTrue,
      );
    });
  });

  test('submitVehicleDetails sends all five keys', () async {
    final profileApi = _FakeProfileApi();
    final repo = DocumentRegistrationRepositoryImpl(
      _UnusedDocsApi(),
      profileApi,
    );
    await repo.submitVehicleDetails(_info());
    expect(profileApi.sent.single, {
      'vehicle_plate': '1กข 1234',
      'vehicle_province': 'กรุงเทพมหานคร',
      'vehicle_color': 'ดำ',
      'vehicle_model': 'Honda Wave 110i',
      'vehicle_year': 2020,
    });
  });

  group('plate helpers', () {
    test('normalizePlate trims and collapses spaces', () {
      expect(normalizePlate('  1กข   1234 '), '1กข 1234');
    });

    test('plateWithProvince', () {
      expect(
        plateWithProvince('1กข 1234', 'กรุงเทพมหานคร'),
        '1กข 1234 กรุงเทพมหานคร',
      );
      expect(plateWithProvince('1กข 1234', ''), '1กข 1234');
      expect(plateWithProvince('1กข 1234', null), '1กข 1234');
      expect(plateWithProvince('', 'กรุงเทพมหานคร'), '');
    });
  });

  group('kThaiProvinces', () {
    test('77 unique full names', () {
      expect(kThaiProvinces, hasLength(77));
      expect(kThaiProvinces.toSet(), hasLength(77));
      expect(kThaiProvinces.first, 'กรุงเทพมหานคร');
      expect(kThaiProvinces, isNot(contains('กรุงเทพฯ')));
    });

    test('search filters as the driver types', () {
      expect(searchThaiProvinces('เชียง'), ['เชียงราย', 'เชียงใหม่']);
      expect(searchThaiProvinces(''), hasLength(77));
      expect(searchThaiProvinces('xyz'), isEmpty);
    });
  });
}
