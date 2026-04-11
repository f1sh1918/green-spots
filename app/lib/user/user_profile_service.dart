import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import 'package:spots/user/user_profile_model.dart';

class UserProfileService {
  Future<UserProfile> fetchProfile(int userId, {String? token}) async {
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Use the custom endpoint — includes spot_count and comment_count.
    // Falls back to the standard WP endpoint if not yet deployed.
    final customResponse = await http.get(
      Uri.parse('$baseUrl$membersEndpoint/$userId'),
      headers: headers,
    );

    if (customResponse.statusCode == 200) {
      final data = jsonDecode(customResponse.body) as Map<String, dynamic>;
      return UserProfile.fromJson(
        data,
        spotCount: data['spot_count'] as int? ?? 0,
        commentCount: data['comment_count'] as int? ?? 0,
      );
    }

    // Legacy fallback: standard WP endpoint + separate count requests
    final userResponse = await http.get(
      Uri.parse('$baseUrl$userEndpoint/$userId'),
      headers: headers,
    );
    if (userResponse.statusCode != 200) {
      throw Exception(
        'Profil konnte nicht geladen werden (${userResponse.statusCode})',
      );
    }
    final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;

    final results = await Future.wait([
      http.get(
        Uri.parse('$baseUrl$spotsEndpoint?author=$userId&per_page=1'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$baseUrl$commentsEndpoint?author=$userId&per_page=1'),
        headers: headers,
      ),
    ]);
    final spotCount = int.tryParse(results[0].headers['x-wp-total'] ?? '') ?? 0;
    final commentCount =
        int.tryParse(results[1].headers['x-wp-total'] ?? '') ?? 0;

    return UserProfile.fromJson(
      userData,
      spotCount: spotCount,
      commentCount: commentCount,
    );
  }

  /// Uploads [imageFile] to the WP media library and returns the full URL.
  Future<String> uploadProfileImage(File imageFile, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$mediaEndpoint'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 201) {
      throw Exception('Bild-Upload fehlgeschlagen (${streamed.statusCode})');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['source_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Keine Bild-URL in der Server-Antwort');
    }
    return url;
  }

  /// Updates [description] and/or [profileImageUrl] for the current user.
  Future<void> saveProfile({
    required String token,
    String? description,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{
      if (description != null) 'description': description,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    };
    if (body.isEmpty) return;

    final response = await http.post(
      Uri.parse('$baseUrl$userEndpoint/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Profil konnte nicht gespeichert werden (${response.statusCode})',
      );
    }
  }
}
