import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/following_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicProfileScreen extends StatefulWidget {
  final Profile profile;

  const PublicProfileScreen({super.key, required this.profile});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  late Future<List<Recipe>> _future;

  bool get _isOwnProfile {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return user.id == widget.profile.id;
  }

  @override
  void initState() {
    super.initState();
    _future = Provider.of<RecipesProvider>(
      context,
      listen: false,
    ).fetchRecipesByOwnerId(widget.profile.id);
  }

  Future<void> _reload() async {
    setState(() {
      _future = Provider.of<RecipesProvider>(
        context,
        listen: false,
      ).fetchRecipesByOwnerId(widget.profile.id);
    });
    await _future;
  }

  Future<void> _toggleFollow(FollowingProvider followingProvider) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      showGuestLoginSheet(context);
      return;
    }

    await followingProvider.toggleFollow(widget.profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _future,
        builder: (context, snapshot) {
          final recipes = snapshot.data ?? const <Recipe>[];
          return Column(
            children: [
              _buildHeader(recipes.length),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            l10n.myRecipesLoadError('${snapshot.error}'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (recipes.isEmpty) {
                      return Center(child: Text(l10n.noCreatedRecipesYet));
                    }

                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) =>
                            _recipeCard(context, recipes[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int recipeCount) {
    final l10n = AppLocalizations.of(context);
    final avatarUrl = widget.profile.avatarUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF8F4FC),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 36, color: Colors.deepPurple)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            widget.profile.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.userRecipesCount(recipeCount),
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          if (!_isOwnProfile)
            Consumer<FollowingProvider>(
              builder: (context, followingProvider, _) {
                final isFollowing = followingProvider.isFollowing(
                  widget.profile.id,
                );
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.deepPurple.shade100
                        : Colors.deepPurple,
                    foregroundColor: isFollowing
                        ? Colors.deepPurple
                        : Colors.white,
                  ),
                  onPressed: () => _toggleFollow(followingProvider),
                  child: Text(
                    isFollowing ? l10n.followingUser : l10n.followUser,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _recipeCard(BuildContext context, Recipe recipe) {
    final l10n = AppLocalizations.of(context);
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
