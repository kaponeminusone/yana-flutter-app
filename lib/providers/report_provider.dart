import 'package:flutter/foundation.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';

class ReporteProvider extends ChangeNotifier {
  final ReporteService _service;
  ReporteProvider(this._service);

  List<ReporteItem> items = [];
  bool loading = false;
  String? error;

  /// Carga el reporte del propietario (usa el endpoint manual)
  Future<void> loadAutomatico() async {
    loading = true;
    notifyListeners();

    try {
      items = await _service.fetchMyReport();
      error = null;
    } catch (e) {
      items = [];
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  /// (Opcional) Si más adelante quieres cargar con filtros:
  Future<void> loadManual({
    String? mantenimientoTipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? obligacionVigente,
    String? placa,
    String? marca,
  }) async {
    loading = true;
    notifyListeners();

    try {
      items = await _service.fetchManual(
        mantenimientoTipo: mantenimientoTipo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        obligacionVigente: obligacionVigente,
        placa: placa,
        marca: marca,
      );
      error = null;
    } catch (e) {
      items = [];
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }
}
