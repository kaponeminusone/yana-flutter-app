// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Quita la importación de connectivity_plus si la tenías
// import 'package:connectivity_plus/connectivity_plus.dart'; 

import '../models/propietario_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { uninitialized, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  PropietarioModel? _user;
  String? _errorMessage;

  // NUEVO: Estado de la alcanzabilidad de la API
  bool _isApiReachable = true; // Asumimos true por defecto hasta que se compruebe

  AuthProvider(this._repo);

  AuthStatus get status => _status;
  PropietarioModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  // NUEVO: Getter para saber si la API es alcanzable
  bool get isApiReachable => _isApiReachable;

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    // NUEVO: Verificar si la API es alcanzable antes de registrar
    await _checkApiReachability(); // Actualiza _isApiReachable
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
      _status = AuthStatus.uninitialized; // O auto-login, como lo tengas
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
    // NUEVO: Verificar si la API es alcanzable antes de iniciar sesión
    await _checkApiReachability(); // Actualiza _isApiReachable
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
    _errorMessage = null; // Limpiar mensaje de error
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    notifyListeners();
  }

  /// Al inicio de la app, cargar token si existe
  Future<void> tryAutoLogin() async {
    // NUEVO: Verificar alcanzabilidad de la API al inicio
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

  // NUEVO: Método privado para verificar si la API es alcanzable
  Future<void> _checkApiReachability() async {
    final reachable = await _repo.checkApiReachability();
    if (_isApiReachable != reachable) { // Solo notificar si el estado cambia
      _isApiReachable = reachable;
      if (!reachable) {
        print('La API no es alcanzable.'); // Para depuración
      } else {
        print('La API es alcanzable.'); // Para depuración
      }
      notifyListeners(); // Notifica el cambio de estado de alcanzabilidad
    }
  }

  // Opcional: Si quieres un monitoreo en tiempo real, deberías implementar
  // un Listener de PeriodicTimer o similar que llame a _checkApiReachability
  // cada cierto tiempo, pero eso sería un cambio más grande y no lo pediste.
}