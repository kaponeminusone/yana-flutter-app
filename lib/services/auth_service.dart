// lib/services/auth_service.dart (Asegúrate de que este archivo exista)
import 'package:dio/dio.dart';
import 'package:yana/repository/auth_repository.dart';
import '../models/propietario_model.dart'; // Importa tu modelo de propietario

class AuthService {
  final Dio _dio;

  AuthService(this._dio); // El constructor ahora recibe un Dio

  // Para login, el Dio no debe tener un token de auth si el token aún no existe
  Future<AuthResponse> login(String correo, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'correo': correo,
        'password': password,
      });
      final accessToken = response.data['accessToken'] as String;
      final propietario = PropietarioModel.fromJson(response.data['propietario'] as Map<String, dynamic>);
      return AuthResponse(accessToken: accessToken, propietario: propietario);
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al iniciar sesión.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al iniciar sesión: $e';
    }
  }

  Future<void> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    try {
      await _dio.post('/api/auth/register', data: {
        'nombre': nombre,
        'identificacion': identificacion,
        'correo': correo,
        'password': password,
        'celular': celular,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al registrarse.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al registrarse: $e';
    }
  }

  Future<bool> checkApiStatus() async {
    try {
      await _dio.get('/api/status'); // Un endpoint simple para verificar conectividad
      return true;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  // ¡NUEVO MÉTODO! Para validar el token con el backend
  // Asume que este _dio tiene el interceptor para añadir el token automáticamente.
  // Si no, deberías pasarlo manualmente en los headers para este método.
  Future<PropietarioModel> validateToken(String token) async {
    try {
      // Necesitas un Dio configurado con el token para esta llamada
      // O puedes pasarlo manualmente aquí:
      final response = await _dio.get(
        '/api/auth/validate', // o '/api/auth/me' o similar
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PropietarioModel.fromJson(response.data['propietario'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        // Token inválido o expirado
        throw 'Token inválido o expirado. Por favor, inicie sesión de nuevo.';
      }
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error al validar el token.';
      } else {
        throw 'Error de conexión al validar token: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al validar token: $e';
    }
  }
}