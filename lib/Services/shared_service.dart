import 'package:shared_preferences/shared_preferences.dart';

const String currentUserKey = 'CurrUser';

const String currentTestKey = 'CurrTest';

class SharedService {
  Future<bool> get currentUserInitialized async {
    final SharedPreferences prefs = await _prefs;
    return prefs.containsKey(currentUserKey);
  }

  Future<bool> setCurrentUser({required String id}) async {
    final SharedPreferences prefs = await _prefs;
    return await prefs.setString(currentUserKey, id);
  }

  Future<bool> setCurrentTest({required String name}) async {
    final SharedPreferences prefs = await _prefs;
    return await prefs.setString(currentTestKey, name);
  }

  Future<String?> getCurrentTest() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(currentTestKey);
  }

  Future<bool> quietSet({required String id}) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.setString(currentUserKey, id);
  }

  Future<String?> getCurrentUser() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(currentUserKey);
  }

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();
}
