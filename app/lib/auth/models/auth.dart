class AuthResult {
  final bool success;
  final String token;
  final String userNiceName;
  final String userDisplayName;
  final String userEmail;
  final String? errorMessage;
  final int? statusCode;

  AuthResult({
    required this.success,
    required this.token,
    required this.userNiceName,
    required this.userDisplayName,
    required this.userEmail,
    this.errorMessage,
    this.statusCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResult(
      success: true,
      token: data['token'] ?? '',
      userEmail: data['email'] ?? '',
      userNiceName: data['nicename'] ?? '',
      userDisplayName: data['displayName'] ?? '',
    );
  }

  factory AuthResult.error(String message, int statusCode) {
    return AuthResult(
      success: false,
      token: '',
      userEmail: '',
      userNiceName: '',
      userDisplayName: '',
      errorMessage: message,
      statusCode: statusCode,
    );
  }
}

class UserInfo {
  final String displayName;
  final String userEmail;
  final DateTime? loginTime;

  UserInfo({
    required this.displayName,
    required this.userEmail,
    this.loginTime,
  });
}
