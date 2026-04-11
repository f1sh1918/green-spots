import 'package:flutter/material.dart';

/// Displays a user avatar with graceful fallback:
/// 1. [imageUrl] (custom profile image or Gravatar) via network
/// 2. If load fails or no URL: person icon
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const UserAvatar({super.key, this.imageUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green.shade100,
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Icon(Icons.person, size: radius * 1.1, color: Colors.green.shade600);
  }
}
