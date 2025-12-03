import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spots/add/models/add_spot.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/spots/models/spot.dart';

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

  Future<bool> addSpot(AddSpot spot, String? token, BuildContext context) async {
    _checkTokenExists(token, context);
    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(spot.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Fehler beim Hinzufügen des Spots: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Spots: $e');
      return false;
    }
  }

  Future<AddSpot?> getSpot(int id) async {
    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint/$id');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AddSpot.fromJson(data);
      } else {
        debugPrint('Fehler beim Abrufen des Spots: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Fehler beim Abrufen des Spots: $e');
      return null;
    }
  }

  Future<bool> updateSpot(int id, AddSpot spot, String token, BuildContext context) async {
    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint/$id');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(spot.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Fehler beim Aktualisieren des Spots: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Spots: $e');
      return false;
    }
  }

  Future<bool> deleteSpot(int id, String token, BuildContext context) async {
    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint/$id');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Fehler beim Löschen des Spots: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Fehler beim Löschen des Spots: $e');
      return false;
    }
  }

  bool _checkTokenExists(String? token, BuildContext context) {
    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nicht authorisiert. Bitte melden sie sich an!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
    }
    return true;
  }
}
