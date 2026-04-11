import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';

class RankingEntry {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? description;
  final int spotCount;
  final int commentCount;

  const RankingEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.description,
    required this.spotCount,
    required this.commentCount,
  });

  int get total => spotCount + commentCount;
}

class CommunityService {
  Future<List<RankingEntry>> fetchRanking({String? token}) async {
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl$membersEndpoint'),
      headers: headers,
    );
    if (response.statusCode != 200) return [];

    final users = jsonDecode(response.body) as List<dynamic>;

    return users.map((u) {
      final avatarUrls = u['avatar_urls'] as Map<String, dynamic>?;
      final gravatarUrl = avatarUrls?['48'] as String?;
      final profileImageUrl = u['profile_image_url'] as String?;
      final avatarUrl = (profileImageUrl?.isNotEmpty == true)
          ? profileImageUrl
          : gravatarUrl;

      return RankingEntry(
        userId: u['id'] as int,
        name: u['name'] as String? ?? '',
        avatarUrl: avatarUrl,
        description: u['description'] as String?,
        spotCount: u['spot_count'] as int? ?? 0,
        commentCount: u['comment_count'] as int? ?? 0,
      );
    }).toList();
  }
}
