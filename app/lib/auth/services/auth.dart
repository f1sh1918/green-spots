import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:spots/auth/models/auth.dart';
import 'package:spots/constants/api.dart';

import '../models/settings.dart';

class AuthService {
  static const String validateEndpoint = '/wp-json/jwt-auth/v1/token/validate';
  String? _refreshTokenCookie;

// TODO Auto-Login with refresh token on startup, remove token validation, save refresh cookie expiration instead of LoginExpires
  Future<AuthResult> login({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$tokenEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        _refreshTokenCookie = _extractRefreshTokenNew(response.headers);
        if (_refreshTokenCookie != null && context.mounted) {
          final settingsModel = Provider.of<SettingsModel>(context, listen: false);
          _saveRefreshToken(_refreshTokenCookie!, settingsModel);
          print('refresh:$_refreshTokenCookie');
        }
        final Map<String, dynamic> data = json.decode(response.body);
        final authResult = AuthResult.fromJson(data);
        print('Token:${authResult.token}');

        if (context.mounted) {
          final settingsModel = Provider.of<SettingsModel>(context, listen: false);
          await _saveToken(authResult.token, settingsModel);
          await _saveUserInfo(authResult, settingsModel);
        }

        return authResult;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return AuthResult.error(
          errorData['message'] ?? 'Login fehlgeschlagen',
          response.statusCode,
        );
      }
    } catch (e) {
      return AuthResult.error('Netzwerkfehler: $e', 0);
    }
  }

  Future<bool> validateToken(SettingsModel settings, String? token) async {
    try {
      final authToken = token ?? settings.token;
      if (authToken == null) return false;

      final url = Uri.parse('$baseUrl$validateEndpoint');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    final settingsModel = Provider.of<SettingsModel>(context, listen: false);
    settingsModel.clearSettings();
  }

  bool isTokenExpired(String? expireDateString) {
    print(expireDateString);
    if (expireDateString == null) return false;

    try {
      DateTime expireDate = DateTime.parse(expireDateString);
      // Add some threshold
      return DateTime.now().isAfter(expireDate.subtract(const Duration(hours: 12)));
    } catch (e) {
      print('Fehler beim Parsen des Datums: $e');
      return true; // Bei Fehler als expired behandeln
    }
  }

  // Private Methoden
  Future<void> _saveToken(String token, SettingsModel settingsModel) async {
    await settingsModel.setToken(token: token);
    await settingsModel.setExpireLogin(expireLogin: DateTime.now().add(const Duration(days: 7)).toIso8601String());
  }

  // Private Methoden
  Future<void> _saveRefreshToken(String token, SettingsModel settingsModel) async {
    await settingsModel.setRefreshToken(refreshToken: token);
  }

  Future<void> _saveUserInfo(AuthResult authResult, SettingsModel settingsModel) async {
    await settingsModel.setUser(user: authResult.userDisplayName);
    await settingsModel.setEmail(email: authResult.userEmail);
  }

  String? _extractRefreshTokenNew(Map<String, String> headers) {
    final setCookie = headers['set-cookie'];
    if (setCookie == null) return null;

    // RegExp für präzise Extraktion des refresh_token Wertes
    final refreshTokenRegex = RegExp(r'refresh_token=([^;]+)');
    final match = refreshTokenRegex.firstMatch(setCookie);

    return match?.group(1); // Gibt nur den Wert zurück, nicht den ganzen Cookie
  }
}
