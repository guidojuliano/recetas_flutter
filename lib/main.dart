import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/categories_screen.dart';
import 'package:recetas_flutter/screens/favorites_screen.dart';
import 'package:recetas_flutter/screens/home_screen.dart';
import 'package:recetas_flutter/screens/initial_screen.dart';
import 'package:recetas_flutter/screens/my_recipes_screen.dart';
import 'package:recetas_flutter/screens/search_screen.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipesProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Cookly',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          primaryTextTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            toolbarTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        home: const InitialScreen(),
      ),
    );
  }
}

class RecipeBook extends StatelessWidget {
  const RecipeBook({super.key});

  void _showProfileSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    if (session == null) {
      showGuestLoginSheet(context);
      return;
    }
    if (user == null) return;
    showModalBottomSheet(
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
                l10n.profile,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyRecipesScreen(ownerId: user.id),
                    ),
                  );
                },
                child: Text(
                  l10n.myRecipes,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const InitialScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  l10n.logout,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final user = Supabase.instance.client.auth.currentUser;
        final metadata = user?.userMetadata ?? {};
        final avatarUrl = metadata['avatar_url'] as String?;
        final displayName =
            metadata['name'] as String? ?? metadata['full_name'] as String?;
        final initials = (displayName?.trim().isNotEmpty ?? false)
            ? displayName!.trim().characters.first.toUpperCase()
            : 'U';

        return InkWell(
          onTap: () => _showProfileSheet(context),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEDE7F6),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF673AB7),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.PNG', width: 24, height: 24),
              const SizedBox(width: 8),
              const Text('Cookly'),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildAvatar(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(icon: Icon(Icons.home), text: l10n.tabHome),
              Tab(icon: Icon(Icons.search), text: l10n.tabSearch),
              Tab(icon: Icon(Icons.food_bank), text: l10n.tabCategories),
              Tab(icon: Icon(Icons.favorite), text: l10n.tabFavorites),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeScreen(),
            SearchScreen(),
            CategoriesScreen(),
            FavoritesScreen(),
          ],
        ),
      ),
    );
  }
}
