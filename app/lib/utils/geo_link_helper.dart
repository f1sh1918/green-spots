class GeoLinkHelper {
  static Map<String, dynamic> parseGeoQueryWithPath(String path, String query) {
    String decodedQuery = Uri.decodeComponent(query);
    RegExp regExp = RegExp(r'q=([-\d.]+),([-\d.]+)(?:\(([^)]+)\))?');
    RegExpMatch? match = regExp.firstMatch(decodedQuery);
    String title = '';

    if (match != null) {
      return {
        'lat': double.tryParse(match.group(1) ?? ''),
        'lng': double.tryParse(match.group(2) ?? ''),
        'title': match.group(3) ?? title,
      };
    }

    if (decodedQuery.contains('(')) {
      int index = decodedQuery.indexOf('(') + 1;
      title = decodedQuery.substring(index, decodedQuery.length - 1);
    }
    final parts = path.split(',');
    if (parts.length >= 2) {
      return {
        'lat': double.tryParse(parts[0]),
        'lng': double.tryParse(parts[1]),
        'title': title,
      };
    }
    return {'lat': null, 'lng': null, 'title': title};
  }
}
