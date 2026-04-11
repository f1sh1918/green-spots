import 'package:flutter/material.dart';
import 'package:spots/user/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final _service = CommunityService();

  List<RankingEntry>? _members;
  bool _loading = false;
  String? _token;

  List<RankingEntry>? get members => _members;
  bool get loading => _loading;
  String? get token => _token;

  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
    _members = null;
    if (token != null) load();
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_members != null && !force) return;
    _loading = true;
    notifyListeners();
    try {
      _members = await _service.fetchRanking(token: _token);
    } catch (_) {
      _members = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  RankingEntry? getMember(int userId) =>
      _members?.where((m) => m.userId == userId).firstOrNull;
}
