import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/auth/services/auth.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/updates/update_info_dialog.dart';
import 'package:spots/updates/update_service.dart';
import 'package:spots/user/user_service.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:spots/utils/string_utils.dart';
import 'package:spots/utils/version_comparator.dart';
import 'package:spots/auth/widgets/registration_page.dart';
import 'package:spots/user/profile_dialog.dart';
import 'package:spots/user/profile_edit_page.dart';
import 'package:spots/widgets/AlertBox.dart';
import 'package:spots/widgets/outlined_button_spinner.dart';
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
  final UpdateService _updateService = UpdateService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userDisplayName;
  String? _userEmail;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _loginExpires;
  String _version = 'unbekannt';
  bool _isCheckingUpdates = false;
  String _userRole = 'N/A';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _getVersion();
    // _checkUserRole(context);
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
    final userRole = settingsProvider.userRole;

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
        _userRole = userRole ?? 'unbekannt';
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
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        context: context,
        userService: _userService,
      );

      if (result.success) {
        // Erfolgreich eingeloggt
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userDisplayName = result.userDisplayName;
            _userEmail = result.userEmail;
            _userRole = result.userRole ?? 'unbekannt';
            _usernameController.clear();
            _passwordController.clear();
            _loginExpires = _authService
                .loginExpirationDate()
                .toIso8601String();
          });
          showSnackBar(
            context,
            'Erfolgreich angemeldet als ${result.userDisplayName}!',
            Colors.green,
            Duration(seconds: 3),
          );
        }
      } else {
        // Login fehlgeschlagen
        if (mounted) {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Login fehlgeschlagen';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unerwarteter Fehler: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: _isLoading
                ? _showSpinner()
                : IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _isLoggedIn ? _buildLoggedInView() : _buildLoginForm(),
                        const Spacer(),
                        Consumer<SpotsProvider>(
                          builder: (context, spotsProvider, _) {
                            return Column(
                              children: [
                                if (spotsProvider.isOffline)
                                  _buildOfflineSection(context, spotsProvider),
                                const SizedBox(height: 8),
                                Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Version: $_version',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (!kIsWeb && !spotsProvider.isOffline)
                                          OutlinedButtonSpinner(
                                            isLoading: _isCheckingUpdates,
                                            onPressed: () =>
                                                _checkUpdate(context),
                                            buttonText: 'Nach Updates suchen',
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ),
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
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Nutzername',
              prefixIcon: const Icon(Icons.people, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              errorText: _errorMessage?.contains('Nutzername') == true
                  ? _errorMessage
                  : null,
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
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
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

          if (_errorMessage != null && !_errorMessage!.contains('Nutzername'))
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
          FilledButton.icon(
            onPressed: _isLoading ? null : _login,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.login),
            label: const Text('Anmelden'),
          ),
          const SizedBox(height: 8),

          // Register + Lost Password
          TextButton.icon(
            onPressed: _register,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Registrieren'),
          ),
          TextButton.icon(
            onPressed: _lostPassword,
            icon: const Icon(Icons.lock_reset_outlined),
            label: const Text('Passwort vergessen'),
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
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              final settings = Provider.of<SettingsModel>(
                context,
                listen: false,
              );
              final userId = int.tryParse(settings.userId ?? '');
              if (userId == null) return;
              showProfileDialog(context, userId: userId, token: settings.token);
            },
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
                          (_userDisplayName?.isNotEmpty == true
                              ? _userDisplayName!.substring(0, 1).toUpperCase()
                              : 'U'),
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
                              _loginExpires != null
                                  ? 'Gültig bis: $_loginExpires'
                                  : 'Gültig bis: unbekannt',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Rolle: ${_userRole.capitalize()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allowedRoles.contains(_userRole)) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ] else ...[
                        const Icon(Icons.info, color: Colors.orange, size: 24),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ), // Card

        const SizedBox(height: 24),

        if (!allowedRoles.contains(_userRole)) ...[
          AlertBox(
            message:
                'Dein Account muss noch von einem Admin freigeschaltet werden. Erst nach der Freischaltung kannst du Spots anlegen und editieren.',
          ),
          const SizedBox(height: 24),
        ],
        // Profil bearbeiten
        OutlinedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileEditPage())),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Profil bearbeiten'),
        ),
        const SizedBox(height: 8),

        // Logout Button
        FilledButton.icon(
          onPressed: () => _logout(context, false),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Abmelden'),
        ),
      ],
    );
  }

  Widget _buildOfflineSection(
    BuildContext context,
    SpotsProvider spotsProvider,
  ) {
    final queueCount = spotsProvider.queuedSpotsCount;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Offline-Modus aktiv',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            if (queueCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                queueCount == 1
                    ? '1 Spot wartet auf Übertragung.'
                    : '$queueCount Spots warten auf Übertragung.',
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Online-Modus wird automatisch aktiviert',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _register() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationPage()));
  }

  void _lostPassword() async {
    final Uri url = Uri.parse('$baseUrl/wp-login.php?action=lostpassword');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _checkUpdate(BuildContext context) async {
    setState(() {
      _isCheckingUpdates = true;
    });
    final updates = await _updateService.fetchUpdates();
    setState(() {
      _isCheckingUpdates = false;
    });
    if (VersionComparator.isHigher(
      currentVersion: _version,
      latestVersion: updates[0].title,
    )) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UpdateInfoDialog(updateInfo: updates[0]);
        },
      );
    } else {
      showSnackBar(context, 'Deine Version ist aktuell.', Colors.green);
    }
  }
}
