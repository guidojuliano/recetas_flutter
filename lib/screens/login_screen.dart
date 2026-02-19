import 'package:flutter/material.dart';
import 'package:recetas_flutter/l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(child: Text(l10n.loginPending)),
    );
  }
}
