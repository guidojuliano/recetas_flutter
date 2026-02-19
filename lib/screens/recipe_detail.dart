import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/services/category_catalog_service.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeDetail extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetail({super.key, required this.recipe});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  late Recipe _recipe;
  Map<String, String> _categoryNames = const {};

  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _loadCategoryCatalog();
  }

  Future<void> _loadCategoryCatalog() async {
    final categories = await CategoryCatalogService.load();
    if (!mounted) return;
    setState(() {
      _categoryNames = {
        for (final category in categories)
          if (category.id != null) category.id.toString(): category.name,
      };
    });
  }

  bool get _canManageRecipe {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return user.id == _recipe.owner.id;
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF3C2E8D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deleteRecipeTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.deleteRecipeConfirm,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.delete,
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await Provider.of<RecipesProvider>(
        context,
        listen: false,
      ).deleteRecipe(recipeId: _recipe.id, accessToken: session.accessToken);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(l10n.recipeDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotDelete('$e'))));
    }
  }

  Future<void> _openEditSheet() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final updated = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _EditRecipeSheet(
              recipe: _recipe,
              accessToken: session.accessToken,
            ),
          ),
        );
      },
    );

    if (updated == null || !mounted) return;
    setState(() {
      _recipe = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ingredients = _recipe.ingredients;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(_recipe.id);
    final canManage = _canManageRecipe;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            title: Text(_recipe.title),
            backgroundColor: Colors.deepPurple,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    showGuestLoginSheet(context);
                    return;
                  }
                  favoritesProvider.toggleFavorite(_recipe.id);
                },
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                color: isFavorite ? Colors.redAccent : Colors.white,
                tooltip: isFavorite
                    ? l10n.removeFromFavorites
                    : l10n.addToFavorites,
              ),
              if (canManage)
                IconButton(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit),
                  color: Colors.white,
                  tooltip: l10n.edit,
                ),
              if (canManage)
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete),
                  color: Colors.white,
                  tooltip: l10n.delete,
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _buildHeroImage(),
                const SizedBox(height: 16),
                _buildMeta(),
                const SizedBox(height: 24),
                _buildSection(
                  title: l10n.ingredients,
                  body: ingredients.map((e) => '• $e').join('\n'),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: l10n.instructions,
                  body: _recipe.instructions,
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: RecipeImage(
          url: _recipe.imageUrl,
          fallbackSvg: _fallbackSvg,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMeta() {
    final l10n = AppLocalizations.of(context);
    final categories = _recipe.categories
        .map((id) => _categoryNames[id] ?? id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _recipe.title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.byAuthor(_recipe.owner.displayName),
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (c) => Chip(
                  label: Text(c),
                  backgroundColor: Colors.deepPurple.shade50,
                  labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                  side: BorderSide(color: Colors.deepPurple.shade100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 15)),
      ],
    );
  }
}

class _EditRecipeSheet extends StatefulWidget {
  final Recipe recipe;
  final String accessToken;

  const _EditRecipeSheet({required this.recipe, required this.accessToken});

  @override
  State<_EditRecipeSheet> createState() => _EditRecipeSheetState();
}

class _EditRecipeSheetState extends State<_EditRecipeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _imageUrl;
  late final TextEditingController _instructions;
  late final TextEditingController _ingredientsInput;
  late final List<String> _ingredients;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.recipe.title);
    _imageUrl = TextEditingController(text: widget.recipe.imageUrl);
    _instructions = TextEditingController(text: widget.recipe.instructions);
    _ingredientsInput = TextEditingController();
    _ingredients = List<String>.from(widget.recipe.ingredients);
  }

  @override
  void dispose() {
    _title.dispose();
    _imageUrl.dispose();
    _instructions.dispose();
    _ingredientsInput.dispose();
    super.dispose();
  }

  void _addIngredientsFromText(String text) {
    final parts = text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return;

    for (final part in parts) {
      if (!_ingredients.contains(part)) {
        _ingredients.add(part);
      }
    }
    _ingredientsInput.clear();
    setState(() {});
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneIngredient)));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final payload = <String, dynamic>{
        'title': _title.text.trim(),
        'image_url': _imageUrl.text.trim().isEmpty
            ? null
            : _imageUrl.text.trim(),
        'ingredients': _ingredients,
        'instructions': _instructions.text.trim(),
      };

      final updated = await Provider.of<RecipesProvider>(context, listen: false)
          .updateRecipe(
            recipeId: widget.recipe.id,
            accessToken: widget.accessToken,
            payload: payload,
          );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotUpdate('$e'))));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.editRecipe,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.titleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: InputDecoration(
                  labelText: l10n.imageUrl,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ingredients,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        onDeleted: () {
                          setState(() {
                            _ingredients.remove(item);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ingredientsInput,
                decoration: InputDecoration(
                  hintText: l10n.addIngredientAndPressEnter,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        _addIngredientsFromText(_ingredientsInput.text),
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: _addIngredientsFromText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructions,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.instructions,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.instructionsRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: Text(
                    _saving ? l10n.saving : l10n.saveChanges,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
