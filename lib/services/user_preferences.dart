import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  UserPreferences._();
  static final instance = UserPreferences._();

  static const _keyName = 'user_name';
  static const _keyOnboarded = 'onboarding_done';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isOnboardingDone => _prefs.getBool(_keyOnboarded) ?? false;
  String get userName => _prefs.getString(_keyName) ?? '';

  Future<void> completeOnboarding({
    required String name,
  }) async {
    await _prefs.setString(_keyName, name);
    await _prefs.setBool(_keyOnboarded, true);
  }

  Future<void> updateUserName(String name) async {
    await _prefs.setString(_keyName, name);
  }
}
