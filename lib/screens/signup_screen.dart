import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text('Registro pendiente'),
      ),
    );
  }
}
