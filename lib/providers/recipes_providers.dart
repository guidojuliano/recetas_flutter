import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/models/recipes_model.dart';

class RecipesProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Recipe> recipes = [];
  static final String _baseUrl = EnvConfig.apiUrl;

  Future<List<Recipe>> fetchRecipes() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/recipes');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          recipes = data
              .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          recipes = [];
        }
        isLoading = false;
        notifyListeners();
        return recipes;
      } else {
        isLoading = false;
        notifyListeners();
        recipes = [];
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      recipes = [];
      throw Exception('Error fetching recipes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Recipe>> fetchRecipesByOwnerId(String ownerId) async {
    final url = Uri.parse('$_baseUrl/recipes?owner_id=$ownerId');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load user recipes');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteRecipe({
    required String recipeId,
    required String accessToken,
  }) async {
    final url = Uri.parse('$_baseUrl/recipes/$recipeId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error eliminando receta: ${response.body}');
    }

    recipes = recipes.where((recipe) => recipe.id != recipeId).toList();
    notifyListeners();
  }

  Future<Recipe> updateRecipe({
    required String recipeId,
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('$_baseUrl/recipes/$recipeId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualizando receta: ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    Recipe updatedRecipe;

    if (decoded is Map<String, dynamic>) {
      final dynamic candidate = decoded['id'] != null
          ? decoded
          : decoded['recipe'];
      if (candidate is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida al actualizar receta');
      }
      updatedRecipe = Recipe.fromJson(candidate);
    } else {
      await fetchRecipes();
      final found = recipes.where((recipe) => recipe.id == recipeId);
      if (found.isEmpty) {
        throw Exception('No se pudo resolver la receta actualizada');
      }
      updatedRecipe = found.first;
      return updatedRecipe;
    }

    recipes = recipes
        .map((recipe) => recipe.id == recipeId ? updatedRecipe : recipe)
        .toList();
    notifyListeners();
    return updatedRecipe;
  }
}
