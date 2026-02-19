import 'package:flutter/material.dart';

class CategoryTranslation {
  final int? id;
  final String name;
  final String es;
  final String en;
  final String pt;

  const CategoryTranslation({
    required this.id,
    required this.name,
    required this.es,
    required this.en,
    required this.pt,
  });

  factory CategoryTranslation.fromJson(Map<String, dynamic> row) {
    final translations = row['translations'] is Map<String, dynamic>
        ? row['translations'] as Map<String, dynamic>
        : const <String, dynamic>{};

    String pick(List<String> keys) {
      for (final key in keys) {
        final direct = row[key];
        if (direct is String && direct.trim().isNotEmpty) return direct.trim();
        final nested = translations[key];
        if (nested is String && nested.trim().isNotEmpty) return nested.trim();
      }
      return '';
    }

    final name = pick(['name', 'slug']);
    return CategoryTranslation(
      id: row['id'] is int ? row['id'] as int : null,
      name: name,
      es: pick(['es', 'name_es', 'spanish']),
      en: pick(['en', 'name_en', 'english']),
      pt: pick(['pt', 'name_pt', 'portuguese']),
    );
  }

  String localizedName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code == 'en' && en.isNotEmpty) return en;
    if (code == 'pt' && pt.isNotEmpty) return pt;
    if (code == 'es' && es.isNotEmpty) return es;
    return name;
  }
}

String normalizeCategoryKey(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[_\-\s]+'), '');
}
