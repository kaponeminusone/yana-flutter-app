// lib/providers/vehiculo_provider.dart
import 'package:flutter/material.dart';
import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/repository/vehiculo_repository.dart';
import 'dart:developer'; // Import for log
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class VehiculoProvider extends ChangeNotifier {
  VehiculoRepository _repo;
  List<VehiculoModel> _vehiculos = [];
  String? _errorMessage;
  bool _isLoading = false;

  VehiculoProvider(this._repo);

  List<VehiculoModel> get vehiculos => _vehiculos;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void updateRepository(VehiculoRepository newRepo) {
    if (_repo != newRepo) {
      _repo = newRepo;
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearVehiculos() {
    _vehiculos = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVehiculos() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _vehiculos = await _repo.fetchVehiculos();
      if (kDebugMode) {
        log('VehiculoProvider: Vehículos cargados exitosamente. Cantidad: ${_vehiculos.length}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _vehiculos = []; // Limpiar si hay error
      if (kDebugMode) {
        log('VehiculoProvider: Error al cargar vehículos: $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createVehiculo(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newVehiculo = await _repo.createVehiculo(data);
      _vehiculos.add(newVehiculo);
      if (kDebugMode) {
        log('VehiculoProvider: Vehículo creado exitosamente: ${newVehiculo.marca} ${newVehiculo.modelo}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        log('VehiculoProvider: Error al crear vehículo: $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVehiculo(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedVehiculo = await _repo.updateVehiculo(id, data);
      int index = _vehiculos.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehiculos[index] = updatedVehiculo;
        if (kDebugMode) {
          log('VehiculoProvider: Vehículo actualizado exitosamente: ${updatedVehiculo.marca} ${updatedVehiculo.modelo}');
        }
      } else {
        if (kDebugMode) {
          log('VehiculoProvider: Vehículo con ID $id no encontrado para actualizar en la lista local.');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        log('VehiculoProvider: Error al actualizar vehículo $id: $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MODIFIED deleteVehiculo method
  Future<bool> deleteVehiculo(String id) async {
    bool success = false; // Track success of deletion
    _isLoading = true; // Set loading true
    _errorMessage = null; // Clear previous error messages
    notifyListeners(); // Notify UI about loading state

    if (kDebugMode) {
      log('VehiculoProvider: Intentando eliminar vehículo con ID: $id');
    }

    try {
      await _repo.deleteVehiculo(id);
      final beforeCount = _vehiculos.length;
      _vehiculos.removeWhere((v) => v.id == id); // Remove from local list ONLY ON SUCCESS
      final afterCount = _vehiculos.length;
      success = true; // Mark as successful
      if (kDebugMode) {
        if (beforeCount > afterCount) {
          log('VehiculoProvider: Vehículo con ID: $id eliminado exitosamente del backend y de la lista local.');
        } else {
          log('VehiculoProvider: Vehículo con ID: $id eliminado del backend, pero no encontrado en la lista local (ya eliminado o ID incorrecto).');
        }
      }
    } catch (e) {
      _errorMessage = e.toString(); // Set error message on failure
      success = false; // Ensure success is false on error
      if (kDebugMode) {
        log('VehiculoProvider: Error al eliminar vehículo con ID $id: $_errorMessage');
      }
      // Do NOT remove from local list if deletion failed on backend
    } finally {
      _isLoading = false; // Always stop loading
      notifyListeners(); // Notify UI about final state (success or error)
    }
    return success; // Return success status
  }
}
