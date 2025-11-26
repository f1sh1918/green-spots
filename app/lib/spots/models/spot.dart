import 'dart:convert';

class Spot {
  final int id;
  final bool swim;
  final bool fire;
  final double space;
  final double secure;
  final String title;
  final String water;
  final String? note;
  final double? lat;
  final double? long;
  final String? thumbnail;
  final List<dynamic>? specials;
  final List<dynamic>? images;

  Spot(
      {required this.id,
      required this.title,
      required this.space,
      required this.secure,
      required this.water,
      required this.swim,
      required this.fire,
      this.images,
      this.lat,
      this.long,
      this.note,
      this.specials,
      this.thumbnail});

  // --------------------------------------------------------------
  // Factory constructor that parses a Map<String, dynamic>
  // --------------------------------------------------------------
  factory Spot.fromJson(Map<String, dynamic> json) {
    // WP returns the "title" and "content" wrapped in a `rendered` key.
    final title = json['title']?['rendered'] as String? ?? '';

    // Advanced Custom Fields (ACF) is optional; guard against null.
    final acf = json['acf'] as Map<String, dynamic>?;

    double? parseDouble(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      return double.tryParse('$raw');
    }

    final images = [json['image_url'], json['image2_url'], json['image2_url']];

    return Spot(
        id: json['id'],
        title: title,
        note: acf?['note'] as String?,
        images: images,
        swim: acf?['swim'] ?? false,
        fire: acf?['fire'] ?? false,
        space: parseDouble(acf?['space'])!,
        secure: parseDouble(acf?['secure'])!,
        lat: parseDouble(['lat']),
        long: parseDouble(['long']),
        specials: acf?['specials'],
        water: acf?['waterquality'],
        thumbnail: json['image_thumb']);
  }

  // --------------------------------------------------------------
  // Helper to decode a whole JSON list
  // --------------------------------------------------------------
  static List<Spot> listFromJson(String jsonStr) {
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((e) => Spot.fromJson(e as Map<String, dynamic>)).toList();
  }
}
