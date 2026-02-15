import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _googleLogoSvg =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path fill='#FFC107' d='M43.6 20.1H42V20H24v8h11.3C33.7 32.6 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.2 6.2 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.7-.4-3.9z'/><path fill='#FF3D00' d='M6.3 14.7l6.6 4.8C14.7 15.6 19 12 24 12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.2 6.2 29.3 4 24 4c-7.7 0-14.3 4.4-17.7 10.7z'/><path fill='#4CAF50' d='M24 44c5.2 0 10-2 13.6-5.2l-6.3-5.2C29.4 35 26.9 36 24 36c-5.2 0-9.6-3.4-11.2-8.2l-6.6 5.1C9.5 39.6 16.2 44 24 44z'/><path fill='#1976D2' d='M43.6 20.1H42V20H24v8h11.3c-1 2.6-3 4.7-5.6 5.9l6.3 5.2C38.7 36.4 44 31 44 24c0-1.3-.1-2.7-.4-3.9z'/></svg>";

void showGuestLoginSheet(BuildContext context) {
  StreamSubscription<AuthState>? sub;
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF3C2E8D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.session != null && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      bool isLoggingIn = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Necesitas iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para acceder a esta función, inicia sesión con Google.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoggingIn
                      ? null
                      : () async {
                          setState(() {
                            isLoggingIn = true;
                          });
                          try {
                            await Supabase.instance.client.auth.signInWithOAuth(
                              OAuthProvider.google,
                              redirectTo: 'io.supabase.flutter://login-callback',
                            );
                          } finally {
                            setState(() {
                              isLoggingIn = false;
                            });
                          }
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(_googleLogoSvg, width: 18, height: 18),
                      const SizedBox(width: 10),
                      isLoggingIn
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          : const Text(
                              'LOGIN WITH GOOGLE',
                              style: TextStyle(color: Colors.black87),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Seguir como invitado',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    sub?.cancel();
  });
}
