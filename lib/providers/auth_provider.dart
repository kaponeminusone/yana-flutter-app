// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:dio/dio.dart'; // Importa Dio para capturar DioException

import '../models/propietario_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { uninitialized, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  PropietarioModel? _user;
  String? _errorMessage;

  bool _isApiReachable = true; // Estado inicial: se asume que la API es alcanzable

  Timer? _apiCheckTimer;

  AuthProvider(this._repo);

  AuthStatus get status => _status;
  PropietarioModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  bool get isApiReachable => _isApiReachable;

  bool get isAuthenticated => _token != null && _user != null && _status == AuthStatus.authenticated;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Inicia la verificación periódica de la API
  void startApiReachabilityCheck() {
    _apiCheckTimer?.cancel(); // Cancela cualquier timer existente
    // Ejecuta la verificación inmediatamente y luego cada 10 segundos
    _checkApiReachability();
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkApiReachability();
    });
  }

  // Detiene la verificación periódica de la API
  void stopApiReachabilityCheck() {
    _apiCheckTimer?.cancel();
    _apiCheckTimer = null;
  }

  @override
  void dispose() {
    stopApiReachabilityCheck(); // Asegura que el timer se cancele al disponer el provider
    super.dispose();
  }

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    // Verifica la accesibilidad de la API antes de intentar registrar
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para registrarse. Verifique su conexión.';
      _status = AuthStatus.unauthenticated; // Opcional: poner en unauthenticated o error
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating; // Temporalmente a authenticating para indicar actividad
    _errorMessage = null; // Limpia mensajes de error previos
    notifyListeners();
    try {
      await _repo.register(
        nombre: nombre,
        identificacion: identificacion,
        correo: correo,
        password: password,
        celular: celular,
      );
      // Si el registro es exitoso, el usuario aún no está logueado,
      // solo registrado. Lo dejamos en unauthenticated para que vaya a la pantalla de login.
      _status = AuthStatus.unauthenticated;
      _errorMessage = null; // Asegura que no haya error si el registro fue OK
    } catch (e) {
      // Las excepciones lanzadas por el servicio ya son Strings, se asignan directamente
      _errorMessage = e.toString();
      _status = AuthStatus.error; // Si hay un error de registro, el estado es error
    }
    notifyListeners();
  }

  Future<void> login({
    required String correo,
    required String password,
  }) async {
    // Verifica la accesibilidad de la API antes de intentar loguearse
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para iniciar sesión. Verifique su conexión.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating; // Temporalmente a authenticating
    _errorMessage = null;
    notifyListeners();
    try {
      final resp = await _repo.login(correo: correo, password: password);
      _token = resp.accessToken;
      _user = resp.propietario;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _token!);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      // Las excepciones lanzadas por el servicio ya son Strings, se asignan directamente
      _errorMessage = e.toString();
      _status = AuthStatus.error; // Error en login (credenciales inválidas, etc.)
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _user = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken'); // Elimina el token guardado
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null; // Limpia cualquier mensaje de error anterior
    notifyListeners();

    await _checkApiReachability(); // Primero verifica la conectividad
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para auto-login. Intente más tarde.';
      _status = AuthStatus.unauthenticated; // Si no hay conexión, no se puede auto-loguear
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('accessToken');

    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        // Intenta validar el token con el backend
        _user = await _repo.validateToken(savedToken);
        _token = savedToken; // Si la validación fue exitosa, el token es válido
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } catch (e) {
        // Si validateToken lanza una excepción (token inválido/expirado, etc.)
        _errorMessage = e.toString();
        _status = AuthStatus.unauthenticated; // Regresa a no autenticado si el auto-login falla
        await logout(); // Fuerza el logout para limpiar token inválido/expirado
      }
    } else {
      // No hay token guardado o está vacío
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    }
    notifyListeners();
  }

  // Método interno para verificar la accesibilidad de la API
  Future<void> _checkApiReachability() async {
    final reachable = await _repo.checkApiReachability();
    if (_isApiReachable != reachable) {
      _isApiReachable = reachable;
      if (!reachable) {
        print('La API no es alcanzable.');
      } else {
        print('La API es alcanzable.');
      }
      notifyListeners(); // Notifica a los listeners si el estado de reachability cambia
    }
  }
}