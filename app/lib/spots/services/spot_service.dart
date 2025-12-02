import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import '../models/spot.dart';

class SpotService {
  Future<List<Spot>> fetchSpots({int perPage = 20, int page = 1}) async {
    final uri = Uri.parse('$baseUrl$spotsEndpoint').replace(queryParameters: {
      'per_page': '$perPage',
      'page': '$page',
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Spot.listFromJson(response.body);
    } else {
      // You can create a custom exception type if you like.
      throw Exception('Failed to load spots – HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}
