import 'package:http/http.dart' as http;
import 'package:spots/constants/api.dart';
import 'package:spots/updates/update_model.dart';

class UpdateService {
  Future<List<Update>> fetchUpdates({int perPage = 5, int page = 1}) async {
    final uri = Uri.parse(
      '$baseUrl$updatesEndpoint',
    ).replace(queryParameters: {'per_page': '$perPage', 'page': '$page'});

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Update.listFromJson(response.body);
    } else {
      // You can create a custom exception type if you like.
      throw Exception(
        'Failed to load spots – HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }
}
