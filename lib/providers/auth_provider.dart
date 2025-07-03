// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/propietario_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { uninitialized, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  PropietarioModel? _user;
  String? _errorMessage;

  bool _isApiReachable = true;

  AuthProvider(this._repo);

  AuthStatus get status => _status;
  PropietarioModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  bool get isApiReachable => _isApiReachable;

  // NUEVO: Método para limpiar el mensaje de error
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
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
      _status = AuthStatus.error;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final resp = await _repo.register(
        nombre: nombre,
        identificacion: identificacion,
        correo: correo,
        password: password,
        celular: celular,
      );
      // Tras un registro exitoso, normalmente no hay token todavía,
      // la idea es que el usuario ahora inicie sesión.
      _status = AuthStatus.uninitialized; // Vuelve a uninitialized para que LoginView sepa que es exitoso
      _errorMessage = null; // Limpiar mensaje de error si fue exitoso
    } catch (e) {
      _errorMessage = e.toString();
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
      _status = AuthStatus.error;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final resp = await _repo.login(correo: correo, password: password);
      _token = resp.accessToken;
      _user = resp.propietario;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _token!);
      _status = AuthStatus.authenticated;
      _errorMessage = null; // Limpiar mensaje de error
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AuthStatus.uninitialized;
    _token = null;
    _user = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    await _checkApiReachability();

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('accessToken');
    if (saved != null) {
      _token = saved;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.uninitialized;
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