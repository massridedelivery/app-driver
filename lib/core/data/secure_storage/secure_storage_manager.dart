import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';

class SecureStorageManager {
  static final SecureStorageManager _instance =
      SecureStorageManager._internal();

  factory SecureStorageManager() => _instance;

  late final FlutterSecureStorage _storage;

  SecureStorageManager._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  Future<bool> isContain(SecureStorageKey key) async {
    return await _storage.containsKey(key: key.name);
  }

  Future<String?> read(SecureStorageKey key) async {
    return await _storage.read(key: key.name);
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  Future<void> write(SecureStorageKey key, String? value) async {
    return await _storage.write(key: key.name, value: value);
  }

  Future<void> delete(SecureStorageKey key) async {
    return await _storage.delete(key: key.name);
  }

  Future<void> deleteAll() async {
    return await _storage.deleteAll();
  }
}
