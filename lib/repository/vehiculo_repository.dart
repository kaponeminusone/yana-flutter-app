// lib/repository/vehiculo_repository.dart
import '../models/vehiculo_model.dart';
import '../services/vehiculo_service.dart';

class VehiculoRepository {
  final VehiculoService _service;
  VehiculoRepository(this._service);

  Future<VehiculoModel> createVehiculo(Map<String, dynamic> data) =>
      _service.createVehiculo(data);

  // ¡AQUÍ ESTÁ EL CAMBIO! Ahora se llama 'fetchVehiculos'
  Future<List<VehiculoModel>> fetchVehiculos() => _service.fetchVehiculos();

  Future<VehiculoModel> getVehiculo(String id) => _service.fetchVehiculoById(id);
  Future<VehiculoModel> updateVehiculo(String id, Map<String, dynamic> data) =>
      _service.updateVehiculo(id, data);
  Future<void> deleteVehiculo(String id) => _service.deleteVehiculo(id);
}