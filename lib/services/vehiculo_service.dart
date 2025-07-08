// lib/services/vehiculo_service.dart
import 'package:dio/dio.dart';
import '../models/vehiculo_model.dart';

class VehiculoService {
  final Dio _dio;

  VehiculoService(this._dio);

  Future<VehiculoModel> createVehiculo(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.post('/api/vehiculos', data: data);
      // *** CAMBIO AQUÍ: Eliminar ['vehiculo'] ***
      return VehiculoModel.fromJson((resp.data as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al crear vehículo.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al crear vehículo: $e';
    }
  }

  Future<List<VehiculoModel>> fetchVehiculos() async {
    try {
      final resp = await _dio.get('/api/vehiculos');
      final list = resp.data as List<dynamic>;
      return list.map((j) => VehiculoModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al obtener vehículos.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al obtener vehículos: $e';
    }
  }

  Future<VehiculoModel> fetchVehiculoById(String id) async {
    try {
      final resp = await _dio.get('/api/vehiculos/$id');
      return VehiculoModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al obtener vehículo por ID.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al obtener vehículo por ID: $e';
    }
  }

  Future<VehiculoModel> updateVehiculo(String id, Map<String, dynamic> data) async {
    try {
      final resp = await _dio.put('/api/vehiculos/$id', data: data);
      // *** CAMBIO AQUÍ: Eliminar ['vehiculo'] ***
      return VehiculoModel.fromJson((resp.data as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al actualizar vehículo.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al actualizar vehículo: $e';
    }
  }

  Future<void> deleteVehiculo(String id) async {
    try {
      await _dio.delete('/api/vehiculos/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Error de servidor al eliminar vehículo.';
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al eliminar vehículo: $e';
    }
  }
}