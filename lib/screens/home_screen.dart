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
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/utils/category_translation.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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

class RecipeForm extends StatefulWidget {
  const RecipeForm({super.key});

  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  static final String _apiBaseUrl = EnvConfig.apiUrl;

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addNewRecipe,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(label: l10n.title, controller: _title),
              SizedBox(height: 20),
              _buildTextField(
                label: l10n.imageUrl,
                controller: _imageUrl,
                optional: true,
              ),
              SizedBox(height: 20),
              _buildIngredientsField(),
              const SizedBox(height: 16),
              _buildSelectedCategories(),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _selectCategory,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  _loadingCategories ? l10n.loading : l10n.selectCategories,
                  style: const TextStyle(color: Colors.deepPurple),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                label: l10n.instructions,
                controller: _instructions,
                isInstructions: true,
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting ? l10n.creating : l10n.createRecipe,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
        ),
      ),
      validator: (value) {
        if (optional) return null;
        if (value == null || value.trim().isEmpty) {
          return l10n.pleaseEnterField(label);
        }
        return null;
      },
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
          decoration: InputDecoration(
            hintText: l10n.ingredientHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addIngredientsFromText(_ingredientInput.text),
            ),
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
      return Text(
        l10n.noCategoriesSelected,
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selected
          .map(
            (c) => Chip(
              label: Text(c.category.localizedName(context)),
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
