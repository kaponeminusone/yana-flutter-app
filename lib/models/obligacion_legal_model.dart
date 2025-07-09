import 'package:yana/models/vehiculo_model.dart';
import 'package:intl/intl.dart';

class ObligacionLegalModel {
  final String id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final DateTime? fechaVencimiento;
  // CAMBIO CLAVE: Cambiar de 'archivoPath' a 'documentoPath'
  final String? documentoPath; 
  final String vehiculoId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VehiculoModel? vehiculo;

  ObligacionLegalModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.fechaVencimiento,
    // CAMBIO CLAVE: Cambiar de 'archivoPath' a 'documentoPath'
    this.documentoPath, 
    required this.vehiculoId,
    this.createdAt,
    this.updatedAt,
    this.vehiculo,
  });

  factory ObligacionLegalModel.fromJson(Map<String, dynamic> json) {
    return ObligacionLegalModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String?,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      // CAMBIO CLAVE: Leer 'documentoPath' del JSON
      documentoPath: json['documentoPath'] as String?, 
      vehiculoId: json['vehiculoId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      vehiculo: json['vehiculo'] != null
          ? VehiculoModel.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'fechaVencimiento': fechaVencimiento?.toIso8601String().split('T')[0],
      // CAMBIO CLAVE: Enviar 'documentoPath' en el JSON
      'documentoPath': documentoPath, 
      'vehiculoId': vehiculoId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedFechaVencimiento {
    if (fechaVencimiento == null) return 'N/A';
    return DateFormat('dd MMMM yyyy', 'es').format(fechaVencimiento!); // Asegúrate de que 'yyyy' está si quieres el año completo
  }

  bool get isVencida {
    if (fechaVencimiento == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDate = DateTime(fechaVencimiento!.year, fechaVencimiento!.month, fechaVencimiento!.day);
    return expirationDate.isBefore(today);
  }
}