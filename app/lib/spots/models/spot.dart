import 'dart:convert';

class Spot {
  final int id;
  final String title;
  final String? note;
  final String? image1;
  final String? image2;
  final String? image3;
  final bool? swim;
  final bool? fire;
  final double? space;
  final double? secure;
  final double? lat;
  final double? long;
  final List<dynamic>? specials;

  Spot({
    required this.id,
    required this.title,
    this.note,
    this.image1,
    this.image2,
    this.image3,
    this.swim,
    this.fire,
    this.space,
    this.secure,
    this.lat,
    this.long,
    this.specials,
  });

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

    return Spot(
      id: json['id'] as int,
      title: title,
      note: acf?['note'] as String?,
      image1: json['image_url'] as String?,
      image2: json['image2_url'] as String?,
      image3: json['image3_url'] as String?,
      swim:acf?['swim'] as bool?,
      fire:acf?['fire'] as bool?,
      space:parseDouble(acf?['space']),
      secure:parseDouble(acf?['secure']),
      lat:parseDouble(['lat']),
      long:parseDouble(['long']),
      specials:acf?['specials'] as List<dynamic>,
    );
  }

  // --------------------------------------------------------------
  // Helper to decode a whole JSON list
  // --------------------------------------------------------------
  static List<Spot> listFromJson(String jsonStr) {
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((e) => Spot.fromJson(e as Map<String, dynamic>)).toList();
  }
}