import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:recetas_flutter/widgets/recipe_image.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/models/recipes_model.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/public_profile_screen.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/utils/category_translation.dart';
import 'package:recetas_flutter/widgets/animated_favorite_button.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:recetas_flutter/widgets/image_search_picker_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _fallbackSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'><rect width='512' height='512' rx='96' fill='#673ab7'/><text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle' font-family='Arial, sans-serif' font-size='48' font-weight='700' letter-spacing='2' fill='#ffffff'>NO IMAGE</text></svg>";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipesProvider>(context, listen: false).fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Consumer<RecipesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.recipes.isEmpty) {
            return Center(child: Text(l10n.noRecipesAvailable));
          } else {
            final recipes = provider.recipes;
            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final recipe = recipes[index];
                      return _RecipesCard(context, recipe);
                    }, childCount: recipes.length),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            showGuestLoginSheet(context);
            return;
          }
          _showBottom(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        hoverColor: Colors.deepPurpleAccent,
        backgroundColor: const Color(0xFF673AB7),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showBottom(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFFF3EFFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: RecipeForm(),
          ),
        );
      },
    );
  }

  // ignore: non_constant_identifier_names
  Widget _RecipesCard(BuildContext context, Recipe recipe) {
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

class RecipeForm extends StatefulWidget {
  const RecipeForm({super.key});

  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  static final String _apiBaseUrl = EnvConfig.apiUrl;
  static const Color _sheetSurface = Color(0xFFF3EFFA);
  static const Color _cardSurface = Colors.white;
  static const Color _fieldSurface = Color(0xFFF8F6FC);
  static const Color _borderSoft = Color(0xFFE3DCF3);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _ingredientInput = TextEditingController();
  final TextEditingController _instructions = TextEditingController();
  final FocusNode _ingredientFocus = FocusNode();
  final FocusNode _instructionsFocus = FocusNode();
  final List<String> _ingredients = [];
  final List<CategoryItem> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  bool _loadingCategories = false;
  bool _submitting = false;

  String get _languageCode {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code == 'en' || code == 'pt' || code == 'es') return code;
    return 'es';
  }

  @override
  void dispose() {
    _title.dispose();
    _imageUrl.dispose();
    _ingredientInput.dispose();
    _instructions.dispose();
    _ingredientFocus.dispose();
    _instructionsFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/categories?lang=$_languageCode'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _categories
            ..clear()
            ..addAll(
              data.map(
                (item) => CategoryItem(
                  id: (item as Map<String, dynamic>)['id'] as int,
                  category: CategoryTranslation.fromJson(item),
                ),
              ),
            );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  void _addIngredientsFromText(String text) {
    final l10n = AppLocalizations.of(context);
    final parts = text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return;

    for (final part in parts) {
      if (part.length > 20) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.ingredientTooLong(part))));
        continue;
      }
      if (!_ingredients.contains(part)) {
        _ingredients.add(part);
      }
    }
    _ingredientInput.clear();
    setState(() {});
    FocusScope.of(context).requestFocus(_ingredientFocus);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.checkRequiredFields)));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneIngredient)));
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      showGuestLoginSheet(context);
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final recipesProvider = Provider.of<RecipesProvider>(
        context,
        listen: false,
      );
      final payload = {
        'title': _title.text.trim(),
        'ingredients': _ingredients,
        'instructions': _instructions.text.trim(),
        'image_url': _imageUrl.text.trim().isEmpty
            ? null
            : _imageUrl.text.trim(),
        'category_ids': _selectedCategoryIds.toList(),
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201) {
        throw Exception('Error creando receta: ${response.body}');
      }

      await recipesProvider.fetchRecipes();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3EFFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: ImageSearchPickerSheet(initialQuery: _title.text),
      ),
    );
    if (selectedUrl == null || selectedUrl.isEmpty) return;
    setState(() {
      _imageUrl.text = selectedUrl;
    });
  }

  Future<void> _selectCategory() async {
    final l10n = AppLocalizations.of(context);
    if (_loadingCategories) return;
    if (_categories.isEmpty) {
      await _loadCategories();
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final tempSelected = Set<int>.from(_selectedCategoryIds);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    l10n.selectCategories,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final categoryItem = _categories[index];
                        final isSelected = tempSelected.contains(
                          categoryItem.id,
                        );
                        return ListTile(
                          title: Text(
                            categoryItem.category.localizedName(context),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.deepPurple,
                                )
                              : null,
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                tempSelected.remove(categoryItem.id);
                              } else {
                                tempSelected.add(categoryItem.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryIds
                              ..clear()
                              ..addAll(tempSelected);
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          l10n.save,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: _sheetSurface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withAlpha(70),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.addNewRecipe,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.checkRequiredFields,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.deepPurple.withAlpha(165),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderSoft),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(label: l10n.title, controller: _title),
                      const SizedBox(height: 12),
                      _buildImagePickerField(l10n),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        title: l10n.ingredients,
                        icon: Icons.restaurant_menu_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildIngredientsField(),
                      const SizedBox(height: 12),
                      _buildSectionTitle(
                        title: l10n.selectCategories,
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildSelectedCategories(),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _selectCategory,
                          icon: Icon(
                            _loadingCategories
                                ? Icons.hourglass_bottom_rounded
                                : Icons.tune_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _loadingCategories
                                ? l10n.loading
                                : l10n.selectCategories,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(
                              color: Colors.deepPurple,
                              width: 1.3,
                            ),
                            backgroundColor: Colors.deepPurple.withAlpha(10),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        title: l10n.instructions,
                        icon: Icons.menu_book_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: l10n.instructions,
                        controller: _instructions,
                        isInstructions: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x4A673AB7),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? l10n.creating : l10n.createRecipe,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? suffixIcon,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF6A53A8),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _fieldSurface,
      suffixIcon: suffixIcon,
      isDense: dense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderSoft, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderSoft, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isInstructions = false,
    bool optional = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      focusNode: isInstructions ? _instructionsFocus : null,
      maxLines: isInstructions ? 6 : 1,
      minLines: isInstructions ? 4 : 1,
      textInputAction: isInstructions
          ? TextInputAction.newline
          : TextInputAction.done,
      keyboardType: isInstructions
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: _inputDecoration(label: label),
      validator: (value) {
        if (optional) return null;
        if (value == null || value.trim().isEmpty) {
          return l10n.pleaseEnterField(label);
        }
        return null;
      },
    );
  }

  Widget _buildImagePickerField(AppLocalizations l10n) {
    final hasImage = _imageUrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title: l10n.imageUrl, icon: Icons.image_rounded),
        const SizedBox(height: 8),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _imageUrl.text.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _fieldSurface,
                  alignment: Alignment.center,
                  child: const Text(
                    'No se pudo cargar la imagen',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: _fieldSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSoft),
            ),
            child: const Text(
              'No elegiste imagen todavia',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buscar imagen'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _imageUrl.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: _borderSoft),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Quitar'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientsField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ingredients,
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ingredients
              .map(
                (item) => Chip(
                  label: Text(item),
                  backgroundColor: Colors.deepPurple.withAlpha(22),
                  labelStyle: const TextStyle(
                    color: Color(0xFF4D2FA1),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: Colors.deepPurple.withAlpha(30)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
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
        TextFormField(
          controller: _ingredientInput,
          focusNode: _ingredientFocus,
          decoration: _inputDecoration(
            label: l10n.ingredientHint,
            suffixIcon: Container(
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () => _addIngredientsFromText(_ingredientInput.text),
                tooltip: l10n.addIngredientAndPressEnter,
              ),
            ),
            dense: true,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: _addIngredientsFromText,
        ),
      ],
    );
  }

  Widget _buildSelectedCategories() {
    final l10n = AppLocalizations.of(context);
    final selected = _categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .toList();

    if (selected.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _fieldSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderSoft),
        ),
        child: Text(
          l10n.noCategoriesSelected,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selected
          .map(
            (c) => Chip(
              label: Text(c.category.localizedName(context)),
              backgroundColor: Colors.deepPurple.withAlpha(22),
              labelStyle: const TextStyle(
                color: Color(0xFF4D2FA1),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: Colors.deepPurple.withAlpha(30)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onDeleted: () {
                setState(() {
                  _selectedCategoryIds.remove(c.id);
                });
              },
            ),
          )
          .toList(),
    );
  }
}

class CategoryItem {
  final int id;
  final CategoryTranslation category;

  CategoryItem({required this.id, required this.category});
}
