import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const String _keyToken = 'sportsync_jwt_token';
  static const String _keyUserJson = 'sportsync_user_json';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserJson(String jsonStr) async {
    await _storage.write(key: _keyUserJson, value: jsonStr);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
