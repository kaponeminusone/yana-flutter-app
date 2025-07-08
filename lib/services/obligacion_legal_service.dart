// lib/services/obligacion_legal_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necesario para obtener el token
import '../models/obligacion_legal_model.dart';
import 'dart:developer'; // Importar para usar log
import 'dart:io'; // Necesario para la clase File

class ObligacionLegalService {
  final Dio _dio;

  ObligacionLegalService(this._dio) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Añadir el token de autenticación
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        log('Dio Request: ${options.method} ${options.path}');
        log('Dio Headers: ${options.headers}');

        // Depuración mejorada para FormData
        if (options.data is FormData) {
          FormData formData = options.data as FormData;
          log('Dio FormData Fields: ${formData.fields.map((f) => '${f.key}: ${f.value}')}');
          log('Dio FormData Files: ${formData.files.map((e) => 'Key: ${e.key}, Filename: ${e.value.filename}, ContentType: ${e.value.contentType}')}');
        } else {
          log('Dio Request Data: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('Dio Response: ${response.requestOptions.method} ${response.requestOptions.path}');
        log('Dio Status Code: ${response.statusCode}');
        log('Dio Response Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        log('Dio Error: ${e.requestOptions.method} ${e.requestOptions.path}');
        log('Dio Error Type: ${e.type}');
        log('Dio Error Message: ${e.message}');
        if (e.response != null) {
          log('Dio Error Response Status: ${e.response?.statusCode}');
          log('Dio Error Response Data: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));
  }

  Future<List<ObligacionLegalModel>> getObligacionesByVehiculoId(String vehiculoId) async {
    try {
      final response = await _dio.get('/api/obligacionesL/vehiculo/$vehiculoId');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ObligacionLegalModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Respuesta inesperada del servidor al obtener obligaciones: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.statusMessage}');
      } else {
        throw Exception('Error de red al obtener obligaciones legales: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener obligaciones legales del vehículo: $e');
    }
  }

  Future<ObligacionLegalModel> getObligacionLegalById(String id) async {
    try {
      final response = await _dio.get('/api/obligacionesL/$id');
      return ObligacionLegalModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.statusMessage}');
      } else {
        throw Exception('Error de red al obtener obligación legal por ID: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener obligación legal por ID: $e');
    }
  }

  Future<ObligacionLegalModel> createObligacionLegal(Map<String, dynamic> data, {String? filePath}) async {
    try {
      FormData formData = FormData.fromMap(data);
      if (filePath != null) {
        formData.files.add(MapEntry(
          // *** CORRECCIÓN CRÍTICA AQUÍ: Cambiado de "file" a "archivo" ***
          "archivo", // ¡Debe coincidir con el nombre del campo en tu middleware Multer en el backend!
          await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
        ));
      }

      final response = await _dio.post('/api/obligacionesL', data: formData);
      return ObligacionLegalModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.statusMessage}');
      } else {
        throw Exception('Error de red al crear obligación legal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al crear obligación legal: $e');
    }
  }

  Future<ObligacionLegalModel> updateObligacionLegal(String id, Map<String, dynamic> data, {String? filePath}) async {
    try {
      Response response;

      // Si hay un archivo para subir, usamos FormData
      if (filePath != null) {
        FormData formData = FormData.fromMap(data);
        formData.files.add(MapEntry(
          // *** CORRECCIÓN CRÍTICA AQUÍ: Cambiado de "file" a "archivo" ***
          "archivo", // ¡Debe coincidir con el nombre del campo en tu middleware Multer en el backend!
          await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
        ));
        response = await _dio.put('/api/obligacionesL/$id', data: formData);
      } else {
        // Si no hay archivo nuevo, pero `data` incluye `archivoPath: null`
        // significa que queremos borrar el archivo existente.
        // En este caso, enviamos `data` directamente como JSON, ya que no hay file a subir.
        // Esto permite que el backend reciba `archivoPath: null` y lo procese.
        response = await _dio.put('/api/obligacionesL/$id', data: data);
      }

      // Tu backend devuelve {message, obligacion} para el PUT,
      // así que accedemos a 'obligacion'
      return ObligacionLegalModel.fromJson(response.data['obligacion']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.statusMessage}');
      } else {
        throw Exception('Error de red al actualizar obligación legal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al actualizar obligación legal: $e');
    }
  }

  Future<void> deleteObligacionLegal(String id) async {
    try {
      await _dio.delete('/api/obligacionesL/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.statusMessage}');
      } else {
        throw Exception('Error de red al eliminar obligación legal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al eliminar obligación legal: $e');
    }
  }
}