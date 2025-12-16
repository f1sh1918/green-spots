import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/auth/services/auth.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userDisplayName;
  String? _userEmail;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _loginExpires;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final settingsProvider = Provider.of<SettingsModel>(context, listen: false);
    final token = settingsProvider.token;
    final userName = settingsProvider.user;
    final userEmail = settingsProvider.email;
    final loginExpires = settingsProvider.expireLogin;

    setState(() {
      _isLoading = true;
    });

    if (token != null) {
      setState(() {
        _isLoggedIn = true;
        _userDisplayName = userName ?? 'Unbekannt';
        _userEmail = userEmail ?? 'Keine Mailadresse';
        _isLoading = false;
        _loginExpires = loginExpires;
      });
    } else {
      if (mounted) {
        _logout(context, false);
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
          username: _usernameController.text.trim(), password: _passwordController.text, context: context);

      if (result.success) {
        // Erfolgreich eingeloggt
        setState(() {
          _isLoggedIn = true;
          _userDisplayName = result.userDisplayName;
          _usernameController.clear();
          _passwordController.clear();
          _loginExpires = _authService.loginExpirationDate().toIso8601String();
        });

        if (mounted) {
          showSnackBar(
              context, 'Erfolgreich angemeldet als ${result.userDisplayName}!', Colors.green, Duration(seconds: 3));
        }
      } else {
        // Login fehlgeschlagen
        setState(() {
          _errorMessage = result.errorMessage ?? 'Login fehlgeschlagen';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unerwarteter Fehler: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context, bool showSnackbar) async {
    await _authService.logout(context);
    setState(() {
      _isLoggedIn = false;
      _userDisplayName = null;
      _userEmail = null;
      _errorMessage = null;
      _isLoading = false;
    });

    if (mounted && showSnackbar) {
      showSnackBar(context, 'Erfolgreich abgemeldet', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? _showSpinner()
            : _isLoggedIn
                ? _buildLoggedInView()
                : _buildLoginForm(),
      ),
    );
  }

  Widget _showSpinner() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Anmeldung',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Melden Sie sich an, um Spots zu erstellen und zu verwalten.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.people, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              errorText: _errorMessage?.contains('Username') == true ? _errorMessage : null,
            ),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihren Nutzername ein';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Passwort',
              prefixIcon: const Icon(Icons.lock, color: Colors.green),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihr Passwort ein';
              }
              if (value.length < 6) {
                return 'Passwort muss mindestens 6 Zeichen haben';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null && !_errorMessage!.contains('Username'))
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Login Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Anmelden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          // Register
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _register,
              child: const Text(
                'Registrieren',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Angemeldet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),

        // Benutzer Info Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        (_userDisplayName?.isNotEmpty == true ? _userDisplayName!.substring(0, 1).toUpperCase() : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userDisplayName ?? 'Unbekannt',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _userEmail ?? 'Keine Mailadresse',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _loginExpires != null ? 'Expires: $_loginExpires' : 'Expires: N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _logout(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Abmelden',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _register() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-login.php?action=register',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
