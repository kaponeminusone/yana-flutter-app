// lib/providers/obligacion_legal_provider.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import for PlatformFile
import '../models/obligacion_legal_model.dart';
import '../services/obligacion_legal_service.dart'; // Make sure this path is correct

class ObligacionLegalProvider with ChangeNotifier {
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

  // --- MODIFIED METHOD: Now fetches ALL and filters locally ---
  Future<void> fetchObligacionesByVehiculoId(String targetVehiculoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch ALL obligations from the backend using the service
      //    (assuming ObligacionLegalService now has a method like getAllObligacionesLegal)
      //    Note: You must ensure your ObligacionLegalService has this method and
      //    it calls the /api/obligacionesL endpoint.
      final List<ObligacionLegalModel> allObligations =
          await _obligacionLegalService.getAllObligacionesLegal();
      print('[log] ObligacionLegalProvider: Se cargaron ${allObligations.length} obligaciones totales desde el backend.');

      // 2. Filter the fetched list based on the targetVehiculoId
      _obligaciones = allObligations
          .where((obligacion) => obligacion.vehiculoId == targetVehiculoId)
          .toList();

      print('[log] ObligacionLegalProvider: Se filtraron ${_obligaciones.length} obligaciones para el vehículo con ID: $targetVehiculoId.');

    } catch (e) {
      _errorMessage = 'Error al obtener y filtrar obligaciones legales: ${e.toString()}';
      print('[log] ObligacionLegalProvider: ERROR al cargar/filtrar obligaciones: $_errorMessage');
      _obligaciones = []; // Clear obligations on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MODIFIED METHOD for creating obligation with file ---
  Future<void> createObligacionLegal(Map<String, dynamic> data, {PlatformFile? file}) async {
    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      final newObligacion = await _obligacionLegalService.createObligacionLegal(data, file: file);
      print('[log] ObligacionLegalProvider: Obligación legal creada exitosamente: ${newObligacion.nombre}');

      // After creating, re-fetch the obligations for the *current featured vehicle*
      // to ensure the list is up-to-date with the new obligation.
      // We assume 'data' map contains 'vehiculoId' which is necessary for re-fetching the specific vehicle's obligations.
      final String? vehiculoIdToRefresh = data['vehiculoId']?.toString();
      if (vehiculoIdToRefresh != null && vehiculoIdToRefresh.isNotEmpty) {
        await fetchObligacionesByVehiculoId(vehiculoIdToRefresh);
        print('[log] ObligacionLegalProvider: Lista de obligaciones para el vehículo $vehiculoIdToRefresh actualizada.');
      } else {
        print('[warn] ObligacionLegalProvider: No se pudo obtener vehiculoId de los datos para actualizar la lista.');
        // If vehiculoId is not available, you might want to consider just adding
        // newObligacion if it matches the current _obligaciones's vehiculoId,
        // or a full re-fetch of all if that's safer. For now, we rely on it being present.
        _obligaciones.add(newObligacion); // Fallback: just add if refresh not possible/needed
      }
    } catch (e) {
      _errorMessage = 'Error al crear obligación legal: ${e.toString()}';
      print('[log] ObligacionLegalProvider: ERROR al crear obligación: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a method to clear obligations (e.g., when a vehicle is unselected)
  void clearObligaciones() {
    _obligaciones = [];
    _errorMessage = null;
    notifyListeners();
  }
}