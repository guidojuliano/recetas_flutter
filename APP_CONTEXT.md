# App Context: recetas_flutter

## Overview
- Flutter app that lists recipes from a local HTTP API and shows details for a selected recipe.
- State management uses `provider` with a `ChangeNotifier`.

## Entry Point and Navigation
- `lib/main.dart`: `MainApp` sets up `MultiProvider` and `MaterialApp`.
- `RecipeBook` uses a `DefaultTabController` with 4 tabs, but `TabBarView` currently has only `HomeScreen`.
- `HomeScreen` navigates to `RecipeDetail` via `Navigator.push`.

## State and Data Flow
- `lib/providers/recipes_providers.dart`: `RecipesProvider` holds `isLoading` and `recipes`.
- `fetchRecipes()` calls `GET http://10.0.2.2:3001/recipes` and expects JSON with a `recipes` array.
- Updates `isLoading` and `recipes`, then `notifyListeners()` for UI updates.

## UI Screens
- `lib/screens/home_screen.dart`:
  - `HomeScreen` triggers `fetchRecipes()` on first frame.
  - Shows a loading spinner, empty state, or list of recipe cards.
  - Uses `CustomScrollView` + `SliverList`.
  - Floating action button opens a bottom sheet `RecipeForm`.
- `lib/screens/recipe_detail.dart`:
  - Displays recipe image, metadata, ingredients, and instructions.
  - Uses `CustomScrollView` with a `SliverAppBar`.

## Data Model
- `lib/models/recipes_model.dart`:
  - `Recipe` (freezed + json_serializable):
    - `name`, `author`, `category` (List<String>), `imageLink` (from `image_link`),
      `ingredients` (List<String>), `instructions`.

## Dependencies
- Runtime: `provider`, `http`, `freezed_annotation`, `json_annotation`.
- Dev: `build_runner`, `freezed`, `json_serializable`.

## Assets
- `assets/images/` is declared in `pubspec.yaml` (no usage found in code).

## Notes
- The API base uses `10.0.2.2` (Android emulator loopback).
- Only the Home tab is wired; other tabs have no views yet.
