import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spots/add/models/add_spot.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_cache.dart';
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

  Future<List<Spot>> fetchSpots({int perPage = 100, int page = 1}) async {
    final uri = Uri.parse(
      '$baseUrl$spotsEndpoint',
    ).replace(queryParameters: {'per_page': '$perPage', 'page': '$page'});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      await SpotCache.saveSpots(response.body);
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
        debugPrint('Response: ${response.body}');
        if (context.mounted) {
          showSnackBar(
            context,
            _spotErrorMessage(response.statusCode, response.body),
            Colors.red,
            const Duration(seconds: 6),
          );
        }
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
    List<int>? keptImageIds,
  }) async {
    bool tokenExists = _checkTokenExists(token, context);

    if (tokenExists) {
      final originalIds = existingSpot.imageIds ?? [];
      final remaining = keptImageIds ?? originalIds;

      // Delete media items that were removed
      final removedIds = originalIds
          .where((id) => !remaining.contains(id))
          .toList();
      for (final id in removedIds) {
        try {
          await http.delete(
            Uri.parse('$baseUrl$mediaEndpoint/$id?force=true'),
            headers: {'Authorization': 'Bearer $token'},
          );
        } catch (e) {
          debugPrint('Fehler beim Löschen des Mediums $id: $e');
        }
      }

      List<int> uploadedImageIds = [];
      if (images != null && images.isNotEmpty) {
        showSnackBar(context, 'Bilder werden hochgeladen...', Colors.orange);
        uploadedImageIds = await uploadImagesAndGetIds(images, token!, context);
      }
      final allImageIds = [...remaining, ...uploadedImageIds];

      spot.acf.image = allImageIds.isNotEmpty
          ? allImageIds[0].toString()
          : null;
      spot.acf.image2 = allImageIds.length > 1
          ? allImageIds[1].toString()
          : null;
      spot.acf.image3 = allImageIds.length > 2
          ? allImageIds[2].toString()
          : null;

      if (images != null && uploadedImageIds.length != images.length) {
        if (context.mounted) {
          showSnackBar(
            context,
            'Nicht alle Bilder konnten hochgeladen werden',
            Colors.red,
          );
        }
      }
    }

    try {
      final url = Uri.parse('$baseUrl$spotsEndpoint/${existingSpot.id}');
      final requestBody = jsonEncode(spot.toJson());
      debugPrint('updateSpot body: $requestBody');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        showSnackBar(context, 'Spot erfolgreich aktualisiert!', Colors.green);
        return true;
      } else {
        debugPrint(
          'Fehler beim Aktualisieren des Spots: ${response.statusCode}',
        );
        debugPrint('Response: ${response.body}');
        if (context.mounted) {
          showSnackBar(
            context,
            _spotErrorMessage(response.statusCode, response.body),
            Colors.red,
            const Duration(seconds: 6),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Spots: $e');
      showSnackBar(context, 'Fehler beim Aktualisieren des Spots!', Colors.red);
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

  String _spotErrorMessage(int statusCode, String responseBody) {
    const errorMessage =
        "Keine ausreichende Berechtigung. Gehe auf Einstellungen und prüfe, ob du die Rolle Editor hast. Falls ja kann ein erneutes ab- und anmelden helfen.";
    if (statusCode == 401 || statusCode == 403) {
      return errorMessage;
    }
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final params = body['data']?['params'];
      if (params is Map && params.containsKey('acf')) {
        return errorMessage;
      }
      final code = body['code'] as String? ?? '';
      if (code.contains('forbidden') || code.contains('unauthorized')) {
        return errorMessage;
      }
    } catch (_) {}
    return 'Fehler beim Speichern des Spots.';
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
