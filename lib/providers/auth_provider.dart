// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:dio/dio.dart'; // Importa Dio para capturar DioException

import '../models/propietario_model.dart';
import '../repository/auth_repository.dart';

// Definición de los estados de autenticación
enum AuthStatus { uninitialized, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  PropietarioModel? _user;
  String? _errorMessage; // Mensaje de error para mostrar en la UI

  bool _isApiReachable = true; // Estado para la accesibilidad de la API

  Timer? _apiCheckTimer; // Timer para la verificación periódica de la API

  AuthProvider(this._repo);

  // Getters para acceder al estado desde los widgets
  AuthStatus get status => _status;
  PropietarioModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isApiReachable => _isApiReachable;

  // Verifica si el usuario está autenticado (tiene token y usuario)
  bool get isAuthenticated => _token != null && _user != null && _status == AuthStatus.authenticated;

  // Método para limpiar el mensaje de error (llamado después de mostrarlo)
  void clearErrorMessage() {
    _errorMessage = null;
    //print('AuthProvider: Error message cleared.'); // Depuración
    notifyListeners(); // Notifica a la UI que el mensaje de error se ha limpiado
  }

  // Inicia la verificación periódica de la API
  void startApiReachabilityCheck() {
    _apiCheckTimer?.cancel(); // Cancela cualquier timer existente
    _checkApiReachability(); // Ejecuta la verificación inmediatamente
    // Configura un timer para ejecutar la verificación cada 10 segundos
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkApiReachability();
    });
    //print('AuthProvider: API reachability check started.'); // Depuración
  }

  // Detiene la verificación periódica de la API
  void stopApiReachabilityCheck() {
    _apiCheckTimer?.cancel();
    _apiCheckTimer = null;
    //print('AuthProvider: API reachability check stopped.'); // Depuración
  }

  @override
  void dispose() {
    stopApiReachabilityCheck(); // Asegura que el timer se cancele al disponer el provider
    super.dispose();
    //print('AuthProvider: Disposed.'); // Depuración
  }

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    // 1. Verificar la accesibilidad de la API
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para registrarse. Verifique su conexión.';
      _status = AuthStatus.error; // Establece el estado a error si la API no es alcanzable
      //print('AuthProvider: Register failed - API unreachable. Error: $_errorMessage'); // Depuración
      notifyListeners();
      return;
    }

    // 2. Preparar para el registro
    _status = AuthStatus.authenticating; // Establece el estado a autenticando para mostrar carga
    _errorMessage = null; // Limpia cualquier mensaje de error previo
    //print('AuthProvider: Attempting registration for $correo...'); // Depuración
    notifyListeners(); // Notifica a la UI (ej. para mostrar un spinner)

    // 3. Intentar el registro
    try {
      await _repo.register(
        nombre: nombre,
        identificacion: identificacion,
        correo: correo,
        password: password,
        celular: celular,
      );
      // Si el registro es exitoso, el usuario aún no está logueado.
      // Lo dejamos en unauthenticated para que el usuario proceda al login.
      _status = AuthStatus.unauthenticated;
      _errorMessage = null; // Asegura que no haya error si el registro fue OK
      //print('AuthProvider: Registration successful, status: $_status'); // Depuración
    } catch (e) {
      // 4. Manejo de errores en el registro
      // Las excepciones lanzadas por el servicio ya son Strings con el mensaje del backend
      _errorMessage = e.toString();
      _status = AuthStatus.error; // Establece el estado a error
      //print('AuthProvider: Registration failed. Error: $_errorMessage, status: $_status'); // Depuración
    } finally {
      // 5. Notificar a los listeners sobre el resultado final (éxito o error)
      notifyListeners();
    }
  }

  Future<void> login({
    required String correo,
    required String password,
  }) async {
    // 1. Verificar la accesibilidad de la API
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para iniciar sesión. Verifique su conexión.';
      _status = AuthStatus.error; // Establece el estado a error si la API no es alcanzable
      //print('AuthProvider: Login failed - API unreachable. Error: $_errorMessage'); // Depuración
      notifyListeners();
      return;
    }

    // 2. Preparar para el login
    _status = AuthStatus.authenticating; // Establece el estado a autenticando para mostrar carga
    _errorMessage = null; // Limpia cualquier mensaje de error previo
    //print('AuthProvider: Attempting login for $correo...'); // Depuración
    notifyListeners(); // Notifica a la UI (ej. para mostrar un spinner)

    // 3. Intentar el login
    try {
      final resp = await _repo.login(correo: correo, password: password);
      _token = resp.accessToken;
      _user = resp.propietario;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _token!);
      _status = AuthStatus.authenticated; // Establece el estado a autenticado
      _errorMessage = null; // Limpia el mensaje de error si el login es exitoso
      //print('AuthProvider: Login successful! User: ${_user?.correo}, status: $_status'); // Depuración
    } catch (e) {
      // 4. Manejo de errores en el login
      // Las excepciones lanzadas por el servicio (AuthService) ya son Strings con el mensaje relevante.
      _errorMessage = e.toString(); // Asigna el mensaje de error
      _status = AuthStatus.error; // Establece el estado a error
      //print('AuthProvider: Login failed. Error: $_errorMessage, status: $_status'); // Depuración
    } finally {
      // 5. Notificar a los listeners sobre el resultado final (éxito o error)
      // ESTE notifyListeners() ES CRÍTICO y debe estar aquí para que la UI reaccione al error.
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _user = null;
    _errorMessage = null; // Asegura que no haya mensaje de error al desloguearse
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken'); // Elimina el token guardado localmente
    //print('AuthProvider: User logged out. Status: $_status'); // Depuración
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    // 1. Preparar para el auto-login
    _status = AuthStatus.authenticating; // Temporalmente a autenticando para indicar carga
    _errorMessage = null; // Limpia cualquier mensaje de error previo
    //print('AuthProvider: Attempting auto-login...'); // Depuración
    notifyListeners(); // Notifica a la UI (ej. para el SplashScreen)

    // 2. Verificar la accesibilidad de la API
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para auto-login. Intente más tarde.';
      _status = AuthStatus.unauthenticated; // Si no hay conexión, no se puede auto-loguear
      //print('AuthProvider: API unreachable for auto-login. Status: $_status, Error: $_errorMessage'); // Depuración
      notifyListeners();
      return;
    }

    // 3. Intentar auto-login con token guardado
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('accessToken');

    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        // Intenta validar el token con el backend
        _user = await _repo.validateToken(savedToken);
        _token = savedToken; // Si la validación fue exitosa, el token es válido
        _status = AuthStatus.authenticated;
        _errorMessage = null; // Limpia el error si el auto-login es exitoso
        // //print('AuthProvider: Auto-login successful. User: ${_user?.correo}, status: $_status'); // Depuración
      } catch (e) {
        // 4. Manejo de errores en auto-login (token inválido/expirado, etc.)
        _errorMessage = e.toString(); // Asigna el mensaje de error
        // //print('AuthProvider: Auto-login failed. Error: $_errorMessage'); // Depuración
        // Pequeño retardo para que el SplashScreen sea visible por un momento
        await Future.delayed(const Duration(seconds: 1));
        _status = AuthStatus.unauthenticated; // Regresa a no autenticado si el auto-login falla
        await logout(); // Fuerza el logout para limpiar cualquier token inválido/expirado localmente
        // //print('AuthProvider: Forced logout after auto-login failure. Status: $_status'); // Depuración
      }
    } else {
      // 5. No hay token guardado o está vacío
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      //print('AuthProvider: No saved token found. Status: $_status'); // Depuración
    }
    notifyListeners(); // Notifica a los listeners sobre el resultado final del auto-login
  }

  // Método interno para verificar la accesibilidad de la API
  Future<void> _checkApiReachability() async {
    final reachable = await _repo.checkApiReachability();
    if (_isApiReachable != reachable) {
      _isApiReachable = reachable;
      if (!reachable) {
        // print('Auth provider: API status changed to NOT REACHABLE.'); // Depuración más específica
      } else {
        // print('Auth provider: API status changed to REACHABLE.'); // Depuración más específica
      }
      notifyListeners(); // Notifica a los listeners si el estado de reachability cambia
    }
  }
}