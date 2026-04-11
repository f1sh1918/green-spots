import 'package:flutter/material.dart';
import 'package:spots/auth/services/registration_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _service = RegistrationService();

  bool _isLoading = false;
  String? _usernameError;
  String? _emailError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _service.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 10),
          content: Text(
            'Deine Registrierung war erfolgreich! Bitte prüfe deinen E-Mail-Eingang.',
          ),
        ),
      );
    } else {
      final errorCode = result.errorCode ?? '';
      if (errorCode == 'existing_user_login') {
        setState(() => _usernameError = result.errorMessage);
        _formKey.currentState!.validate();
      } else if (errorCode == 'existing_user_email') {
        setState(() => _emailError = result.errorMessage);
        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text(
              result.errorMessage ?? 'Fehler bei der Registrierung.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Registrieren'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: Theme.of(context).inputDecorationTheme
                  .copyWith(
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Konto erstellen',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nach der Registrierung wird dein Konto durch einen Admin freigeschaltet. '
                    'Du erhältst per E-Mail einen Link zum Festlegen deines Passworts.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                      errorMaxLines: 3,
                    ),
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                    validator: (v) {
                      if (_usernameError != null) return _usernameError;
                      if (v == null || v.trim().isEmpty) {
                        return 'Benutzername ist erforderlich.';
                      }
                      if (v.trim().length < 3) {
                        return 'Mindestens 3 Zeichen erforderlich.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      errorMaxLines: 3,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (_emailError != null) return _emailError;
                      if (v == null || v.trim().isEmpty) {
                        return 'E-Mail ist erforderlich.';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Bitte eine gültige E-Mail-Adresse eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.person_add_outlined),
                    label: const Text('Registrieren'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
