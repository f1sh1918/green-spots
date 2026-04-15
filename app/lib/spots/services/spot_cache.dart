import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/spots/models/spot.dart';

class SpotCache {
  static const _spotsKey = 'cached_spots_json';
  static const _queueKey = 'queued_spots';

  static Future<void> saveSpots(String jsonBody) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spotsKey, jsonBody);
  }

  static Future<List<Spot>?> loadCachedSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_spotsKey);
    if (raw == null) return null;
    try {
      return Spot.listFromJson(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> enqueueSpot(Map<String, dynamic> spotData) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(spotData));
    await prefs.setStringList(_queueKey, queue);
  }

  static Future<List<Map<String, dynamic>>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    return queue.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  static Future<void> dequeueSpot(String queueId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['_queueId'] == queueId;
    });
    await prefs.setStringList(_queueKey, queue);
  }

  // ── Queued image storage ──────────────────────────────────────────────────

  static Future<Directory> _queuedImagesDir(String queueId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/queued_images/$queueId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [images] into permanent storage for [queueId].
  /// Files already inside the queued_images dir are kept in place.
  /// Old files no longer in [images] are deleted.
  /// Returns the list of saved file paths (stored in queue data as _imagePaths).
  static Future<List<String>> saveQueuedImages(
    String queueId,
    List<File> images,
  ) async {
    final dir = await _queuedImagesDir(queueId);

    // Collect existing files in the dir before making changes
    final existing = <String>{};
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e is File) existing.add(e.path);
      }
    }

    final paths = <String>[];
    final kept = <String>{};

    for (int i = 0; i < images.length; i++) {
      final dest = File('${dir.path}/image_$i.jpg');
      kept.add(dest.path);
      if (images[i].path != dest.path) {
        // Source is outside the dir (new image) — copy it in
        await images[i].copy(dest.path);
      }
      // If source == dest the file is already in the right place
      paths.add(dest.path);
    }

    // Delete old files that are no longer in the new set
    for (final old in existing) {
      if (!kept.contains(old)) {
        try {
          await File(old).delete();
        } catch (_) {}
      }
    }

    return paths;
  }

  /// Loads previously saved images for [queueId].
  static Future<List<File>> loadQueuedImages(String queueId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/queued_images/$queueId');
    if (!await dir.exists()) return [];
    final files = await dir.list().where((e) => e is File).toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.cast<File>();
  }

  /// Deletes all stored images for [queueId].
  static Future<void> deleteQueuedImages(String queueId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/queued_images/$queueId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
