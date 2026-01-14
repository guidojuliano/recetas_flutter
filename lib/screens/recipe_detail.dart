import 'package:flutter/material.dart';

class RecipeDetail extends StatelessWidget {
  final String recipeName;
  const RecipeDetail({super.key, required this.recipeName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            title: Text(recipeName),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            backgroundColor: Colors.deepPurple,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                <Widget>[
                  _buildHeroImage(),
                  const SizedBox(height: 16),
                  _buildMeta(),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Ingredientes',
                    body:
                        '- Pasta\n- Salsa de tomate\n- Queso\n- Carne molida\n- Especias',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Instrucciones',
                    body:
                        '1. Precalienta el horno.\n2. Cocina la pasta.\n3. Monta capas de pasta, salsa y queso.\n4. Hornea 30 minutos.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
        child: Image.network(
          'https://www.tasteofhome.com/wp-content/uploads/2025/07/Best-Lasagna_EXPS_ATBBZ25_36333_DR_07_01_2b.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          recipeName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text('Por: John Doe'),
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
        Text(body),
      ],
    );
  }
}
