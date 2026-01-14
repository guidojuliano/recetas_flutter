import 'package:flutter/material.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:recetas_flutter/services/recipe_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: RecipeService().fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final recipes = snapshot.data ?? [];
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showBottom(context);
        },
        hoverColor: Colors.deepPurpleAccent,
        backgroundColor: Colors.deepPurple,
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
  Widget _RecipesCard(BuildContext context, dynamic recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetail(recipeName: 'Lassagna'),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 125,
          child: Card(
            color: Colors.deepPurple.shade100,
            elevation: 8,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 125,
                  width: 100,

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      recipe['image_link'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 26),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(height: 1, width: 75, color: Colors.deepPurple),
                    SizedBox(height: 4),
                    Text(
                      'by ${recipe['author']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _recipeName = TextEditingController();
  final TextEditingController _author = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _ingredients = TextEditingController();
  final TextEditingController _instructions = TextEditingController();

  @override
  void dispose() {
    _recipeName.dispose();
    _author.dispose();
    _imageUrl.dispose();
    _ingredients.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Recipe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(label: 'Recipe Name', controller: _recipeName),
              SizedBox(height: 20),
              _buildTextField(label: 'Autor', controller: _author),
              SizedBox(height: 20),
              _buildTextField(label: 'Image URL', controller: _imageUrl),
              SizedBox(height: 20),
              _buildTextField(label: 'Ingredients', controller: _ingredients),
              SizedBox(height: 20),
              _buildTextField(label: 'Instructions', controller: _instructions),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process data
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Create Recipe',
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
  }) {
    return TextFormField(
      controller: controller,
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
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
