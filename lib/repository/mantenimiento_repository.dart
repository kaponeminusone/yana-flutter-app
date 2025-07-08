// lib/repository/mantenimiento_repository.dart
import 'package:dio/dio.dart'; // Necesario para MultipartFile
import '../models/mantenimiento_model.dart';
import '../services/mantenimiento_service.dart';

class MantenimientoRepository {
  final MantenimientoService _service;

  MantenimientoRepository(this._service);

  Future<MantenimientoModel> createMantenimiento(
      Map<String, dynamic> data, {MultipartFile? facturaFile}) async { // Cambiado a MultipartFile
    return _service.createMantenimiento(data, facturaFile: facturaFile);
  }

  Future<List<MantenimientoModel>> fetchMantenimientos() =>
      _service.fetchMantenimientos();

  Future<MantenimientoModel> fetchMantenimiento(String id) =>
      _service.fetchMantenimientoById(id);

  Future<MantenimientoModel> updateMantenimiento(
      String id, Map<String, dynamic> data, {MultipartFile? facturaFile}) async { // Cambiado a MultipartFile
    return _service.updateMantenimiento(id, data, facturaFile: facturaFile);
  }

  Future<void> deleteMantenimiento(String id) =>
      _service.deleteMantenimiento(id);
}