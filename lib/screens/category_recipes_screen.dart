import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRecipesScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryDisplayName;

  const CategoryRecipesScreen({
    super.key,
    required this.categoryName,
    this.categoryDisplayName,
  });

  @override
  State<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends State<CategoryRecipesScreen> {
  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  late Future<List<Recipe>> _futureRecipes;

  @override
  void initState() {
    super.initState();
    _futureRecipes = _loadCategoryRecipes();
  }

  Future<List<Recipe>> _loadCategoryRecipes() async {
    final allRecipes = await Provider.of<RecipesProvider>(
      context,
      listen: false,
    ).fetchRecipes();
    final target = widget.categoryName.trim();
    return allRecipes.where((recipe) {
      return recipe.categories.contains(target);
    }).toList();
  }

  Future<void> _reload() async {
    setState(() {
      _futureRecipes = _loadCategoryRecipes();
    });
    await _futureRecipes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryDisplayName ?? widget.categoryName),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _futureRecipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.recipesLoadError('${snapshot.error}'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return Center(
              child: Text(
                l10n.noRecipesForCategory(
                  widget.categoryDisplayName ?? widget.categoryName,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final recipe = recipes[index];
                      return _recipeCard(context, recipe);
                    }, childCount: recipes.length),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
        ).then((_) => _reload());
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
                const SizedBox(width: 20),
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
