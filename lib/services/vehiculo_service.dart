
// lib/services/vehiculo_service.dart
import 'package:dio/dio.dart';
import '../models/vehiculo_model.dart';
import 'dart:developer'; // Import for log
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class VehiculoService {
  final Dio _dio;

  VehiculoService(this._dio);

  Future<VehiculoModel> createVehiculo(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.post('/api/vehiculos', data: data);
      final VehiculoModel newVehiculo = VehiculoModel.fromJson((resp.data as Map<String, dynamic>));
      if (kDebugMode) {
        log('VehiculoService: Vehículo creado en el servidor: ${newVehiculo.id}');
      }
      return newVehiculo;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Error de servidor al crear vehículo.';
        if (kDebugMode) {
          log('VehiculoService: DioError al crear vehículo: ${e.response?.statusCode} - $errorMessage');
        }
        throw errorMessage;
      } else {
        final errorMessage = 'Error de conexión al crear vehículo: ${e.message}';
        if (kDebugMode) {
          log('VehiculoService: DioError de conexión al crear vehículo: $errorMessage');
        }
        throw errorMessage;
      }
    } catch (e) {
      final errorMessage = 'Error inesperado al crear vehículo: $e';
      if (kDebugMode) {
        log('VehiculoService: Error inesperado al crear vehículo: $errorMessage');
      }
      throw errorMessage;
    }
  }

  Future<List<VehiculoModel>> fetchVehiculos() async {
    try {
      final resp = await _dio.get('/api/vehiculos');
      final list = resp.data as List<dynamic>;
      final List<VehiculoModel> vehiculos = list.map((j) => VehiculoModel.fromJson(j as Map<String, dynamic>)).toList();
      if (kDebugMode) {
        log('VehiculoService: Vehículos obtenidos del servidor. Cantidad: ${vehiculos.length}');
      }
      return vehiculos;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Error de servidor al obtener vehículos.';
        if (kDebugMode) {
          log('VehiculoService: DioError al obtener vehículos: ${e.response?.statusCode} - $errorMessage');
        }
        throw errorMessage;
      } else {
        final errorMessage = 'Error de conexión al obtener vehículos: ${e.message}';
        if (kDebugMode) {
          log('VehiculoService: DioError de conexión al obtener vehículos: $errorMessage');
        }
        throw errorMessage;
      }
    } catch (e) {
      final errorMessage = 'Error inesperado al obtener vehículos: $e';
      if (kDebugMode) {
        log('VehiculoService: Error inesperado al obtener vehículos: $errorMessage');
      }
      throw errorMessage;
    }
  }

  Future<VehiculoModel> fetchVehiculoById(String id) async {
    try {
      final resp = await _dio.get('/api/vehiculos/$id');
      final VehiculoModel vehiculo = VehiculoModel.fromJson(resp.data as Map<String, dynamic>);
      if (kDebugMode) {
        log('VehiculoService: Vehículo obtenido por ID $id: ${vehiculo.marca} ${vehiculo.modelo}');
      }
      return vehiculo;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Error de servidor al obtener vehículo por ID.';
        if (kDebugMode) {
          log('VehiculoService: DioError al obtener vehículo por ID $id: ${e.response?.statusCode} - $errorMessage');
        }
        throw errorMessage;
      } else {
        final errorMessage = 'Error de conexión al obtener vehículo por ID: ${e.message}';
        if (kDebugMode) {
          log('VehiculoService: DioError de conexión al obtener vehículo por ID: $errorMessage');
        }
        throw errorMessage;
      }
    } catch (e) {
      final errorMessage = 'Error inesperado al obtener vehículo por ID: $e';
      if (kDebugMode) {
        log('VehiculoService: Error inesperado al obtener vehículo por ID: $errorMessage');
      }
      throw errorMessage;
    }
  }

  Future<VehiculoModel> updateVehiculo(String id, Map<String, dynamic> data) async {
    try {
      final resp = await _dio.put('/api/vehiculos/$id', data: data);
      final VehiculoModel updatedVehiculo = VehiculoModel.fromJson((resp.data as Map<String, dynamic>));
      if (kDebugMode) {
        log('VehiculoService: Vehículo actualizado en el servidor con ID $id: ${updatedVehiculo.marca} ${updatedVehiculo.modelo}');
      }
      return updatedVehiculo;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Error de servidor al actualizar vehículo.';
        if (kDebugMode) {
          log('VehiculoService: DioError al actualizar vehículo $id: ${e.response?.statusCode} - $errorMessage');
        }
        throw errorMessage;
      } else {
        final errorMessage = 'Error de conexión al actualizar vehículo: ${e.message}';
        if (kDebugMode) {
          log('VehiculoService: DioError de conexión al actualizar vehículo: $errorMessage');
        }
        throw errorMessage;
      }
    } catch (e) {
      final errorMessage = 'Error inesperado al actualizar vehículo: $e';
      if (kDebugMode) {
        log('VehiculoService: Error inesperado al actualizar vehículo: $errorMessage');
      }
      throw errorMessage;
    }
  }

  Future<void> deleteVehiculo(String id) async {
    try {
      if (kDebugMode) {
        log('VehiculoService: Enviando solicitud de eliminación para vehículo con ID: $id');
      }
      await _dio.delete('/api/vehiculos/$id');
      if (kDebugMode) {
        log('VehiculoService: Solicitud de eliminación exitosa para ID: $id');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Error de servidor al eliminar vehículo.';
        if (kDebugMode) {
          log('VehiculoService: DioError al eliminar vehículo $id: ${e.response?.statusCode} - $errorMessage');
        }
        throw errorMessage;
      } else {
        final errorMessage = 'Error de conexión al eliminar vehículo: ${e.message}';
        if (kDebugMode) {
          log('VehiculoService: DioError de conexión al eliminar vehículo $id: $errorMessage');
        }
        throw errorMessage;
      }
    } catch (e) {
      final errorMessage = 'Error inesperado al eliminar vehículo: $e';
      if (kDebugMode) {
        log('VehiculoService: Error inesperado al eliminar vehículo $id: $errorMessage');
      }
      throw errorMessage;
    }
  }
}