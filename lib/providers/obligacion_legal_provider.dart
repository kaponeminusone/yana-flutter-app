import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/obligacion_legal_model.dart';
import '../services/obligacion_legal_service.dart';

class ObligacionLegalProvider extends ChangeNotifier {
  final ObligacionLegalService _obligacionLegalService;
  List<ObligacionLegalModel> _obligaciones = [];
  bool _isLoading = false;
  String? _errorMessage;

  ObligacionLegalProvider(this._obligacionLegalService);

  List<ObligacionLegalModel> get obligaciones => _obligaciones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchObligacionesByVehiculoId(String vehiculoId) async {
    log('ObligacionLegalProvider: Iniciando fetchObligacionesByVehiculoId para vehiculoId: $vehiculoId'); // DEBUG PRINT 1
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _obligaciones = await _obligacionLegalService.getObligacionesByVehiculoId(vehiculoId);
      log('ObligacionLegalProvider: Obligaciones cargadas exitosamente. Cantidad: ${_obligaciones.length}'); // DEBUG PRINT 2
    } catch (e) {
      _errorMessage = 'Exception: Error al obtener obligaciones legales del vehículo: ${e.toString()}';
      _obligaciones = []; // Limpiar datos anteriores en caso de error
      log('ObligacionLegalProvider: ERROR al cargar obligaciones: $_errorMessage'); // DEBUG PRINT 3
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ObligacionLegalModel?> createObligacionLegal(Map<String, dynamic> data, {String? filePath}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newObligacion = await _obligacionLegalService.createObligacionLegal(data, filePath: filePath);
      // No es necesario añadir a la lista aquí, vuelve a cargar después del éxito o navega de vuelta
      return newObligacion;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ObligacionLegalModel?> updateObligacionLegal(String id, Map<String, dynamic> data, {String? filePath}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedObligacion = await _obligacionLegalService.updateObligacionLegal(id, data, filePath: filePath);
      // No es necesario actualizar la lista aquí, vuelve a cargar después del éxito o navega de vuelta
      return updatedObligacion;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObligacionLegal(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _obligacionLegalService.deleteObligacionLegal(id);
      // Eliminar de la lista actual si fue cargada para un vehículo específico
      _obligaciones.removeWhere((obligacion) => obligacion.id == id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}