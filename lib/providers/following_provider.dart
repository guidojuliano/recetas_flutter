import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:recetas_flutter/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowingProvider extends ChangeNotifier {
  static final String _baseUrl = EnvConfig.apiUrl;
  final Set<String> _followingUserIds = <String>{};
  StreamSubscription<AuthState>? _authSubscription;

  FollowingProvider() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      refresh();
    });
    refresh();
  }

  Set<String> get followingUserIds => _followingUserIds;

  bool isFollowing(String userId) => _followingUserIds.contains(userId);

  Future<void> refresh() async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (session == null || user == null) {
      _followingUserIds.clear();
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/${user.id}/following'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar following');
      }

      final dynamic decoded = jsonDecode(response.body);
      final Iterable<dynamic> rows = decoded is List ? decoded : const [];

      final ids = <String>{};
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final id = row['user_id'];
          if (id is String && id.isNotEmpty) {
            ids.add(id);
          }
        }
      }

      _followingUserIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
      _followingUserIds.clear();
    }

    notifyListeners();
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (session == null || user == null || targetUserId == user.id) {
      return false;
    }

    final wasFollowing = _followingUserIds.contains(targetUserId);

    if (wasFollowing) {
      _followingUserIds.remove(targetUserId);
    } else {
      _followingUserIds.add(targetUserId);
    }
    notifyListeners();

    try {
      if (wasFollowing) {
        final response = await http.delete(
          Uri.parse('$_baseUrl/users/$targetUserId/follow'),
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('No se pudo dejar de seguir');
        }
      } else {
        final response = await http.post(
          Uri.parse('$_baseUrl/users/$targetUserId/follow'),
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('No se pudo seguir usuario');
        }
      }
    } catch (_) {
      if (wasFollowing) {
        _followingUserIds.add(targetUserId);
      } else {
        _followingUserIds.remove(targetUserId);
      }
      notifyListeners();
    }

    return _followingUserIds.contains(targetUserId);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
