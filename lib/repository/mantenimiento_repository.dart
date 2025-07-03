import 'package:dio/dio.dart'; // Necesario para FormData
import '../models/mantenimiento_model.dart';
import '../services/mantenimiento_service.dart';

class MantenimientoRepository {
  final MantenimientoService _service;

  MantenimientoRepository(this._service);

  Future<MantenimientoModel> createMantenimiento(
          Map<String, dynamic> data, {FormData? factura}) =>
      _service.createMantenimiento(data, factura);

  Future<List<MantenimientoModel>> fetchMantenimientos() =>
      _service.fetchMantenimientos();

  Future<MantenimientoModel> fetchMantenimiento(String id) =>
      _service.fetchMantenimientoById(id);

  Future<MantenimientoModel> updateMantenimiento(
          String id, Map<String, dynamic> data, {FormData? factura}) =>
      _service.updateMantenimiento(id, data, factura);

  Future<void> deleteMantenimiento(String id) =>
      _service.deleteMantenimiento(id);
}