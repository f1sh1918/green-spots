import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spots/add/models/add_spot.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/utils/messenger_utils.dart';

class SpotService {
  Future<List<int>> uploadImagesAndGetIds(
    List<File> images,
    String token,
    BuildContext context,
  ) async {
    List<int> imageIds = [];

    for (File image in images) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl$mediaEndpoint'),
        );

        request.headers['Authorization'] = 'Bearer $token';

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        var response = await request.send();

        if (response.statusCode == 201) {
          String responseBody = await response.stream.bytesToString();
          Map<String, dynamic> jsonResponse = json.decode(responseBody);

          // Media-ID aus der Response extrahieren
          int mediaId = jsonResponse['id'] ?? 0;
          if (mediaId > 0) {
            imageIds.add(mediaId);
          }
        } else {
          debugPrint(
            'Fehler beim Hochladen des Bildes: ${response.statusCode}',
          );
          String errorBody = await response.stream.bytesToString();
          debugPrint('Error body: $errorBody');
        }
      } catch (e) {
        showSnackBar(context, 'Fehler beim Hochladen des Bildes', Colors.red);
      }

      // Kurze Pause zwischen den Uploads
      await Future.delayed(Duration(milliseconds: 100));
    }

    return imageIds;
  }

  Future<List<Spot>> fetchSpots({int perPage = 20, int page = 1}) async {
    final uri = Uri.parse(
      '$baseUrl$spotsEndpoint',
    ).replace(queryParameters: {'per_page': '$perPage', 'page': '$page'});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Spot.listFromJson(response.body);
    } else {
      // You can create a custom exception type if you like.
      throw Exception(
        'Failed to load spots – HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  Future<bool> addSpot(
    AddSpot spot,
    String? token,
    BuildContext context, {
    List<File>? images,
  }) async {
    bool tokenExists = _checkTokenExists(token, context);

    // Bilder hochladen, falls vorhanden
    if (images != null && images.isNotEmpty && tokenExists) {
      showSnackBar(context, 'Bilder werden hochgeladen...', Colors.orange);
      List<int> imageIds = await uploadImagesAndGetIds(images, token!, context);

      if (imageIds.isNotEmpty) {
        // Media-IDs zu ACF hinzufügen (nicht URLs)
        spot.acf.image = imageIds[0].toString();
        if (imageIds.length > 1) spot.acf.image2 = imageIds[1].toString();
        if (imageIds.length > 2) spot.acf.image3 = imageIds[2].toString();
      }

      if (imageIds.length != images.length) {
        showSnackBar(
          context,
          'Nicht alle Bilder konnten hochgeladen werden',
          Colors.red,
        );
      }
    }

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
        if (context.mounted) {
          showSnackBar(context, 'Spot erfolgreich hinzugefügt!', Colors.green);
        }
        return true;
      } else {
        if (context.mounted) {
          final errorMessage = jsonDecode(response.body)['message'] ?? 'Fehler beim Hinzufügen des Spots';
          showSnackBar(context, errorMessage, Colors.red);
        }
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

  Future<bool> updateSpot(
    Spot existingSpot,
    AddSpot spot,
    String? token,
    BuildContext context, {
    List<File>? images,
  }) async {
    bool tokenExists = _checkTokenExists(token, context);

    if (tokenExists && existingSpot.imageIds!.isNotEmpty) {
      List<int> existingImageIds = existingSpot.imageIds!;
      List<int> uploadedImageIds = [];
      if (images != null && images.isNotEmpty) {
        showSnackBar(context, 'Bilder werden hochgeladen...', Colors.orange);
        uploadedImageIds = await uploadImagesAndGetIds(images, token!, context);
      }
      List<int> allImageIds = [...existingImageIds, ...uploadedImageIds];

      spot.acf.image = allImageIds[0].toString();
      if (allImageIds.length > 1) spot.acf.image2 = allImageIds[1].toString();
      if (allImageIds.length > 2) spot.acf.image3 = allImageIds[2].toString();

      if (uploadedImageIds.length != images?.length) {
        showSnackBar(
          context,
          'Nicht alle Bilder konnten hochgeladen werden',
          Colors.red,
        );
      }
    }

    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint/${existingSpot.id}');
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
        debugPrint(
          'Fehler beim Aktualisieren des Spots: ${response.statusCode}',
        );
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Spots: $e');
      return false;
    }
  }

  Future<bool> deleteSpot(int id, BuildContext context, String? token) async {
    bool tokenExists = _checkTokenExists(token, context);
    if (tokenExists && context.mounted) {
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
          showSnackBar(context, 'Spot erfolgreich gelöscht.', Colors.green);
          return true;
        } else {
          showSnackBar(context, 'Fehler beim Löschen des Spots!', Colors.red);
          return false;
        }
      } catch (e) {
        showSnackBar(context, 'Fehler beim Löschen des Spots!', Colors.red);
        return false;
      }
    } else {
      showSnackBar(
        context,
        'Sie sind nicht berechtigt einen Spot zu löschen!',
        Colors.red,
      );
      return false;
    }
  }

  bool _checkTokenExists(String? token, BuildContext context) {
    if (token == null) {
      if (context.mounted) {
        showSnackBar(
          context,
          'Nicht authorisiert. Bitte melden sie sich an!',
          Colors.orange,
          Duration(seconds: 3),
        );
        return false;
      }
    }
    return true;
  }
}
