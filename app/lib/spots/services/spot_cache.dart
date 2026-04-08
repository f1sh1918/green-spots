import 'dart:convert';

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
}
