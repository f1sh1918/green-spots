import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';

class RegistrationResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;

  const RegistrationResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });
}

class RegistrationService {
  Future<RegistrationResult> register({
    required String username,
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/wp-login.php?action=register');
      final client = http.Client();

      final request = http.Request('POST', url)
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
        ..body =
            'user_login=${Uri.encodeComponent(username)}'
            '&user_email=${Uri.encodeComponent(email)}';

      final streamed = await client.send(request);
      final body = await streamed.stream.bytesToString();
      client.close();

      // WordPress redirects to ?checkemail=registered on success
      if (streamed.statusCode == 302) {
        final location = streamed.headers['location'] ?? '';
        if (location.contains('checkemail=registered')) {
          return const RegistrationResult(success: true);
        }
      }

      return _parseError(body);
    } catch (e) {
      return RegistrationResult(
        success: false,
        errorMessage: 'Netzwerkfehler. Bitte überprüfe deine Verbindung.',
      );
    }
  }

  RegistrationResult _parseError(String html) {
    // Extract text from WordPress's #login_error div
    final divRegex = RegExp(r'id="login_error"[^>]*>(.*?)</div>', dotAll: true);
    final match = divRegex.firstMatch(html);
    final rawMessage = match?.group(1) ?? '';

    // Strip HTML tags, remove "Fehler:" / "Error:" prefix, clean whitespace
    final message = rawMessage
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(
          RegExp(r'^\s*(Fehler|Error)\s*:\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (message.isNotEmpty) {
      if (message.contains('Benutzername ist bereits registriert') ||
          message.contains('username already exists')) {
        return const RegistrationResult(
          success: false,
          errorCode: 'existing_user_login',
          errorMessage: 'Dieser Benutzername ist bereits registriert.',
        );
      }
      if (message.contains('E-Mail-Adresse wird bereits verwendet') ||
          message.contains('E-Mail-Adresse ist bereits') ||
          message.contains('email address is already used')) {
        return const RegistrationResult(
          success: false,
          errorCode: 'existing_user_email',
          errorMessage: 'Diese E-Mail-Adresse ist bereits registriert.',
        );
      }
      return RegistrationResult(success: false, errorMessage: message);
    }

    return const RegistrationResult(
      success: false,
      errorMessage: 'Registrierung fehlgeschlagen. Bitte versuche es erneut.',
    );
  }
}
