// lib/services/mantenimiento_service.dart
import 'package:dio/dio.dart';
import '../models/mantenimiento_model.dart';

class MantenimientoService {
  final Dio _dio;

  MantenimientoService(this._dio);

  // Helper para construir FormData
  Future<FormData> _buildFormData(Map<String, dynamic> data, MultipartFile? facturaFile) async {
    final formData = FormData.fromMap(data);
    if (facturaFile != null) {
      formData.files.add(MapEntry('factura', facturaFile)); // 'factura' es el nombre del campo que el backend espera para el archivo
    }
    return formData;
  }

  Future<MantenimientoModel> createMantenimiento(
      Map<String, dynamic> data, {MultipartFile? facturaFile}) async { // Cambiado a MultipartFile
    try {
      Response resp;
      if (facturaFile != null) {
        // Si hay una factura, enviamos todo como FormData
        final formData = await _buildFormData(data, facturaFile);
        resp = await _dio.post('/api/mantenimientos', data: formData);
      } else {
        // Si no hay factura, enviamos como JSON
        resp = await _dio.post('/api/mantenimientos', data: data);
      }

      print('Respuesta de la API al crear mantenimiento: ${resp.data}');

      if (resp.statusCode == 201) {
        if (resp.data is Map<String, dynamic> && resp.data.containsKey('mantenimiento')) {
          final dynamic mantenimientoData = resp.data['mantenimiento'];
          if (mantenimientoData is Map<String, dynamic>) {
            return MantenimientoModel.fromJson(mantenimientoData);
          } else {
            throw 'Formato de respuesta inesperado: El objeto "mantenimiento" no es un mapa válido.';
          }
        } else {
          throw 'Formato de respuesta inesperado: No se encontró el objeto "mantenimiento" o el formato es incorrecto.';
        }
      } else {
        throw 'Error inesperado del servidor al crear mantenimiento: Estado ${resp.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al crear mantenimiento.')
            : 'Error de servidor al crear mantenimiento.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al crear mantenimiento: $e';
    }
  }

  Future<MantenimientoModel> updateMantenimiento(
      String id, Map<String, dynamic> data, {MultipartFile? facturaFile}) async { // Cambiado a MultipartFile
    try {
      Response resp;
      if (facturaFile != null) {
        // Si hay una factura, enviamos todo como FormData
        final formData = await _buildFormData(data, facturaFile);
        resp = await _dio.put('/api/mantenimientos/$id', data: formData);
      } else {
        // Si no hay factura, enviamos como JSON
        resp = await _dio.put('/api/mantenimientos/$id', data: data);
      }
      print('Respuesta de la API al actualizar mantenimiento: ${resp.data}');

      if (resp.statusCode == 200) {
        if (resp.data is Map<String, dynamic> && resp.data.containsKey('mantenimiento')) {
          final dynamic mantenimientoData = resp.data['mantenimiento'];
          if (mantenimientoData is Map<String, dynamic>) {
            return MantenimientoModel.fromJson(mantenimientoData);
          } else {
            throw 'Formato de respuesta inesperado: El objeto "mantenimiento" no es un mapa válido.';
          }
        } else {
          throw 'Formato de respuesta inesperado: No se encontró el objeto "mantenimiento" o el formato es incorrecto.';
        }
      } else {
        throw 'Error inesperado del servidor al actualizar mantenimiento: Estado ${resp.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al actualizar mantenimiento.')
            : 'Error de servidor al actualizar mantenimiento.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al actualizar mantenimiento: $e';
    }
  }

  Future<List<MantenimientoModel>> fetchMantenimientos() async {
    try {
      final resp = await _dio.get('/api/mantenimientos');
      if (resp.statusCode == 200) { // Asegurarse de verificar el status code
        if (resp.data is List<dynamic>) {
          final list = resp.data as List<dynamic>;
          return list.map((j) {
            if (j is Map<String, dynamic>) {
              return MantenimientoModel.fromJson(j);
            } else {
              print('Advertencia: Elemento de mantenimiento no es un mapa válido: $j');
              throw 'Elemento de lista de mantenimientos con formato incorrecto.';
            }
          }).toList();
        } else {
          throw 'Formato de respuesta inesperado: Se esperaba una lista de mantenimientos.';
        }
      } else {
        throw 'Error inesperado del servidor al obtener mantenimientos: Estado ${resp.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al obtener mantenimientos.')
            : 'Error de servidor al obtener mantenimientos.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al obtener mantenimientos: $e';
    }
  }

  Future<MantenimientoModel> fetchMantenimientoById(String id) async {
    try {
      final resp = await _dio.get('/api/mantenimientos/$id');
      if (resp.statusCode == 200) { // Asegurarse de verificar el status code
        if (resp.data is Map<String, dynamic>) {
          return MantenimientoModel.fromJson(resp.data as Map<String, dynamic>);
        } else {
          throw 'Formato de respuesta inesperado: Se esperaba un objeto de mantenimiento.';
        }
      } else {
        throw 'Error inesperado del servidor al obtener mantenimiento por ID: Estado ${resp.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al obtener mantenimiento por ID.')
            : 'Error de servidor al obtener mantenimiento por ID.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al obtener mantenimiento por ID: $e';
    }
  }

  Future<void> deleteMantenimiento(String id) async {
    try {
      final resp = await _dio.delete('/api/mantenimientos/$id');
      if (resp.statusCode != 204 && resp.statusCode != 200) { // Un 204 No Content o 200 OK
        throw 'Error inesperado del servidor al eliminar mantenimiento: Estado ${resp.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al eliminar mantenimiento.')
            : 'Error de servidor al eliminar mantenimiento.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al eliminar mantenimiento: $e';
    }
  }
}