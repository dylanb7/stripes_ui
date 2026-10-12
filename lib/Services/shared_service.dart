import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';

const String currentUserKey = 'CurrUser';

const String currentTestKey = 'CurrTest';
const String detailLayoutPreferenceKey = 'detail_layout_preference';

class SharedService {
  String _termsKey(String accountId) =>
      'terms_acceptance:${jsonEncode(accountId)}';

  Future<TermsAcceptance?> getTermsAcceptance(String accountId) async {
    final prefs = await _prefs;
    try {
      final stored = prefs.getString(_termsKey(accountId));
      if (stored == null) return null;
      return TermsAcceptance.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> setTermsAcceptance(
    String accountId,
    TermsAcceptance acceptance,
  ) async {
    final prefs = await _prefs;
    final saved = await prefs.setString(
      _termsKey(accountId),
      jsonEncode(acceptance.toJson()),
    );
    if (!saved) throw StateError('Unable to save terms acceptance');
  }

  String _conditionKey(String accountId, String profileId) =>
      'profile_condition:${jsonEncode([accountId, profileId])}';

  Future<ProfileCondition?> getProfileCondition({
    required String accountId,
    required String profileId,
  }) async {
    final prefs = await _prefs;
    final stored = prefs.getString(_conditionKey(accountId, profileId));
    return stored == null
        ? null
        : ProfileCondition.fromJson(jsonDecode(stored) as Map<String, dynamic>);
  }

  Future<void> setProfileCondition({
    required String accountId,
    required String profileId,
    required ProfileCondition? condition,
  }) async {
    final prefs = await _prefs;
    final key = _conditionKey(accountId, profileId);
    if (condition == null && !prefs.containsKey(key)) return;
    final saved = condition == null
        ? await prefs.remove(key)
        : await prefs.setString(key, jsonEncode(condition.toJson()));
    if (!saved) throw StateError('Unable to save profile condition');
  }

  Future<AppDisplaySettings> getDisplaySettings() async {
    final prefs = await _prefs;
    return AppDisplaySettings(
      detailLayout: prefs.getString(detailLayoutPreferenceKey) == 'stacked'
          ? DetailLayoutPreference.stacked
          : DetailLayoutPreference.automatic,
    );
  }

  Future<void> setDisplaySettings(AppDisplaySettings settings) async {
    final prefs = await _prefs;
    final saved = await prefs.setString(
      detailLayoutPreferenceKey,
      settings.detailLayout.name,
    );
    if (!saved) throw StateError('Unable to save display settings');
  }

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
