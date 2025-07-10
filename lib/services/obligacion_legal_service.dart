// lib/services/obligacion_legal_service.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/obligacion_legal_model.dart';

class ObligacionLegalService {
  final Dio _dio;
  ObligacionLegalService(this._dio);

  // --- MODIFIED METHOD: Now fetches ALL legal obligations ---
  Future<List<ObligacionLegalModel>> getAllObligacionesLegal() async {
    try {
      // Se elimina el queryParameter 'vehiculoId' ya que este endpoint trae todo
      final response = await _dio.get(
        '/api/obligacionesL',
      );

      print('[log] GET /api/obligacionesL (all obligations) → ${response.statusCode}');
      // Opcional: print('[log] Data: ${response.data}'); // Puede ser mucha data

      if (response.statusCode == 200) {
        // Asumiendo que la respuesta es una lista de objetos JSON
        final List<dynamic> data = response.data;
        // Forzamos la conversión a List<Map<String, dynamic>>
        final List<Map<String, dynamic>> listaJson = List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map)),
        );
        return listaJson
            .map((json) => ObligacionLegalModel.fromJson(json))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch all obligations with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al obtener todas las obligaciones: ';
      if (e.response != null) {
        errorMessage += 'Servidor: ${e.response?.statusCode} - ${e.response?.statusMessage ?? 'Error desconocido'}.';
        if (e.response?.data != null) {
          errorMessage += ' Detalles: ${e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data) : e.response?.data}';
        }
      } else {
        errorMessage += 'Error de red: ${e.message ?? 'No se pudo conectar al servidor.'}';
      }
      print('[log] ObligacionLegalService: ERROR al obtener todas las obligaciones: $errorMessage');
      throw Exception('Error al obtener todas las obligaciones: $errorMessage');
    } catch (e) {
      print('[log] ObligacionLegalService: ERROR inesperado al obtener todas las obligaciones: ${e.toString()}');
      throw Exception('Error inesperado al obtener todas las obligaciones: ${e.toString()}');
    }
  }

  // --- EXISTING METHOD for creating obligation with file (no changes needed) ---
  Future<ObligacionLegalModel> createObligacionLegal(Map<String, dynamic> data, {PlatformFile? file}) async {
    try {
      final formData = FormData.fromMap(data);

      if (file != null && file.path != null) {
        formData.files.add(MapEntry(
          'documento', // Este debe ser el nombre del campo que tu backend espera para el archivo
          await MultipartFile.fromFile(file.path!, filename: file.name),
        ));
        print('DEBUG: Archivo adjunto para creación: ${file.name}, tamaño: ${file.size} bytes');
      } else {
        print('DEBUG: No se adjuntó ningún archivo para la creación o el archivo no tiene una ruta válida.');
      }

      final response = await _dio.post(
        '/api/obligacionesL', // Asegúrate de que esta sea la URL correcta para crear
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data', // Importante para enviar archivos
          },
        ),
      );

      print('[log] Dio Response: POST /api/obligacionesL');
      print('[log] Dio Status Code: ${response.statusCode}');
      print('[log] Dio Response Data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Asumiendo que el backend devuelve la obligación creada
        return ObligacionLegalModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to create obligation with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al crear obligación legal: ';
      if (e.response != null) {
        errorMessage += 'Servidor: ${e.response?.statusCode} - ${e.response?.statusMessage ?? 'Error desconocido'}.';
        if (e.response?.data != null) {
          errorMessage += ' Detalles: ${e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data) : e.response?.data}';
        }
      } else {
        errorMessage += 'Error de red: ${e.message ?? 'No se pudo conectar al servidor.'}';
      }
      print('[log] ObligacionLegalService: ERROR al crear obligación legal: $errorMessage');
      throw Exception('Error al crear obligación legal: $errorMessage');
    } catch (e) {
      print('[log] ObligacionLegalService: ERROR inesperado al crear obligación legal: ${e.toString()}');
      throw Exception('Error inesperado al crear obligación legal: ${e.toString()}');
    }
  }
}