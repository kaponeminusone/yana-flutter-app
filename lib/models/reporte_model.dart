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

  factory ReporteItem.fromJson(Map<String, dynamic> j) {
    return ReporteItem(
      marca: j['infoVehiculo']['marca'],
      placa: j['infoVehiculo']['placa'],
      modelo: j['infoVehiculo']['modelo'],
      color: j['infoVehiculo']['color'],
      nombrePropietario: j['infoPropietario']?['nombre'],
      cedulaPropietario: j['infoPropietario']?['cedula'],
      mantenimientos: (j['mantenimientos'] as List)
          .map((m) => Mantenimiento.fromJson(m))
          .toList(),
      obligacionesLegales: (j['obligacionesLegales'] as List)
          .map((o) => ObligacionLegal.fromJson(o))
          .toList(),
    );
  }
}

class Mantenimiento {
  final String tipo;
  final double precio;
  final String fecha;
  Mantenimiento({required this.tipo, required this.precio, required this.fecha});
  factory Mantenimiento.fromJson(Map<String, dynamic> j) =>
      Mantenimiento(tipo: j['tipo'], precio: j['precio'].toDouble(), fecha: j['fecha']);
}

class ObligacionLegal {
  final String nombreDocumento;
  final bool vigente;
  ObligacionLegal({required this.nombreDocumento, required this.vigente});
  factory ObligacionLegal.fromJson(Map<String, dynamic> j) =>
      ObligacionLegal(nombreDocumento: j['nombreDocumento'], vigente: j['vigente'] == true);
}
