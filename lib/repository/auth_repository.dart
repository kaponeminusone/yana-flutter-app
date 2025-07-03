// lib/repository/auth_repository.dart
import '../models/propietario_model.dart';
import '../models/auth_response.dart'; // Asegúrate de importar AuthResponse
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

  // ¡MÉTODO para validar el token con el backend!
  Future<PropietarioModel> validateToken(String token) async {
    return await _service.validateToken(token);
  }

  // --- Implementación de checkApiReachability() ---
  Future<bool> checkApiReachability() async {
    try {
      // Delega la lógica de la petición HTTP al AuthService
      return await _service.checkApiStatus();
    } catch (e) {
      // Si por alguna razón el AuthService lanza un error (que no debería si está bien manejado),
      // lo capturamos aquí para asegurar que siempre retornemos un booleano.
      print('AuthRepository: Error inesperado al verificar la API: $e'); // Para depuración
      return false;
    }
  }
}