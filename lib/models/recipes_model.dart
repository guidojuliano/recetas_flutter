import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipes_model.freezed.dart';
part 'recipes_model.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required Profile owner,
    required String title,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'image_url') required String imageUrl,
    required List<String> ingredients,
    required String instructions,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'recipe_categories', fromJson: _categoriesFromJson)
    required List<String> categories,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'display_name') required String displayName,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

List<String> _categoriesFromJson(Object? json) {
  if (json is! List) return const [];
  final List<String> names = [];
  for (final entry in json) {
    if (entry is Map<String, dynamic>) {
      final category = entry['category'];
      if (category is Map<String, dynamic>) {
        final name = category['name'] ?? category['slug'];
        if (name is String && name.isNotEmpty) {
          names.add(name);
        }
      }
    }
  }
  return names;
}
