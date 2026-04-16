class AddSpot {
  final String title;
  final String status;
  final AddSpotACF acf;

  AddSpot({required this.title, this.status = 'publish', required this.acf});

  Map<String, dynamic> toJson() {
    return {'title': title, 'status': status, 'acf': acf.toJson()};
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
  String lastvisited;
  final String? note;
  final List<String>? specials;
  final String waterquality;
  String? image;
  String? image2;
  String? image3;

  AddSpotACF({
    required this.lat,
    required this.long,
    required this.secure,
    required this.space,
    required this.swim,
    required this.fire,
    required this.lastvisited,
    this.note,
    this.specials,
    this.image,
    this.image2,
    this.image3,
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
      'image': image,
      'image2': image2,
      'image3': image3,
      'lastvisited': lastvisited,
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
      specials: json['specials'] != null
          ? List<String>.from(json['specials'])
          : null,
      waterquality: json['waterquality'] ?? 'keine',
      image: json['image'],
      image2: json['image2'],
      image3: json['image3'],
      lastvisited: json['lastvisited'],
    );
  }
}
