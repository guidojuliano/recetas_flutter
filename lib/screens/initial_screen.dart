import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';
import 'package:recetas_flutter/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  StreamSubscription<AuthState>? _authSub;
  bool _isLoggingIn = false;

  static const String _googleLogoSvg =
      "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path fill='#FFC107' d='M43.6 20.1H42V20H24v8h11.3C33.7 32.6 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.2 6.2 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.7-.4-3.9z'/><path fill='#FF3D00' d='M6.3 14.7l6.6 4.8C14.7 15.6 19 12 24 12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.2 6.2 29.3 4 24 4c-7.7 0-14.3 4.4-17.7 10.7z'/><path fill='#4CAF50' d='M24 44c5.2 0 10-2 13.6-5.2l-6.3-5.2C29.4 35 26.9 36 24 36c-5.2 0-9.6-3.4-11.2-8.2l-6.6 5.1C9.5 39.6 16.2 44 24 44z'/><path fill='#1976D2' d='M43.6 20.1H42V20H24v8h11.3c-1 2.6-3 4.7-5.6 5.9l6.3 5.2C38.7 36.4 44 31 44 24c0-1.3-.1-2.7-.4-3.9z'/></svg>";

  @override
  void initState() {
    super.initState();
    _redirectIfLogged();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      if (session != null && mounted) {
        await _upsertProfile(session.user);
        _goToHome();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _redirectIfLogged() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _goToHome();
        }
      });
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RecipeBook()),
    );
  }

  Future<void> _upsertProfile(User user) async {
    final metadata = user.userMetadata ?? {};
    final displayName =
        metadata['name'] as String? ?? metadata['full_name'] as String? ?? '';
    final avatarUrl = metadata['avatar_url'] as String?;

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background-screen.png', fit: BoxFit.cover),
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [
          //         Colors.black.withOpacity(0.55),
          //         Colors.black.withOpacity(0.15),
          //       ],
          //       begin: Alignment.bottomCenter,
          //       end: Alignment.topCenter,
          //     ),
          //   ),
          // ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EE6A6),
                      shadowColor: Colors.black,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loginWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          _googleLogoSvg,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 10),
                        _isLoggingIn
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color.fromARGB(255, 3, 44, 99),
                                ),
                              )
                            : Text(
                                l10n.login,
                                style: TextStyle(
                                  color: Color.fromARGB(255, 3, 44, 99),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goToHome,
                    child: Text(
                      l10n.continueAsGuest,
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    if (_isLoggingIn) return;
    setState(() {
      _isLoggingIn = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      debugPrint('OAuth error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.oauthError('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }
}
