import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import 'package:spots/user/user_model.dart';
import 'package:spots/utils/messenger_utils.dart';

class UserService {
  /// Fetches the user role from the API.
  /// When [silent] is true, no snackbar is shown and null is returned on
  /// non-200 responses so the caller can keep the existing role unchanged.
  Future<User?> getUserRole({
    required String userId,
    required BuildContext context,
    String? token,
    bool silent = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$userEndpoint/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return User.singleFromJson(response.body);
      }
      if (!silent && context.mounted) {
        showSnackBar(
          context,
          'Dein Account ist noch nicht freigeschaltet.',
          Colors.red,
        );
      }
      // Empty role signals "server responded but user not found / access denied"
      return silent ? User(role: '') : User(role: 'subscriber');
    } catch (_) {
      // Network / socket error — return null so the caller keeps the existing role
      return null;
    }
  }
}
