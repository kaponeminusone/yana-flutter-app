// lib/models/reporte_model.dart
class ReporteItem {
  final String marca;
  final String placa;
  final String modelo;
  final String color;
  final String? nombrePropietario;
  final String? cedulaPropietario;
  final List<Mantenimiento> mantenimientos;
  final List<ObligacionLegal> obligacionesLegales;

  ReporteItem({
    required this.marca,
    required this.placa,
    required this.modelo,
    required this.color,
    this.nombrePropietario,
    this.cedulaPropietario,
    required this.mantenimientos,
    required this.obligacionesLegales,
  });

  factory ReporteItem.fromJson(Map<String, dynamic> json) {
    final infoVehiculo = json['infoVehiculo'] as Map<String, dynamic>?;
    if (infoVehiculo == null) {
      // Considera si esto debería ser un error o si el reporte puede existir sin infoVehiculo completa
      throw FormatException('Datos de vehículo incompletos o faltantes en el reporte.');
    }

    final infoPropietario = json['infoPropietario'] as Map<String, dynamic>?;

    return ReporteItem(
      marca: infoVehiculo['marca'] as String,
      placa: infoVehiculo['placa'] as String,
      modelo: infoVehiculo['modelo'] as String,
      color: infoVehiculo['color'] as String,
      nombrePropietario: infoPropietario?['nombre'] as String?,
      cedulaPropietario: infoPropietario?['cedula'] as String?,
      mantenimientos: (json['mantenimientos'] as List<dynamic>?)
          ?.map((m) => Mantenimiento.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      obligacionesLegales: (json['obligacionesLegales'] as List<dynamic>?)
          ?.map((o) => ObligacionLegal.fromJson(o as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class Mantenimiento {
  final String tipo;
  final double precio;
  final String fecha;

  Mantenimiento({required this.tipo, required this.precio, required this.fecha});

  factory Mantenimiento.fromJson(Map<String, dynamic> json) {
    // Manejo robusto del precio:
    double parsedPrecio;
    if (json['precio'] is String) {
      parsedPrecio = double.tryParse(json['precio']) ?? 0.0; // Intenta parsear, si falla, 0.0
    } else if (json['precio'] is num) {
      parsedPrecio = (json['precio'] as num).toDouble();
    } else {
      parsedPrecio = 0.0; // Valor por defecto si el tipo es inesperado
    }

    return Mantenimiento(
      tipo: json['tipo'] as String,
      precio: parsedPrecio,
      fecha: json['fecha'] as String,
    );
  }
}

class ObligacionLegal {
  final String nombreDocumento;
  final bool vigente;

  ObligacionLegal({required this.nombreDocumento, required this.vigente});

  factory ObligacionLegal.fromJson(Map<String, dynamic> json) {
    // Manejo robusto del booleano:
    bool parsedVigente;
    if (json['vigente'] is bool) {
      parsedVigente = json['vigente'];
    } else if (json['vigente'] is String) {
      parsedVigente = json['vigente'].toLowerCase() == 'true'; // Convierte "true" a true, cualquier otra cosa a false
    } else if (json['vigente'] is int) {
      parsedVigente = json['vigente'] == 1; // Convierte 1 a true, 0 a false
    } else {
      parsedVigente = false; // Por defecto a false si el tipo es inesperado
    }

    return ObligacionLegal(
      nombreDocumento: json['nombreDocumento'] as String,
      vigente: parsedVigente,
    );
  }
}