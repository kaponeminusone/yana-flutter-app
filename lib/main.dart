// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/mantenimiento_provider.dart';
import 'package:yana/repository/auth_repository.dart';
import 'package:yana/repository/mantenimiento_repository.dart';
import 'package:yana/services/auth_service.dart';

import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/repository/vehiculo_repository.dart';
import 'package:yana/services/mantenimiento_service.dart';
import 'package:yana/services/vehiculo_service.dart';

import 'package:yana/views/authentication/login_view.dart';
import 'package:yana/views/home/home_view.dart';
import 'package:yana/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),

        // 1. Configuración de Dio Base (para endpoints que no requieren token, ej. login, register, status)
        Provider<Dio>(
          create: (_) => Dio(BaseOptions(
            // baseUrl: 'http://10.0.2.2:5000', // ¡AJUSTA ESTA URL!
            baseUrl: 'https://yana-gestorvehicular.onrender.com', // ¡AJUSTA ESTA URL!
            contentType: Headers.jsonContentType,
          )),
          dispose: (_, dio) => dio.close(),
        ),

        // 2. Configuración de Dio Autenticado (con interceptor para token)
        // Este Dio se usará para todas las llamadas que requieran autenticación
        // (ej. VehiculoService y AuthService.validateToken si lo usa).
        // Aquí es donde añadimos el interceptor para el token.
        // También podemos añadir un interceptor para manejar 401s globales.
        ProxyProvider<SharedPreferences, Dio>(
          update: (_, prefs, previousDio) {
            final authenticatedDio = Dio(BaseOptions(
              // baseUrl: 'http://10.0.2.2:5000', // ¡AJUSTA ESTA URL!
              baseUrl: 'https://yana-gestorvehicular.onrender.com', // ¡AJUSTA ESTA URL!
              contentType: Headers.jsonContentType,
            ));

            authenticatedDio.interceptors.add(InterceptorsWrapper(
              onRequest: (options, handler) async {
                final token = prefs.getString('accessToken');
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                return handler.next(options);
              },
              onError: (DioException e, handler) async {
                // Si el error es 401 (Unauthorized) y no estamos ya intentando autenticar/auto-login
                // y no estamos en la ruta de login/register (para evitar bucles)
                if (e.response?.statusCode == 401) {
                  // No intentes obtener el AuthProvider aquí directamente con BuildContext
                  // El AuthProvider ya debe manejar el 401 en `tryAutoLogin` o `login`.
                  // Si el token expira durante otra llamada (ej. a /api/vehiculos),
                  // Dio lanzará la excepción, y si el AuthProvider no maneja ese 401
                  // de forma global (lo cual es complejo), la UI mostrará el error
                  // de esa llamada específica, o el usuario tendrá que intentar de nuevo
                  // y el `tryAutoLogin` del siguiente inicio ya fallará.
                  // La mejor práctica es que el AuthProvider tenga un método para
                  // invalidar el token si *otras* partes de la app lo reportan,
                  // o confiar en que `tryAutoLogin` detecte la expiración.

                  // Por ahora, eliminamos la línea problemática para evitar el error de tipo.
                  // El flujo de `AuthProvider.tryAutoLogin()` y `AuthProvider.login()`
                  // ya debería ser suficiente para manejar el 401.
                  print('Error 401 detectado por Dio interceptor. Probablemente token expirado o inválido.');
                  // Aquí no hacemos un logout directo para no acoplar el Dio interceptor al AuthProvider.
                  // Dejamos que el error se propague para que el manejador de la llamada (el provider, etc.) lo reciba.
                }
                return handler.next(e);
              },
            ));
            return authenticatedDio;
          },
          dispose: (_, dio) => dio.close(),
        ),

        // 3. AuthService - Usa la instancia base de Dio
        Provider<AuthService>(
          create: (context) => AuthService(context.read<Dio>()),
        ),

        // 4. AuthRepository - Depende de AuthService.
        Provider<AuthRepository>(
          create: (context) => AuthRepository(context.read<AuthService>()),
        ),

        // 5. AuthProvider - Depende de AuthRepository y SharedPreferences (gestionadas internamente)
        ChangeNotifierProvider(
          create: (context) {
            final authRepo = context.read<AuthRepository>();
            final authProvider = AuthProvider(authRepo);
            authProvider.tryAutoLogin(); // Intenta auto-login al inicio
            authProvider.startApiReachabilityCheck(); // Inicia la verificación de conectividad
            return authProvider;
          },
          lazy: false, // ¡IMPORTANTE! Asegura que AuthProvider se inicialice inmediatamente.
        ),

        // 6. VehiculoService - Usa la instancia *autenticada* de Dio
        ProxyProvider<Dio, VehiculoService>( // Cambié a ProxyProvider solo de Dio, ya que el token lo maneja el interceptor
          update: (_, authenticatedDio, previousVehiculoService) {
            return VehiculoService(authenticatedDio); // Pasa el Dio autenticado
          },
        ),

        // 7. VehiculoRepository - Depende de VehiculoService.
        Provider<VehiculoRepository>(
          create: (context) => VehiculoRepository(context.read<VehiculoService>()),
        ),

        // 8. VehiculoProvider - Depende de VehiculoRepository
        ChangeNotifierProxyProvider<AuthProvider, VehiculoProvider>(
          create: (context) {
            return VehiculoProvider(context.read<VehiculoRepository>());
          },
          update: (context, authProvider, previousVehiculoProvider) {
            final vehiculoRepo = context.read<VehiculoRepository>();
            if (previousVehiculoProvider == null) {
              return VehiculoProvider(vehiculoRepo);
            }
            // Si el usuario se desloguea, limpia la lista de vehículos.
            if (authProvider.status == AuthStatus.unauthenticated || authProvider.status == AuthStatus.error) {
              previousVehiculoProvider.clearVehiculos();
            }
            previousVehiculoProvider.updateRepository(vehiculoRepo);
            return previousVehiculoProvider;
          },
        ),
        // --- Nuevos Proveedores para Mantenimiento ---
        // Proveedor para MantenimientoService
        Provider<MantenimientoService>(
          create: (context) => MantenimientoService(
            Provider.of<Dio>(context, listen: false), // Usa la misma instancia de Dio
          ),
        ),
        // Proveedor para MantenimientoRepository
        Provider<MantenimientoRepository>(
          create: (context) => MantenimientoRepository(
            Provider.of<MantenimientoService>(context, listen: false),
          ),
        ),
        // Proveedor para MantenimientoProvider (ChangeNotifier)
        ChangeNotifierProvider<MantenimientoProvider>(
          create: (context) => MantenimientoProvider(
            Provider.of<MantenimientoRepository>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    Widget homeScreen;
    switch (auth.status) {
      case AuthStatus.authenticated:
        homeScreen = const HomeView();
        break;
      case AuthStatus.authenticating:
        homeScreen = const SplashScreen();
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.uninitialized:
      default:
        homeScreen = const LoginView();
        break;
    }

    return MaterialApp(
      title: 'Yana App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return Stack(
            children: [
              homeScreen,
              const ApiStatusIndicator(),
            ],
          );
        },
      ),
    );
  }
}

class ApiStatusIndicator extends StatelessWidget {
  const ApiStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    Color indicatorColor;
    if (auth.isApiReachable) {
      indicatorColor = Colors.green;
    } else {
      indicatorColor = Colors.red;
    }

    final bool showIndicator = auth.status != AuthStatus.authenticating;

    if (!showIndicator) {
      return const SizedBox.shrink();
    }

    return Positioned(
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
    );
  }
}