// lib/repository/auth_repository.dart (Asegúrate de que este archivo exista)
import '../models/propietario_model.dart';
import '../services/auth_service.dart'; // Asume que tienes un auth_service.dart

class AuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  Future<AuthResponse> login({required String correo, required String password}) async {
    return await _service.login(correo, password);
  }

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    await _service.register(
      nombre: nombre,
      identificacion: identificacion,
      correo: correo,
      password: password,
      celular: celular,
    );
  }

  Future<bool> checkApiReachability() async {
    return await _service.checkApiStatus();
  }

  // ¡NUEVO MÉTODO! Para validar el token con el backend
  Future<PropietarioModel> validateToken(String token) async {
    return await _service.validateToken(token);
  }
}

class AuthResponse {
  final String accessToken;
  final PropietarioModel propietario;

  AuthResponse({required this.accessToken, required this.propietario});
}