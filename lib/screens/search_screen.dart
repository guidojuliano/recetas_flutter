import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/public_profile_screen.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/services/category_catalog_service.dart';
import 'package:recetas_flutter/widgets/animated_favorite_button.dart';
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

  List<_UserSearchItem> _buildUsers(List<Recipe> allRecipes) {
    final Map<String, _UserSearchItem> usersById = {};
    for (final recipe in allRecipes) {
      final profile = recipe.owner;
      final existing = usersById[profile.id];
      if (existing == null) {
        usersById[profile.id] = _UserSearchItem(profile: profile, recipes: 1);
      } else {
        usersById[profile.id] = _UserSearchItem(
          profile: existing.profile,
          recipes: existing.recipes + 1,
        );
      }
    }

    var users = usersById.values.toList();
    if (_query.isNotEmpty) {
      final q = _normalize(_query);
      users = users
          .where((user) => _normalize(user.profile.displayName).contains(q))
          .toList();
    }
    users.sort((a, b) => b.recipes.compareTo(a.recipes));
    return users;
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
        final filteredUsers = _buildUsers(allRecipes);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: l10n.usersSearchHint,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: provider.isLoading && allRecipes.isEmpty
                    ? const Center(
                        key: ValueKey('search-loading'),
                        child: CircularProgressIndicator(),
                      )
                    : _buildResults(filteredUsers, filteredRecipes),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(List<_UserSearchItem> users, List<Recipe> recipes) {
    final l10n = AppLocalizations.of(context);

    if (users.isEmpty && recipes.isEmpty && _query.isNotEmpty) {
      return _animatedMessage(
        key: const ValueKey('no-results'),
        text: l10n.noSearchResults(_query),
      );
    }

    if (users.isEmpty && recipes.isEmpty) {
      return _animatedMessage(
        key: const ValueKey('empty-search'),
        text: l10n.typeToSearchRecipes,
      );
    }

    final children = <Widget>[];
    var animationIndex = 0;
    if (users.isNotEmpty) {
      children.add(_sectionTitle(l10n.usersSection));
      for (final user in users) {
        children.add(
          _StaggeredReveal(
            key: ValueKey('user-${_query}-${user.profile.id}'),
            index: animationIndex++,
            child: _userCard(context, user),
          ),
        );
      }
    }
    if (recipes.isNotEmpty) {
      children.add(_sectionTitle(l10n.recipesSection));
      for (final recipe in recipes) {
        children.add(
          _StaggeredReveal(
            key: ValueKey('recipe-${_query}-${recipe.id}'),
            index: animationIndex++,
            child: _recipeCard(context, recipe),
          ),
        );
      }
    }

    return ListView(
      key: ValueKey('results-${_query}_${users.length}_${recipes.length}'),
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      children: children,
    );
  }

  Widget _animatedMessage({required Key key, required String text}) {
    return Center(
      key: key,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 14),
              child: child,
            ),
          );
        },
        child: Text(text),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _userCard(BuildContext context, _UserSearchItem user) {
    final l10n = AppLocalizations.of(context);
    final avatarUrl = user.profile.avatarUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(profile: user.profile),
          ),
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
                  child: Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 34,
                              color: Colors.deepPurple,
                            )
                          : null,
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
                        user.profile.displayName,
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
                        l10n.userRecipesCount(user.recipes),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
                    child: Hero(
                      tag: 'recipe-image-${recipe.id}',
                      child: RecipeImage(
                        url: recipe.imageUrl,
                        fallbackSvg: _fallbackSvg,
                      ),
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicProfileScreen(profile: recipe.owner),
                            ),
                          );
                        },
                        child: Text(
                          l10n.byAuthor(recipe.owner.displayName),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  inactiveColor: Colors.grey.shade600,
                  tooltip: isFavorite
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites,
                  onPressed: () {
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    if (session == null) {
                      showGuestLoginSheet(context);
                      return;
                    }
                    favoritesProvider.toggleFavorite(recipe.id);
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

class _UserSearchItem {
  final Profile profile;
  final int recipes;

  const _UserSearchItem({required this.profile, required this.recipes});
}

class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    final computedDelay = widget.index * 45;
    final delayMs = computedDelay > 360 ? 360 : computedDelay;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.06),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
