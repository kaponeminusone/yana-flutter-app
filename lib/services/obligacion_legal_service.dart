// lib/services/obligacion_legal_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obligacion_legal_model.dart';
import 'dart:developer';
import 'dart:io';

class ObligacionLegalService {
  final Dio _dio;

  ObligacionLegalService(this._dio) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        log('Dio Request: ${options.method} ${options.path}');
        log('Dio Headers: ${options.headers}');

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

  // *** NUEVO MÉTODO PARA OBTENER TODAS LAS OBLIGACIONES ***
  Future<List<ObligacionLegalModel>> getTodasObligacionesLegales() async {
    try {
      final response = await _dio.get('/api/obligacionesL'); // Llama a la ruta general
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ObligacionLegalModel.fromJson(json))
            .toList();
      } else {
        // Esto captura casos donde la API no devuelve una lista, incluso si el status es 200
        throw Exception('Respuesta inesperada: se esperaba una lista de obligaciones, pero se recibió: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de red o del servidor al obtener todas las obligaciones: ';
      if (e.response != null) {
        errorMessage += 'Código ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Mensaje desconocido'}';
        if (e.response?.data is Map && e.response?.data.containsKey('message')) {
            errorMessage += ' - ${e.response?.data['message']}';
        } else if (e.response?.data is String) {
            errorMessage += ' - ${e.response?.data}'; // En caso de HTML de error, al menos muestra el contenido
        }
      } else {
        errorMessage += e.message ?? 'Error de conexión desconocido.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error inesperado al obtener todas las obligaciones legales: $e');
    }
  }

  // *** MODIFICADO: Ahora este método llama al anterior y filtra ***
  Future<List<ObligacionLegalModel>> getObligacionesByVehiculoId(String vehiculoId) async {
    log('ObligacionLegalService: Fetching all obligations to filter by vehiculoId: $vehiculoId');
    try {
      final allObligations = await getTodasObligacionesLegales(); // Llama al nuevo método
      final filteredObligations = allObligations.where((o) => o.vehiculoId == vehiculoId).toList();
      log('ObligacionLegalService: Found ${filteredObligations.length} obligations for vehiculoId: $vehiculoId');
      return filteredObligations;
    } catch (e) {
      log('ObligacionLegalService: Error filtering obligations: $e');
      // Re-lanza la excepción tal como se recibió de getTodasObligacionesLegales
      throw e;
    }
  }

  // Resto de métodos (getById, create, update, delete) permanecen igual
  Future<ObligacionLegalModel> getObligacionLegalById(String id) async {
    try {
      final response = await _dio.get('/api/obligacionesL/$id');
      // Asegúrate de que el backend devuelve un objeto simple para una sola obligación
      if (response.data is Map<String, dynamic>) {
        return ObligacionLegalModel.fromJson(response.data);
      } else {
        throw Exception('Respuesta inesperada del servidor al obtener obligación por ID: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de red o del servidor al obtener obligación legal por ID: ';
      if (e.response != null) {
        errorMessage += 'Código ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Mensaje desconocido'}';
        if (e.response?.data is Map && e.response?.data.containsKey('message')) {
            errorMessage += ' - ${e.response?.data['message']}';
        } else if (e.response?.data is String) {
            errorMessage += ' - ${e.response?.data}';
        }
      } else {
        errorMessage += e.message ?? 'Error de conexión desconocido.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error inesperado al obtener obligación legal por ID: $e');
    }
  }

  Future<ObligacionLegalModel> createObligacionLegal(Map<String, dynamic> data, {String? filePath}) async {
    try {
      FormData formData = FormData.fromMap(data);
      if (filePath != null) {
        formData.files.add(MapEntry(
          "archivo",
          await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
        ));
      }

      final response = await _dio.post('/api/obligacionesL', data: formData);
      // El backend podría devolver { message: "...", obligacion: {...} }
      // Asegúrate de extraer el objeto de la obligación si es el caso
      if (response.data is Map && response.data.containsKey('obligacion')) {
        return ObligacionLegalModel.fromJson(response.data['obligacion']);
      }
      return ObligacionLegalModel.fromJson(response.data); // Asume que el JSON raíz es la obligación
    } on DioException catch (e) {
      String errorMessage = 'Error de red o del servidor al crear obligación legal: ';
      if (e.response != null) {
        errorMessage += 'Código ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Mensaje desconocido'}';
        if (e.response?.data is Map && e.response?.data.containsKey('message')) {
            errorMessage += ' - ${e.response?.data['message']}';
        } else if (e.response?.data is String) {
            errorMessage += ' - ${e.response?.data}';
        }
      } else {
        errorMessage += e.message ?? 'Error de conexión desconocido.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error inesperado al crear obligación legal: $e');
    }
  }

  Future<ObligacionLegalModel> updateObligacionLegal(String id, Map<String, dynamic> data, {String? filePath}) async {
    try {
      Response response;

      if (filePath != null) {
        FormData formData = FormData.fromMap(data);
        formData.files.add(MapEntry(
          "archivo",
          await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
        ));
        response = await _dio.put('/api/obligacionesL/$id', data: formData);
      } else {
        response = await _dio.put('/api/obligacionesL/$id', data: data);
      }

      // Tu backend devuelve {message, obligacion} para el PUT,
      // así que accedemos a 'obligacion'
      if (response.data is Map && response.data.containsKey('obligacion')) {
        return ObligacionLegalModel.fromJson(response.data['obligacion']);
      }
      // En caso de que el backend solo devuelva la obligación directamente
      return ObligacionLegalModel.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage = 'Error de red o del servidor al actualizar obligación legal: ';
      if (e.response != null) {
        errorMessage += 'Código ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Mensaje desconocido'}';
        if (e.response?.data is Map && e.response?.data.containsKey('message')) {
            errorMessage += ' - ${e.response?.data['message']}';
        } else if (e.response?.data is String) {
            errorMessage += ' - ${e.response?.data}';
        }
      } else {
        errorMessage += e.message ?? 'Error de conexión desconocido.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error inesperado al actualizar obligación legal: $e');
    }
  }

  Future<void> deleteObligacionLegal(String id) async {
    try {
      await _dio.delete('/api/obligacionesL/$id');
    } on DioException catch (e) {
      String errorMessage = 'Error de red o del servidor al eliminar obligación legal: ';
      if (e.response != null) {
        errorMessage += 'Código ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Mensaje desconocido'}';
        if (e.response?.data is Map && e.response?.data.containsKey('message')) {
            errorMessage += ' - ${e.response?.data['message']}';
        } else if (e.response?.data is String) {
            errorMessage += ' - ${e.response?.data}';
        }
      } else {
        errorMessage += e.message ?? 'Error de conexión desconocido.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error inesperado al eliminar obligación legal: $e');
    }
  }
}