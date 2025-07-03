import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // <--- ¡Importa Provider!

// Asegúrate de importar los archivos de AuthProvider, AuthRepository y AuthService
import 'package:yana/providers/auth_provider.dart';
import 'package:yana/repository/auth_repository.dart';
import 'package:yana/services/auth_service.dart';

import 'package:yana/views/authentication/login_view.dart';
import 'package:yana/views/home/home_view.dart'; // Asegúrate de tener tu HomeView

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es'); // Inicializa locale 'es'

  // NUEVO: Inicialización y provisión del AuthProvider
  final authService = AuthService();
  final authRepo = AuthRepository(authService);

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final authProvider = AuthProvider(authRepo);
        // Llama a tryAutoLogin aquí para verificar la API al inicio
        authProvider.tryAutoLogin();
        return authProvider;
      },
      child: const MyApp(), // MyApp ahora es un hijo del Provider
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NUEVO: Observa el AuthProvider
    final auth = context.watch<AuthProvider>();

    // Determina la pantalla principal según el estado de autenticación
    Widget homeScreen;
    switch (auth.status) {
      case AuthStatus.authenticated:
        homeScreen = const HomeView(); // Tu HomeView real
        break;
      case AuthStatus.authenticating:
        homeScreen = const Scaffold(body: Center(child: CircularProgressIndicator()));
        break;
      default:
        homeScreen = const LoginView(); // Tu LoginView real
        break;
    }

    // Define el color del círculo indicador de la API
    Color indicatorColor;
    if (auth.isApiReachable) {
      indicatorColor = Colors.green; // Verde para API conectada
    } else {
      indicatorColor = Colors.red;   // Rojo para API desconectada
    }

    // Opcional: No mostrar el círculo durante la carga inicial si auth.status es authenticating
    final bool showIndicator = auth.status != AuthStatus.authenticating;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Si quieres usar Material Design 3
      ),
      // NUEVO: Usamos un Builder y Stack para superponer el indicador
      home: Builder(
        builder: (context) {
          return Stack(
            children: [
              // 1. La pantalla principal de la aplicación (Login, Home, Loading)
              homeScreen,

              // 2. El círculo indicador de estado de la API, en la esquina superior derecha
              if (showIndicator)
                Positioned(
                  // Posición en la esquina superior derecha, con margen del borde y de la barra de estado del sistema
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 10,
                  child: Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: indicatorColor,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}