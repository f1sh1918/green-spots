import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    if (_preferences != null) {
      // Already initialized
      return;
    }

    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> clearSettings() async {
    await _preferences?.clear();
    notifyListeners();
  }

  Future<void> clearUserData() async {
    await _preferences?.remove('token');
    await _preferences?.remove('refreshToken');
    await _preferences?.remove('user');
    await _preferences?.remove('email');
    await _preferences?.remove('lastLogin');
    await _preferences?.remove('userRole');
    await _preferences?.remove('userId');
    notifyListeners();
  }

  bool? _getBool(String key) {
    final obj = _preferences?.get(key);
    if (obj == null) {
      return null;
    } else if (obj is! bool) {
      log(
        'Preference key $key has wrong type: Expected bool, but got ${obj.runtimeType}. Returning fallback.',
        level: 1000,
      );
      return null;
    }
    return obj;
  }

  String? _getString(String key) {
    final obj = _preferences?.get(key);
    if (obj == null) {
      return null;
    } else if (obj is! String) {
      log(
        'Preference key $key has wrong type: Expected string, but got ${obj.runtimeType}. Returning fallback.',
        level: 1000,
      );
      return null;
    }
    return obj;
  }

  String hasSeenOnboardingKey = 'hasSeenOnboarding';
  bool get hasSeenOnboarding => _getBool(hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding() async {
    await _preferences?.setBool(hasSeenOnboardingKey, true);
  }

  String firstMapStartKey = 'firstMapStart';
  bool get firstMapStart => _getBool(firstMapStartKey) ?? true;

  Future<void> setFirstStart({required bool enabled}) async {
    bool? currentlyFirstMapStartEnabled = firstMapStart;
    await _preferences?.setBool(firstMapStartKey, enabled);
    _notifyChange(currentlyFirstMapStartEnabled, enabled);
  }

  String tokenKey = 'token';
  String? get token => _getString(tokenKey);

  Future<void> setToken({required String token}) async {
    String? currentToken = token;
    await _preferences?.setString(tokenKey, token);
    _notifyChange(currentToken, token);
  }

  String refreshTokenKey = 'refreshToken';
  String? get refreshToken => _getString(refreshTokenKey);

  Future<void> setRefreshToken({required String refreshToken}) async {
    String? currentRefreshToken = refreshToken;
    await _preferences?.setString(refreshTokenKey, refreshToken);
    _notifyChange(currentRefreshToken, refreshToken);
  }

  String userKey = 'user';
  String? get user => _getString(userKey);

  Future<void> setUser({required String user}) async {
    String? currentUser = user;
    await _preferences?.setString(userKey, user);
    _notifyChange(currentUser, user);
  }

  String userIdKey = 'userId';
  String? get userId => _getString(userIdKey);

  Future<void> setUserId({required String userId}) async {
    String? currentUserId = userId;
    await _preferences?.setString(userIdKey, userId);
    _notifyChange(currentUserId, userId);
  }

  String userRoleKey = 'userRole';
  String? get userRole => _getString(userRoleKey);

  Future<void> setUserRole({required String userRole}) async {
    final currentUserRole = this.userRole;
    await _preferences?.setString(userRoleKey, userRole);
    _notifyChange(currentUserRole, userRole);
  }

  String emailKey = 'email';
  String? get email => _getString(emailKey);

  Future<void> setEmail({required String email}) async {
    String? currentEmail = email;
    await _preferences?.setString(emailKey, email);
    _notifyChange(currentEmail, email);
  }

  String expireLoginKey = 'expireLogin';
  String? get expireLogin => _getString(expireLoginKey);

  Future<void> setExpireLogin({required String expireLogin}) async {
    String? currentLogin = expireLogin;
    await _preferences?.setString(expireLoginKey, expireLogin);
    _notifyChange(currentLogin, expireLogin);
  }

  @override
  String toString() {
    return 'SettingsModel{firstStart: $firstMapStart}';
  }

  // only notify if value has changed
  void _notifyChange<T>(T oldValue, T newValue) {
    if (oldValue != newValue) {
      notifyListeners();
    }
  }
}
