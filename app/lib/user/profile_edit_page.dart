import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/user/user_profile_model.dart';
import 'package:spots/user/user_profile_service.dart';
import 'package:spots/utils/messenger_utils.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _service = UserProfileService();
  final _bioController = TextEditingController();

  UserProfile? _profile;
  bool _loadingProfile = true;
  bool _saving = false;
  XFile? _pendingImage;
  Uint8List? _pendingImageBytes;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final token = settings.token;
    final userId = int.tryParse(settings.userId ?? '');
    if (token == null || userId == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final profile = await _service.fetchProfile(userId, token: token);
      if (mounted) {
        setState(() {
          _profile = profile;
          _bioController.text = profile.description ?? '';
          _currentImageUrl = profile.effectiveAvatarUrl;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pendingImage = picked;
        _pendingImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final token = settings.token;
    if (token == null) return;

    setState(() => _saving = true);
    try {
      String? newImageUrl;
      if (_pendingImage != null) {
        newImageUrl = await _service.uploadProfileImage(_pendingImage!, token);
      }

      await _service.saveProfile(
        token: token,
        description: _bioController.text.trim(),
        profileImageUrl: newImageUrl,
      );

      if (mounted) {
        showSnackBar(context, 'Profil gespeichert', Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil bearbeiten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  tooltip: 'Speichern',
                ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: _pendingImageBytes != null
                              ? MemoryImage(_pendingImageBytes!)
                              : (_currentImageUrl != null
                                        ? NetworkImage(_currentImageUrl!)
                                        : null)
                                    as ImageProvider?,
                          child:
                              _pendingImage == null && _currentImageUrl == null
                              ? Text(
                                  _profile?.name.isNotEmpty == true
                                      ? _profile!.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Foto ändern',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.green),
                  ),
                  const SizedBox(height: 28),

                  // Name (read-only display)
                  if (_profile != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Name',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _profile!.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bio
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Kurzinfo',
                      hintText: 'Schreib etwas über dich…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 200,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),
            ),
    );
  }
}
