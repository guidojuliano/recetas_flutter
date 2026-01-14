import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  Future<List<dynamic>> fetchRecipes() async {
    final url = Uri.parse('http://10.0.2.2:3001/recipes');
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    return data['recipes'];
  }
}
