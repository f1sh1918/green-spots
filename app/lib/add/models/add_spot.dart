class AddSpot {
  final String title;
  final String status;
  final AddSpotACF acf;

  AddSpot({
    required this.title,
    this.status = 'publish',
    required this.acf,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'status': status,
      'acf': acf.toJson(),
    };
  }

  factory AddSpot.fromJson(Map<String, dynamic> json) {
    return AddSpot(
      title: json['title'] ?? '',
      status: json['status'] ?? 'publish',
      acf: AddSpotACF.fromJson(json['acf'] ?? {}),
    );
  }
}

class AddSpotACF {
  final double lat;
  final double long;
  final double secure;
  final int space;
  final bool swim;
  final bool fire;
  final String? note;
  final List<String>? specials;
  final String waterquality;

  AddSpotACF({
    required this.lat,
    required this.long,
    required this.secure,
    required this.space,
    required this.swim,
    required this.fire,
    this.note,
    this.specials,
    required this.waterquality,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': long,
      'secure': secure,
      'space': space,
      'swim': swim,
      'fire': fire,
      'note': note,
      'specials': specials,
      'waterquality': waterquality,
    };
  }

  factory AddSpotACF.fromJson(Map<String, dynamic> json) {
    return AddSpotACF(
      lat: (json['lat'] ?? 0.0).toDouble(),
      long: (json['long'] ?? 0.0).toDouble(),
      secure: (json['secure'] ?? 0.0).toDouble(),
      space: json['space'] ?? 0,
      swim: json['swim'] ?? false,
      fire: json['fire'] ?? false,
      note: json['note'] ?? '',
      specials: List<String>.from(json['specials']),
      waterquality: json['waterquality'] ?? 'kein Wasser',
    );
  }
}
