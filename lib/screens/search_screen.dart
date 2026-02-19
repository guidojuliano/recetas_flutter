import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/services/category_catalog_service.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  Map<String, String> _categoryNames = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<RecipesProvider>(context, listen: false);
      if (provider.recipes.isEmpty) {
        await provider.fetchRecipes();
      }
      final categories = await CategoryCatalogService.load();
      if (!mounted) return;
      setState(() {
        _categoryNames = {
          for (final category in categories)
            if (category.id != null) category.id.toString(): category.name,
        };
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
      });
    });
  }

  List<Recipe> _filterRecipes(List<Recipe> all) {
    if (_query.isEmpty) return all;
    final q = _normalize(_query);
    return all.where((recipe) {
      final inTitle = _normalize(recipe.title).contains(q);
      final inOwner = _normalize(recipe.owner.displayName).contains(q);
      final inIngredients = recipe.ingredients
          .map(_normalize)
          .any((ingredient) => ingredient.contains(q));
      final inCategories = recipe.categories
          .map((id) => _normalize(_categoryNames[id] ?? id))
          .any((category) => category.contains(q));
      return inTitle || inOwner || inIngredients || inCategories;
    }).toList();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<RecipesProvider>(
      builder: (context, provider, child) {
        final allRecipes = provider.recipes;
        final filteredRecipes = _filterRecipes(allRecipes);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                            _searchFocus.unfocus();
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading && allRecipes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResults(filteredRecipes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(List<Recipe> recipes) {
    final l10n = AppLocalizations.of(context);
    if (recipes.isEmpty && _query.isNotEmpty) {
      return Center(child: Text(l10n.noSearchResults(_query)));
    }

    if (recipes.isEmpty) {
      return Center(child: Text(l10n.typeToSearchRecipes));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      itemCount: recipes.length,
      itemBuilder: (context, index) => _recipeCard(context, recipes[index]),
    );
  }

  Widget _recipeCard(BuildContext context, Recipe recipe) {
    final l10n = AppLocalizations.of(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(recipe.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetail(recipe: recipe)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 125,
          child: Card(
            color: const Color(0xFFF8F4FC),
            elevation: 8,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: const BorderSide(color: Color(0xFFE3D9F2), width: 1),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 125,
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: RecipeImage(
                      url: recipe.imageUrl,
                      fallbackSvg: _fallbackSvg,
                    ),
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(height: 1, width: 75, color: Colors.deepPurple),
                      const SizedBox(height: 4),
                      Text(
                        l10n.byAuthor(recipe.owner.displayName),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    if (session == null) {
                      showGuestLoginSheet(context);
                      return;
                    }
                    favoritesProvider.toggleFavorite(recipe.id);
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.grey.shade600,
                  ),
                  tooltip: isFavorite
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
