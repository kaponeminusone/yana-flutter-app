// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:yana/models/propietario_model.dart';

class AuthService {
  final Dio _dio;
  // Asegúrate de que esta sea la URL base de tu API
  final String _baseUrl = 'http://10.0.2.2:5000/api/auth'; // Para emulador Android
  // final String _baseUrl = 'http://localhost:5000/api/auth'; // Para iOS Simulator o Web

  AuthService([Dio? dio]) : _dio = dio ?? Dio();

  // NUEVO: Método para hacer un "ping" a la API
  Future<bool> pingApi() async {
    try {
      // Intenta hacer una petición GET muy ligera, por ejemplo, a la URL base
      // Si tu API tiene un endpoint de /health o /status, úsalo en su lugar.
      // Por ahora, solo intentaremos la URL base.
      await _dio.get(_baseUrl, options: Options(
        sendTimeout: const Duration(seconds: 5), // Límite de tiempo para el envío
        receiveTimeout: const Duration(seconds: 5), // Límite de tiempo para la recepción
      ));
      return true; // La API es alcanzable
    } on DioException catch (e) {
      // Captura errores específicos de Dio, como problemas de conexión, timeouts, etc.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        print('Error de conexión a la API: ${e.message}');
        return false; // No se pudo conectar a la API
      }
      // Otros tipos de errores Dio (ej. 404, 500) aún significan que se llegó a la API
      // pero la respuesta no fue la esperada para este ping.
      print('Otro tipo de error Dio al hacer ping a la API: ${e.message}');
      return true; // Consideramos que la API es alcanzable, pero el endpoint de ping falló
    } catch (e) {
      // Captura cualquier otro error inesperado
      print('Error inesperado al hacer ping a la API: $e');
      return false; // Error desconocido, asumimos no alcanzable
    }
  }

  Future<RegisterResponse> register({
    required String nombre,
    required String identificacion,
    required String correo,
    required String password,
    required String celular,
  }) async {
    final resp = await _dio.post(
      '$_baseUrl/register',
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'nombre': nombre,
        'identificacion': identificacion,
        'correo': correo,
        'password': password,
        'celular': celular,
      },
    );
    return RegisterResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<LoginResponse> login({
    required String correo,
    required String password,
  }) async {
    final resp = await _dio.post(
      '$_baseUrl/login',
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'correo': correo,
        'password': password,
      },
    );
    return LoginResponse.fromJson(resp.data as Map<String, dynamic>);
  }
}