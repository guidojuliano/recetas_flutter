import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:recetas_flutter/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteRecipeIds = <String>{};
  StreamSubscription<AuthState>? _authSubscription;
  static final String _baseUrl = EnvConfig.apiUrl;

  String get _languageCode {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code == 'en' || code == 'pt' || code == 'es') return code;
    return 'es';
  }

  FavoritesProvider() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      _loadFavorites();
    });
    _loadFavorites();
  }

  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;

  bool isFavorite(String recipeId) => _favoriteRecipeIds.contains(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final shouldRemove = _favoriteRecipeIds.contains(recipeId);

    if (shouldRemove) {
      _favoriteRecipeIds.remove(recipeId);
    } else {
      _favoriteRecipeIds.add(recipeId);
    }
    notifyListeners();

    try {
      if (shouldRemove) {
        final response = await http.delete(
          Uri.parse('$_baseUrl/recipes/$recipeId/favorite'),
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('No se pudo quitar favorito');
        }
      } else {
        final response = await http.post(
          Uri.parse('$_baseUrl/recipes/$recipeId/favorite'),
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('No se pudo agregar favorito');
        }
      }
    } catch (_) {
      // Keep optimistic UI state if backend call fails.
    }
  }

  Future<void> _loadFavorites() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _favoriteRecipeIds.clear();
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me/favorites?lang=$_languageCode'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.statusCode != 200) {
        throw Exception('No se pudieron cargar favoritos');
      }
      final dynamic decoded = jsonDecode(response.body);
      final Iterable<dynamic> rows = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['favorites'] is List
                ? decoded['favorites'] as List<dynamic>
                : const <dynamic>[]);
      final ids = <String>{};
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final recipeId = row['id'];
          if (recipeId is String && recipeId.isNotEmpty) {
            ids.add(recipeId);
          }
        }
      }

      _favoriteRecipeIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
      _favoriteRecipeIds.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
