// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:yana/models/propietario_model.dart'; // Importa tu modelo de propietario
import 'package:yana/models/auth_response.dart'; // Importa AuthResponse

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

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
        throw 'Error de conexión: ${e.message ?? 'No se pudo conectar al servidor.'}';
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
        throw 'Error de conexión: ${e.message ?? 'No se pudo conectar al servidor.'}';
      }
    } catch (e) {
      throw 'Error inesperado al registrarse: $e';
    }
  }

  // --- Implementación de checkApiStatus() usando /api/reportes/automaticos ---
  Future<bool> checkApiStatus() async {
    return true;
    try {
      
      // Usamos el endpoint '/api/reportes/automaticos' que no requiere autenticación
      // y está documentado como "Solo para visualización".
      final response = await _dio.get(
        '/api/reportes/automaticos',
        options: Options(
          sendTimeout: const Duration(seconds: 5), // Límite de tiempo para enviar la petición
          receiveTimeout: const Duration(seconds: 5), // Límite de tiempo para recibir la respuesta
        ),
      );
      // Consideramos que la API es alcanzable si el status code es 200 OK
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Cualquier DioException (ej. connectionError, timeout, badResponse)
      // significa que la API no es alcanzable o no respondió correctamente.
      print('AuthService: Error al verificar estado de la API: ${e.message ?? e.toString()}'); // Mejorar el log
      return false;
    } catch (e) {
      // Otros errores inesperados
      print('AuthService: Error inesperado al verificar estado de la API: $e');
      return false;
    }
  }

  Future<PropietarioModel> validateToken(String token) async {
    try {
      // Si el Dio que se inyecta aquí (AuthService(this._dio)) NO tiene un interceptor
      // que añada automáticamente el token, entonces DEBES descomentar la siguiente línea:
      final response = await _dio.get('/api/auth/validate', options: Options(headers: {'Authorization': 'Bearer $token'}));
      // De lo contrario, si tu Dio ya está configurado con un interceptor global para tokens,
      // la línea de abajo es suficiente:
      // final response = await _dio.get('/api/auth/validate'); // Si el Dio ya maneja el token via interceptor

      return PropietarioModel.fromJson(response.data['propietario'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw 'Sesión expirada o token inválido. Por favor, inicie sesión de nuevo.';
      }
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error al validar el token.';
      } else {
        throw 'Error de conexión al validar token: ${e.message ?? 'No se pudo conectar al servidor.'}';
      }
    } catch (e) {
      throw 'Error inesperado al validar token: $e';
    }
  }
}