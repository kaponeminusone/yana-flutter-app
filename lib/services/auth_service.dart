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
        // MUY IMPORTANTE: Asegúrate de que tu backend envíe un 'message' claro en caso de credenciales incorrectas (generalmente 401).
        // Por ejemplo, si el backend responde con status 401 y body {"message": "Correo o contraseña incorrectos"}
        throw e.response?.data['message'] ?? 'Error de servidor al iniciar sesión. Código: ${e.response?.statusCode}';
      } else {
        throw 'Error de conexión: No se pudo conectar al servidor. Verifique su internet.';
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
        throw e.response?.data['message'] ?? 'Error de servidor al registrarse. Código: ${e.response?.statusCode}';
      } else {
        throw 'Error de conexión: No se pudo conectar al servidor para registrarse. Verifique su internet.';
      }
    } catch (e) {
      throw 'Error inesperado al registrarse: $e';
    }
  }

  // --- IMPLEMENTACIÓN DE checkApiStatus() USANDO UN ENDPOINT CONOCIDO COMO /api/auth/login ---
  Future<bool> checkApiStatus() async {
    try {
      // Intentamos hacer un GET a la ruta base de la API.
      // Si tu backend tiene una ruta '/' o '/api' que devuelve algo, úsala.
      // Si no, incluso un 404 aquí significaría que el servidor está activo.
      final response = await _dio.get(
        '/', // <--- CAMBIO AQUÍ: Probamos la ruta base.
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) {
            // Aceptamos 2xx (éxito), 400 (Bad Request), 401 (Unauthorized),
            // 404 (Not Found), 405 (Method Not Allowed) como una señal de que el servidor responde.
            return status != null &&
                   (status >= 200 && status < 300 ||
                    status == 400 ||
                    status == 401 ||
                    status == 404 || // <--- ACEPTAMOS 404
                    status == 405);
          },
        ),
      );
      // Si llegamos aquí, el servidor respondió con un estado que consideramos "activo".
      return true;
    } on DioException catch (e) {
      // Capturamos 5xx (Internal Server Error) o errores de red.
      print('AuthService: Error al verificar estado de la API: ${e.message ?? e.toString()}');
      return false;
    } catch (e) {
      print('AuthService: Error inesperado al verificar estado de la API: $e');
      return false;
    }
  }

  Future<PropietarioModel> validateToken(String token) async {
    try {
      final response = await _dio.get(
        '/api/auth/validate',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PropietarioModel.fromJson(response.data['propietario'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw e.response?.data['message'] ?? 'Sesión expirada o token inválido. Por favor, inicie sesión de nuevo.';
        }
        throw e.response?.data['message'] ?? 'Error al validar el token. Código: ${e.response?.statusCode}';
      } else {
        throw 'Error de conexión al validar token: No se pudo conectar al servidor. Verifique su internet.';
      }
    } catch (e) {
      throw 'Error inesperado al validar token: $e';
    }
  }
}