// lib/services/reporte_service.dart
import 'package:dio/dio.dart';
import '../models/reporte_model.dart';

class ReporteService {
  final Dio _dio;

  ReporteService(this._dio);

  /// Fetches the report for the authenticated user.
  Future<List<ReporteItem>> fetchMyReport() async {
    try {
      // Si tu baseUrl en Dio es 'http://<ip>:<puerto>/api', esta ruta relativa es correcta.
      // La petición se hará a 'http://<ip>:<puerto>/api/reportes/automaticos'
      final response = await _dio.get('/api/reportes/automaticos');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final Map<String, dynamic> responseMap = response.data;

          if (responseMap.containsKey('data') && responseMap['data'] is Map<String, dynamic>) {
            final Map<String, dynamic> dataMap = responseMap['data'];

            if (dataMap.containsKey('reporte') && dataMap['reporte'] is List<dynamic>) {
              final List<dynamic> jsonList = dataMap['reporte'];
              return jsonList.map((json) => ReporteItem.fromJson(json as Map<String, dynamic>)).toList();
            } else {
              throw 'Formato de respuesta inesperado: La clave "reporte" no es una lista válida o no existe.';
            }
          } else {
            throw 'Formato de respuesta inesperado: La clave "data" no es un mapa válido o no existe.';
          }
        } else {
          throw 'Formato de respuesta inesperado: Se esperaba un objeto JSON principal (Map).';
        }
      } else {
        throw 'Error inesperado del servidor al cargar el reporte: Estado ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic> && e.response!.data.containsKey('message')
            ? e.response!.data['message']
            : 'Error de servidor al cargar el reporte automático.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al cargar el reporte: $e';
    }
  }

  /// Fetches reports based on provided filters.
  /// (Mantengo la ruta relativa '/reportes/manual' asumiendo que la baseUrl de Dio incluye '/api')
  Future<List<ReporteItem>> fetchManual({
    String? mantenimientoTipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? obligacionVigente,
    String? placa,
    String? marca,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (mantenimientoTipo != null) queryParams['mantenimientoTipo'] = mantenimientoTipo;
      if (fechaInicio != null) queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      if (fechaFin != null) queryParams['fechaFin'] = fechaFin.toIso8601String();
      if (obligacionVigente != null) queryParams['obligacionVigente'] = obligacionVigente.toString();
      if (placa != null) queryParams['placa'] = placa;
      if (marca != null) queryParams['marca'] = marca;

      final response = await _dio.get(
        '/reportes/manual', // Endpoint de ejemplo para filtros
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is List<dynamic>) { // Asumiendo que este endpoint devuelve una lista directa
          final List<dynamic> jsonList = response.data;
          return jsonList.map((json) => ReporteItem.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw 'Formato de respuesta inesperado: Se esperaba una lista de reportes filtrados.';
        }
      } else {
        throw 'Error inesperado del servidor al cargar el reporte filtrado: Estado ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response!.data['message'] ?? 'Error de servidor al cargar el reporte filtrado.')
            : 'Error de servidor al cargar el reporte filtrado.';
        throw errorMessage;
      } else {
        throw 'Error de conexión: ${e.message}';
      }
    } catch (e) {
      throw 'Error inesperado al cargar el reporte filtrado: $e';
    }
  }
}