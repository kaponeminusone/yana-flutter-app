// lib/repository/auth_repository.dart

import 'package:yana/models/propietario_model.dart';

import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;
  AuthRepository(this._service);

  // NUEVO: Método para verificar si la API es alcanzable
  Future<bool> checkApiReachability() => _service.pingApi();

  Future<RegisterResponse> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) =>
      _service.register(
        nombre: nombre,
        identificacion: identificacion,
        correo: correo,
        password: password,
        celular: celular,
      );

  Future<LoginResponse> login({
    required String correo,
    required String password,
  }) =>
      _service.login(correo: correo, password: password);
}