import 'dart:convert';

class Update {
  final int id;
  final String title;
  final String downloadUrl;
  final String? releaseNotes;

  Update({
    required this.id,
    required this.title,
    required this.downloadUrl,
    this.releaseNotes,
  });

  // --------------------------------------------------------------
  // Factory constructor that parses a Map<String, dynamic>
  // --------------------------------------------------------------
  factory Update.fromJson(Map<String, dynamic> json) {
    // WP returns the "title" and "content" wrapped in a `rendered` key.
    final title = json['title']?['rendered'] as String? ?? '';

    // Advanced Custom Fields (ACF) is optional; guard against null.
    final acf = json['acf'] as Map<String, dynamic>?;

    return Update(
      id: json['id'],
      title: title,
      downloadUrl: acf?['downloadurl'] ?? '',
      releaseNotes: acf?['releasenotes'] ?? '',
    );
  }

  // --------------------------------------------------------------
  // Helper to decode a whole JSON list
  // --------------------------------------------------------------
  static List<Update> listFromJson(String jsonStr) {
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded
        .map((e) => Update.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
