import 'package:flutter/material.dart';
import 'package:recetas_flutter/screens/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(fontFamily: 'Opensans'),
      home: RecipeBook(),
    );
  }
}

class RecipeBook extends StatelessWidget {
  const RecipeBook({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recipe Book'),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          backgroundColor: Colors.deepPurple,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.category), text: 'Categories'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(children: [HomeScreen()]),
      ),
    );
  }
}
