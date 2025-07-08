import 'package:dio/dio.dart';
import '../models/reporte_model.dart';

class ReporteService {
  final Dio _dio;
  ReporteService(this._dio);

  /// Obtiene el reporte del propietario autenticado
  Future<List<ReporteItem>> fetchMyReport() async {
    try {
      final resp = await _dio.get(
        '/api/reportes/manuales',
        options: Options(validateStatus: (status) => status != null && status < 400),
      );

      if (resp.statusCode != 200) {
        final msg = resp.data is Map<String, dynamic>
            ? (resp.data['message'] ?? 'Error desconocido')
            : 'Error de servidor';
        throw Exception('(${resp.statusCode}) $msg');
      }

      final lista = resp.data['data']['reporte'] as List;
      return lista
          .map((j) => ReporteItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioError catch (e) {
      throw Exception('Fallo de conexión: ${e.message}');
    }
  }

  /// (Opcional) Si en el futuro necesitas filtros manuales:
  Future<List<ReporteItem>> fetchManual({
    String? mantenimientoTipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? obligacionVigente,
    String? placa,
    String? marca,
  }) async {
    final qp = <String, dynamic>{};
    if (mantenimientoTipo != null) qp['mantenimientoTipo'] = mantenimientoTipo;
    if (fechaInicio != null) qp['mantenimientoFechaInicio'] = fechaInicio.toIso8601String();
    if (fechaFin != null)    qp['mantenimientoFechaFin']    = fechaFin.toIso8601String();
    if (obligacionVigente != null) qp['obligacionVigente'] = obligacionVigente.toString();
    if (placa != null) qp['vehiculoPlaca'] = placa;
    if (marca != null) qp['vehiculoMarca'] = marca;

    final resp = await _dio.get('/api/reportes/manuales', queryParameters: qp);
    final lista = (resp.data['data']['reporte'] as List);
    return lista.map((j) => ReporteItem.fromJson(j as Map<String, dynamic>)).toList();
  }
}
