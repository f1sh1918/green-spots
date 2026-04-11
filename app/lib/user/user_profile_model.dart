class UserProfile {
  final int id;
  final String name;
  final String? description;
  final String? gravatarUrl;
  final String? profileImageUrl;
  final int spotCount;
  final int commentCount;

  const UserProfile({
    required this.id,
    required this.name,
    this.description,
    this.gravatarUrl,
    this.profileImageUrl,
    required this.spotCount,
    required this.commentCount,
  });

  /// Custom image if set, otherwise Gravatar
  String? get effectiveAvatarUrl {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return profileImageUrl;
    }
    return (gravatarUrl != null && gravatarUrl!.isNotEmpty)
        ? gravatarUrl
        : null;
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required int spotCount,
    required int commentCount,
  }) {
    final avatarUrls = json['avatar_urls'] as Map<String, dynamic>?;
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      gravatarUrl: avatarUrls?['96'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      spotCount: spotCount,
      commentCount: commentCount,
    );
  }
}
