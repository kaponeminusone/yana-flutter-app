import 'package:dio/dio.dart';
import '../models/mantenimiento_model.dart';

class MantenimientoService {
  final Dio _dio;

  // Constructor que recibe la instancia de Dio configurada.
  MantenimientoService(this._dio);

  Future<MantenimientoModel> createMantenimiento(
      Map<String, dynamic> data, FormData? facturaFormData) async {
    try {
      Response resp;
      if (facturaFormData != null) {
        // Cuando hay archivo, se envía FormData
        resp = await _dio.post('/api/mantenimientos', data: facturaFormData);
      } else {
        // Cuando no hay archivo, se envía JSON normal
        resp = await _dio.post('/api/mantenimientos', data: data);
      }
      return MantenimientoModel.fromJson(resp.data['mantenimiento'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        // Si hay una respuesta del servidor, intenta obtener el mensaje de error
        throw e.response?.data['message'] ?? 'Error de servidor al crear mantenimiento.';
      } else {
        // Error sin respuesta del servidor (ej. problemas de red)
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al crear mantenimiento: $e';
    }
  }

  Future<List<MantenimientoModel>> fetchMantenimientos() async {
    try {
      final resp = await _dio.get('/api/mantenimientos');
      // El backend devuelve una lista directa
      final list = resp.data as List<dynamic>;
      return list.map((j) => MantenimientoModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al obtener mantenimientos.';
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
      return MantenimientoModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al obtener mantenimiento por ID.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al obtener mantenimiento por ID: $e';
    }
  }

  Future<MantenimientoModel> updateMantenimiento(
      String id, Map<String, dynamic> data, FormData? facturaFormData) async {
    try {
      Response resp;
      if (facturaFormData != null) {
        // Cuando hay archivo, se envía FormData
        resp = await _dio.put('/api/mantenimientos/$id', data: facturaFormData);
      } else {
        // Cuando no hay archivo, se envía JSON normal
        resp = await _dio.put('/api/mantenimientos/$id', data: data);
      }
      return MantenimientoModel.fromJson(resp.data['mantenimiento'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al actualizar mantenimiento.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al actualizar mantenimiento: $e';
    }
  }

  Future<void> deleteMantenimiento(String id) async {
    try {
      await _dio.delete('/api/mantenimientos/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al eliminar mantenimiento.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al eliminar mantenimiento: $e';
    }
  }
}