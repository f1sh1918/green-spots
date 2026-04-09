import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import 'package:spots/spots/models/comment.dart';

class CommentService {
  Future<int> fetchCommentCount(int postId) async {
    final uri = Uri.parse('$baseUrl$commentsEndpoint?post=$postId&per_page=1');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final total = response.headers['x-wp-total'];
      return int.tryParse(total ?? '') ?? 0;
    }
    return 0;
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final uri = Uri.parse(
      '$baseUrl$commentsEndpoint?post=$postId&per_page=100&orderby=date&order=desc',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    }
    throw Exception(
      'Kommentare konnten nicht geladen werden (${response.statusCode})',
    );
  }

  Future<Comment> postComment({
    required int postId,
    required String content,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl$commentsEndpoint');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'post': postId, 'content': content}),
    );
    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    }
    final body = _parseErrorMessage(response.body);
    throw Exception(
      'Kommentar konnte nicht gespeichert werden (${response.statusCode}): $body',
    );
  }

  String _parseErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? body;
    } catch (_) {
      return body;
    }
  }

  Future<Comment> updateComment({
    required int commentId,
    required String content,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl$commentsEndpoint/$commentId');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode == 200) {
      return Comment.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Kommentar konnte nicht bearbeitet werden (${response.statusCode})',
    );
  }

  Future<void> deleteComment({
    required int commentId,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl$commentsEndpoint/$commentId?force=true');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Kommentar konnte nicht gelöscht werden (${response.statusCode})',
      );
    }
  }
}
