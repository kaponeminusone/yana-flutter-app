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

  bool _isApiReachable = true;

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

  void startApiReachabilityCheck() {
    _apiCheckTimer?.cancel();
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkApiReachability();
    });
    _checkApiReachability();
  }

  void stopApiReachabilityCheck() {
    _apiCheckTimer?.cancel();
    _apiCheckTimer = null;
  }

  @override
  void dispose() {
    stopApiReachabilityCheck();
    super.dispose();
  }

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para registrarse.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.register(
        nombre: nombre,
        identificacion: identificacion,
        correo: correo,
        password: password,
        celular: celular,
      );
      _status = AuthStatus.unauthenticated; // Después del registro, el usuario aún no está autenticado
      _errorMessage = null;
    } catch (e) {
      // Captura de excepciones más específica para DioException
      if (e is DioException) {
        _errorMessage = e.response?.data['message'] ?? 'Error de registro.';
      } else {
        _errorMessage = e.toString();
      }
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> login({
    required String correo,
    required String password,
  }) async {
    await _checkApiReachability();
    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor para iniciar sesión.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating;
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
    } on DioException catch (e) {
      // ¡Aquí es donde manejas el 401 del login!
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Credenciales inválidas. Por favor, verifica tu correo y contraseña.';
      } else {
        _errorMessage = e.response?.data['message'] ?? 'Error al iniciar sesión.';
      }
      _status = AuthStatus.error; // Se pone en error si las credenciales son incorrectas
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _user = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    await _checkApiReachability();

    if (!_isApiReachable) {
      _errorMessage = 'No se puede conectar al servidor. Intente más tarde.';
      _status = AuthStatus.unauthenticated; // Va a unauthenticated si no hay conexión
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
      } on DioException catch (e) {
        // Si el token es inválido o expirado (401/403)
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          _errorMessage = 'Sesión expirada o token inválido. Por favor, inicie sesión de nuevo.';
          await logout(); // Fuerza el logout
        } else {
          // Otro tipo de error al validar (ej. 500, red, etc.)
          _errorMessage = e.response?.data['message'] ?? 'Error al validar sesión.';
          _status = AuthStatus.error;
        }
      } catch (e) {
        _errorMessage = e.toString();
        _status = AuthStatus.error;
      }
    } else {
      // No hay token guardado o está vacío
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> _checkApiReachability() async {
    final reachable = await _repo.checkApiReachability();
    if (_isApiReachable != reachable) {
      _isApiReachable = reachable;
      if (!reachable) {
        print('La API no es alcanzable.');
      } else {
        print('La API es alcanzable.');
      }
      notifyListeners();
    }
  }
}