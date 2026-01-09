import 'dart:convert';

class User {
  final String role;

  User({
    required this.role,
  });

  // --------------------------------------------------------------
  // Factory constructor that parses a Map<String, dynamic>
  // --------------------------------------------------------------
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      role: json['roles'][0] ?? '',
    );
  }

  // --------------------------------------------------------------
  // Helper to decode a whole JSON list
  // --------------------------------------------------------------
  static User singleFromJson(String jsonStr) {
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      return User.fromJson(decoded);
    } catch (e) {
      return User(role: 'subscriber');
    }
  }
}
