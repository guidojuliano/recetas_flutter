import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final recipesProvider = Provider.of<RecipesProvider>(context, listen: false);
      if (recipesProvider.recipes.isEmpty) {
        await recipesProvider.fetchRecipes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RecipesProvider, FavoritesProvider>(
      builder: (context, recipesProvider, favoritesProvider, child) {
        final allRecipes = recipesProvider.recipes;
        final favorites = allRecipes
            .where((recipe) => favoritesProvider.isFavorite(recipe.id))
            .toList();

        if (recipesProvider.isLoading && allRecipes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (favorites.isEmpty) {
          return const Center(
            child: Text('Todavía no marcaste recetas como favoritas'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 12),
          itemCount: favorites.length,
          itemBuilder: (context, index) => _recipeCard(context, favorites[index]),
        );
      },
    );
  }

  Widget _recipeCard(BuildContext context, Recipe recipe) {
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
                        'by ${recipe.owner.displayName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    return IconButton(
                      onPressed: () => favoritesProvider.toggleFavorite(recipe.id),
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      tooltip: 'Quitar de favoritos',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
