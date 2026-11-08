import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();
  static const storage = FlutterSecureStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async =>
      (await storage.read(key: 'daryeel.session')) != null;
  @override
  Future<String?> accessToken() => storage.read(key: 'daryeel.session');
  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: 'daryeel.session', value: persistSessionString);
  @override
  Future<void> removePersistedSession() =>
      storage.delete(key: 'daryeel.session');
}
