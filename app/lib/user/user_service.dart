import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import 'package:spots/user/user_model.dart';
import 'package:spots/utils/messenger_utils.dart';

class UserService {
  Future<User> getUserRole({
    required String userId,
    required BuildContext context,
    String? token,
  }) async {
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
    } else {
      showSnackBar(
        context,
        'Dein Account ist noch nicht freigeschaltet.',
        Colors.red,
      );
      return User(role: 'subscriber');
    }
  }
}
