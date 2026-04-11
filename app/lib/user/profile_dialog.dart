import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/user/community_provider.dart';
import 'package:spots/user/community_service.dart';
import 'package:spots/user/user_avatar.dart';
import 'package:spots/user/user_profile_model.dart';
import 'package:spots/user/user_profile_service.dart';

/// Shows a modal profile card for [userId].
/// Uses the [CommunityProvider] cache when available — no network request needed.
Future<void> showProfileDialog(
  BuildContext context, {
  required int userId,
  required String? token,
  VoidCallback? onShowOnMap,
}) async {
  // Check cache first
  CommunityProvider? communityProvider;
  try {
    communityProvider = Provider.of<CommunityProvider>(context, listen: false);
  } catch (_) {}

  final cached = communityProvider?.getMember(userId);

  showDialog(
    context: context,
    builder: (_) => _ProfileDialog(
      userId: userId,
      token: token,
      onShowOnMap: onShowOnMap,
      cached: cached,
    ),
  );
}

UserProfile _profileFromEntry(RankingEntry e) => UserProfile(
  id: e.userId,
  name: e.name,
  description: e.description,
  gravatarUrl: e.avatarUrl,
  profileImageUrl: null,
  spotCount: e.spotCount,
  commentCount: e.commentCount,
);

class _ProfileDialog extends StatefulWidget {
  final int userId;
  final String? token;
  final VoidCallback? onShowOnMap;
  final RankingEntry? cached;

  const _ProfileDialog({
    required this.userId,
    required this.token,
    this.onShowOnMap,
    this.cached,
  });

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _service = UserProfileService();
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.cached != null) {
      _profile = _profileFromEntry(widget.cached!);
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final profile = await _service.fetchProfile(
        widget.userId,
        token: widget.token,
      );
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Profil konnte nicht geladen werden.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            : _ProfileContent(
                profile: _profile!,
                onShowOnMap: widget.onShowOnMap != null
                    ? () {
                        Navigator.of(context).pop();
                        widget.onShowOnMap!();
                      }
                    : null,
              ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onShowOnMap;

  const _ProfileContent({required this.profile, this.onShowOnMap});

  @override
  Widget build(BuildContext context) {
    final hasBio =
        profile.description != null && profile.description!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(imageUrl: profile.effectiveAvatarUrl, radius: 40),
        const SizedBox(height: 12),

        Text(
          profile.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.park_outlined, size: 16, color: Colors.green[600]),
            const SizedBox(width: 4),
            Text(
              '${profile.spotCount} ${profile.spotCount == 1 ? 'Spot' : 'Spots'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: Colors.blueGrey[400],
            ),
            const SizedBox(width: 4),
            Text(
              '${profile.commentCount} ${profile.commentCount == 1 ? 'Kommentar' : 'Kommentare'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blueGrey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        if (hasBio) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            profile.description!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            if (onShowOnMap != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShowOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Auf Karte'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
