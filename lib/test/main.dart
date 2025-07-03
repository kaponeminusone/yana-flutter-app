// lib/main.dart
import 'package:flutter/material.dart';
import 'package:yana/providers/auth_provider.dart';
import 'package:yana/repository/auth_repository.dart';
import 'package:yana/services/auth_service.dart';
import 'package:yana/views/authentication/login_view.dart';
import 'package:yana/views/home/home_view.dart';
import 'package:provider/provider.dart';

void main() {
  final authService = AuthService();
  final authRepo = AuthRepository(authService);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(authRepo)..tryAutoLogin(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      title: 'Yana',
      home: Builder(builder: (ctx) {
        switch (auth.status) {
          case AuthStatus.authenticated:
            return const HomeView();    // tu HomeView
          case AuthStatus.authenticating:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          default:
            return const LoginView();   // pantalla de login
        }
      }),
    );
  }
}
