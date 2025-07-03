import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Necesario para FormData
import '../models/mantenimiento_model.dart';
import '../repository/mantenimiento_repository.dart';

enum MantenimientoStatus { idle, loading, success, error }

class MantenimientoProvider extends ChangeNotifier {
  MantenimientoRepository _repo; // Ahora no es final para poder actualizarlo
  List<MantenimientoModel> _mantenimientos = [];
  String? _errorMessage;
  MantenimientoStatus _status = MantenimientoStatus.idle;

  MantenimientoProvider(this._repo);

  List<MantenimientoModel> get mantenimientos => _mantenimientos;
  String? get errorMessage => _errorMessage;
  MantenimientoStatus get status => _status;
  bool get isLoading => _status == MantenimientoStatus.loading; // Atajo

  // Método para actualizar el repositorio (útil si el token cambia)
  void updateRepository(MantenimientoRepository newRepo) {
    if (_repo != newRepo) {
      _repo = newRepo;
      // Opcional: podrías querer volver a cargar los mantenimientos
      // si el cambio de repositorio implica un cambio de contexto (ej. nuevo usuario logueado)
      // fetchMantenimientos(); // Considera cuándo es apropiado llamar esto
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    if (_status == MantenimientoStatus.error) {
      _status = MantenimientoStatus.idle; // Vuelve a idle después de limpiar el error
    }
    notifyListeners();
  }

  void clearMantenimientos() {
    _mantenimientos = [];
    _errorMessage = null;
    _status = MantenimientoStatus.idle;
    notifyListeners();
  }

  Future<void> fetchMantenimientos() async {
    if (_status == MantenimientoStatus.loading) return;

    _status = MantenimientoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _mantenimientos = await _repo.fetchMantenimientos();
      _status = MantenimientoStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _mantenimientos = []; // Limpiar si hay error
      _status = MantenimientoStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> createMantenimiento(
      Map<String, dynamic> data, {FormData? factura}) async {
    _status = MantenimientoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final newMantenimiento = await _repo.createMantenimiento(data, factura: factura);
      _mantenimientos.add(newMantenimiento);
      _status = MantenimientoStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MantenimientoStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateMantenimiento(
      String id, Map<String, dynamic> data, {FormData? factura}) async {
    _status = MantenimientoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedMantenimiento = await _repo.updateMantenimiento(id, data, factura: factura);
      int index = _mantenimientos.indexWhere((m) => m.id == id);
      if (index != -1) {
        _mantenimientos[index] = updatedMantenimiento;
      }
      _status = MantenimientoStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MantenimientoStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteMantenimiento(String id) async {
    _status = MantenimientoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.deleteMantenimiento(id);
      _mantenimientos.removeWhere((m) => m.id == id);
      _status = MantenimientoStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MantenimientoStatus.error;
    } finally {
      notifyListeners();
    }
  }
}