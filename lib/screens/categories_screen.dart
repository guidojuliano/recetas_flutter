import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/screens/category_recipes_screen.dart';
import 'package:recetas_flutter/utils/category_translation.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const List<Color> _brandPalette = <Color>[
    Color(0xFF3DE396),
    Color(0xFFE3AD3D),
    Color(0xFF7D568E),
    Color(0xFF4D6359),
    Color(0xFFB7E33D),
    Color(0xFF7F8E56),
    Color(0xFF5D4D63),
  ];

  late Future<List<CategoryTranslation>> _futureCategories;

  String get _languageCode {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code == 'en' || code == 'pt' || code == 'es') return code;
    return 'es';
  }

  @override
  void initState() {
    super.initState();
    _futureCategories = _fetchCategories();
  }

  Future<List<CategoryTranslation>> _fetchCategories() async {
    final response = await http.get(
      Uri.parse('${EnvConfig.apiUrl}/categories?lang=$_languageCode'),
    );
    if (response.statusCode != 200) {
      throw Exception('categories_load_failed');
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .map((item) {
          final row = item as Map<String, dynamic>;
          return CategoryTranslation.fromJson(row);
        })
        .where((item) => item.name.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<CategoryTranslation>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final rawError = '${snapshot.error}';
          final message = rawError.contains('categories_load_failed')
              ? l10n.couldNotLoadCategories
              : l10n.categoryLoadError(rawError);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message, textAlign: TextAlign.center),
            ),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return Center(child: Text(l10n.noCategoriesAvailable));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            if (category.id == null) {
              return const SizedBox.shrink();
            }
            final displayName = category.localizedName(context);
            final theme = _themeForCategory(category.name, index);
            final imageOnLeft = index.isEven;

            return _CategoryStripe(
              title: displayName,
              backgroundColor: theme.backgroundColor,
              imageUrl: theme.imageUrl,
              imageOnLeft: imageOnLeft,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryRecipesScreen(
                      categoryName: category.id.toString(),
                      categoryDisplayName: displayName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  _CategoryTheme _themeForCategory(String rawName, int index) {
    final name = rawName.trim().toLowerCase();

    if (name.contains('postre') ||
        name.contains('dulce') ||
        name.contains('dessert') ||
        name.contains('sweet') ||
        name.contains('sobremesa')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFFE3AD3D),
        imageUrl:
            'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('entrada') ||
        name.contains('starter') ||
        name.contains('appetizer') ||
        name.contains('aperitivo')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF7F8E56),
        imageUrl:
            'https://images.unsplash.com/photo-1546793665-c74683f339c1?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('caliente') ||
        name.contains('hot') ||
        name.contains('quente')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFFE3AD3D),
        imageUrl:
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('frio') ||
        name.contains('fría') ||
        name.contains('fria') ||
        name.contains('cold') ||
        name.contains('gelado')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF5D4D63),
        imageUrl:
            'https://images.unsplash.com/photo-1532635241-17e820acc59f?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('light')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFFB7E33D),
        imageUrl:
            'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('vegana') ||
        name.contains('vegano') ||
        name.contains('vegetariana') ||
        name.contains('vegetarian') ||
        name.contains('vegan')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF3DE396),
        imageUrl:
            'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('sin tacc')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF4D6359),
        imageUrl:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('desayuno') ||
        name.contains('breakfast') ||
        name.contains('cafe da manha')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFFE3AD3D),
        imageUrl:
            'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('merienda') ||
        name.contains('snack') ||
        name.contains('lanche')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF3DE396),
        imageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('bebidas') ||
        name.contains('drinks') ||
        name.contains('beverages')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF7D568E),
        imageUrl:
            'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=900&q=80',
      );
    }
    if (name.contains('ensalada') ||
        name.contains('salad') ||
        name.contains('salada')) {
      return const _CategoryTheme(
        backgroundColor: Color(0xFF4D6359),
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
      );
    }

    return _CategoryTheme(
      backgroundColor: _brandPalette[index % _brandPalette.length],
      imageUrl:
          'https://images.unsplash.com/photo-1495195134817-aeb325a55b65?auto=format&fit=crop&w=900&q=80',
    );
  }
}

class _CategoryStripe extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final String imageUrl;
  final bool imageOnLeft;
  final VoidCallback onTap;

  const _CategoryStripe({
    required this.title,
    required this.backgroundColor,
    required this.imageUrl,
    required this.imageOnLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double stripeHeight = 118;
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: stripeHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Center(
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      letterSpacing: 8,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _foregroundColor(backgroundColor),
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   left: imageOnLeft ? 8 : null,
              //   right: imageOnLeft ? null : 8,
              //   top: (stripeHeight - imageSize) / 2,
              //   child: ClipOval(
              //     child: Image.network(
              //       imageUrl,
              //       width: imageSize,
              //       height: imageSize,
              //       fit: BoxFit.cover,
              //       errorBuilder: (context, error, stackTrace) {
              //         return Container(
              //           width: imageSize,
              //           height: imageSize,
              //           color: Colors.white24,
              //           alignment: Alignment.center,
              //           child: Icon(
              //             Icons.restaurant_menu,
              //             size: 34,
              //             color: _foregroundColor(backgroundColor),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Color _foregroundColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF273241);
  }
}

class _CategoryTheme {
  final Color backgroundColor;
  final String imageUrl;

  const _CategoryTheme({required this.backgroundColor, required this.imageUrl});
}
