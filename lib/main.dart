import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recetas_flutter/firebase_options.dart';
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/providers/favorites_provider.dart';
import 'package:recetas_flutter/providers/following_provider.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/categories_screen.dart';
import 'package:recetas_flutter/screens/favorites_screen.dart';
import 'package:recetas_flutter/screens/home_screen.dart';
import 'package:recetas_flutter/screens/initial_screen.dart';
import 'package:recetas_flutter/screens/my_recipes_screen.dart';
import 'package:recetas_flutter/screens/search_screen.dart';
import 'package:recetas_flutter/services/push_notifications_service.dart';
import 'package:recetas_flutter/widgets/guest_login_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationsService.instance.initialize(appNavigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipesProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => FollowingProvider()),
      ],
      child: MaterialApp(
        title: 'Cookly',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
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

class RecipeBook extends StatefulWidget {
  const RecipeBook({super.key});

  @override
  State<RecipeBook> createState() => _RecipeBookState();
}

class _RecipeBookState extends State<RecipeBook> with TickerProviderStateMixin {
  static const Color _surfaceWhite = Color(0xFFF6F6F8);
  static const List<Color> _navColors = [
    Color(0xFFFC5F8B),
    Color(0xFFFF8A3D),
    Color(0xFF6C63FF),
    Color(0xFFE74C3C),
  ];

  int _selectedIndex = 0;
  Color _bottomColor = _navColors[0];
  late final PageController _pageController;
  late final AnimationController _profileMenuController;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _iconScales;
  late final List<Animation<double>> _iconRotations;
  late final List<Animation<double>> _iconSaturations;
  late final List<Animation<double>> _labelScales;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _profileMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _controllers = List.generate(
      _navColors.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        reverseDuration: const Duration(milliseconds: 180),
      ),
    );

    _iconScales = _controllers
        .map(
          (controller) => Tween<double>(begin: 1, end: 1.35).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeIn,
            ),
          ),
        )
        .toList();

    _iconRotations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0, end: -0.22).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeIn,
            ),
          ),
        )
        .toList();

    _iconSaturations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
          ),
        )
        .toList();

    _labelScales = _controllers
        .map(
          (controller) => Tween<double>(begin: 1, end: 1.12).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeIn,
            ),
          ),
        )
        .toList();

    _controllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _profileMenuController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setActiveTab(int index) {
    if (index == _selectedIndex) return;
    _controllers[_selectedIndex].reverse();
    _controllers[index].forward();
    setState(() {
      _selectedIndex = index;
      _bottomColor = _navColors[index];
    });
    _profileMenuController.reverse();
  }

  void _onTabTap(int index) {
    if (index == _selectedIndex) return;
    _setActiveTab(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    _setActiveTab(index);
  }

  bool _isFlatTab(int index) => index == 1 || index == 3;

  bool _shouldShowGradientForPage(double page) {
    final clamped = page.clamp(0, 3).toDouble();
    final left = clamped.floor();
    final right = clamped.ceil();

    if (left == right) return !_isFlatTab(left);
    if (_isFlatTab(left) || _isFlatTab(right)) return false;
    return true;
  }

  void _showProfileSheet(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    if (session == null) {
      showGuestLoginSheet(context);
      return;
    }
    if (user == null) return;
    if (_profileMenuController.value > 0) {
      _profileMenuController.reverse();
    } else {
      _profileMenuController.forward();
    }
  }

  Future<void> _openMyRecipes(String ownerId) async {
    _profileMenuController.reverse();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyRecipesScreen(ownerId: ownerId)),
    );
  }

  Future<void> _logout() async {
    _profileMenuController.reverse();
    try {
      await PushNotificationsService.instance.unregisterCurrentToken();
    } catch (_) {
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar sesión. Intenta de nuevo.')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialScreen()),
      (route) => false,
    );
  }

  PreferredSizeWidget _buildProfileInlineMenu(AppLocalizations l10n) {
    final user = Supabase.instance.client.auth.currentUser;
    const menuHeight = 128.0;
    final factor = user == null ? 0.0 : _profileMenuController.value;

    final menuBody = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: user == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openMyRecipes(user.id),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(l10n.myRecipes),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1.3),
                    backgroundColor: Colors.white.withAlpha(18),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1.3),
                    backgroundColor: Colors.white.withAlpha(10),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
    );

    return PreferredSize(
      preferredSize: Size.fromHeight(menuHeight * factor),
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: factor,
          child: menuBody,
        ),
      ),
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

  List<double> _saturationMatrix(double saturation) {
    final inverse = 1 - saturation;
    final red = 0.213 * inverse;
    final green = 0.715 * inverse;
    final blue = 0.072 * inverse;
    return <double>[
      red + saturation,
      green,
      blue,
      0,
      0,
      red,
      green + saturation,
      blue,
      0,
      0,
      red,
      green,
      blue + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? _selectedIndex.toDouble())
        : _selectedIndex.toDouble();
    final showGradientBackground = _shouldShowGradientForPage(currentPage);
    final navItems = <_CandyNavItem>[
      _CandyNavItem(
        title: l10n.tabHome,
        icon: Icons.lunch_dining,
        color: _navColors[0],
      ),
      _CandyNavItem(
        title: l10n.tabSearch,
        icon: Icons.search,
        color: _navColors[1],
      ),
      _CandyNavItem(
        title: l10n.tabCategories,
        icon: Icons.restaurant_menu,
        color: _navColors[2],
      ),
      _CandyNavItem(
        title: l10n.tabFavorites,
        icon: Icons.favorite,
        color: _navColors[3],
      ),
    ];

    return Scaffold(
      backgroundColor: _surfaceWhite,
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
        bottom: _buildProfileInlineMenu(l10n),
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: showGradientBackground ? null : _surfaceWhite,
              gradient: showGradientBackground
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_surfaceWhite, _bottomColor.withAlpha(25)],
                    )
                  : null,
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              HomeScreen(),
              SearchScreen(),
              CategoriesScreen(),
              FavoritesScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onTabTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        final iconColor = Color.lerp(
                          Colors.grey.shade500,
                          item.color,
                          _controllers[index].value,
                        )!;
                        return Transform.rotate(
                          angle: _iconRotations[index].value,
                          child: Transform.scale(
                            scale: _iconScales[index].value,
                            alignment: Alignment.bottomCenter,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(
                                _saturationMatrix(
                                  _iconSaturations[index].value,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 28,
                                color: iconColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _labelScales[index].value,
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: index == _selectedIndex
                                  ? item.color
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CandyNavItem {
  final String title;
  final IconData icon;
  final Color color;

  const _CandyNavItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}
