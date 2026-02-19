import 'dart:convert';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/utils/category_translation.dart';

class CategoryCatalogService {
  static List<CategoryTranslation> _cache = const [];
  static Map<String, String> _byId = const {};

  static String get _languageCode {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code == 'en' || code == 'pt' || code == 'es') return code;
    return 'es';
  }

  static Future<List<CategoryTranslation>> load({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.isNotEmpty) return _cache;

    final response = await http.get(
      Uri.parse('${EnvConfig.apiUrl}/categories?lang=$_languageCode'),
    );
    if (response.statusCode != 200) {
      _cache = const [];
      _byId = const {};
      return _cache;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      _cache = const [];
      _byId = const {};
      return _cache;
    }

    final categories = decoded
        .map(
          (item) => CategoryTranslation.fromJson(item as Map<String, dynamic>),
        )
        .where((c) => c.id != null)
        .toList();

    _cache = categories;
    _byId = {
      for (final category in categories) category.id.toString(): category.name,
    };
    return _cache;
  }

  static String? nameForId(String categoryId) => _byId[categoryId];
}
