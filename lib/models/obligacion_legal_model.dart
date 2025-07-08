// lib/models/obligacion_legal_model.dart
import 'package:yana/models/vehiculo_model.dart';
import 'package:intl/intl.dart';

class ObligacionLegalModel {
  final String id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final DateTime? fechaVencimiento;
  final String? archivoPath; // *** CAMBIO: Usar archivoPath para que coincida con la API DOCS ***
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
    this.archivoPath, // *** CAMBIO ***
    required this.vehiculoId,
    this.createdAt,
    this.updatedAt,
    this.vehiculo,
  });

  factory ObligacionLegalModel.fromJson(Map<String, dynamic> json) {
    return ObligacionLegalModel(
      id: json['id'] as String, // Asegurar el casteo explícito
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String?, // Usar as String? para anulables
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String) // Asegurar casteo
          : null,
      archivoPath: json['archivoPath'] as String?, // *** CAMBIO: Usar archivoPath para leer del JSON ***
      vehiculoId: json['vehiculoId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      vehiculo: json['vehiculo'] != null
          ? VehiculoModel.fromJson(json['vehiculo'] as Map<String, dynamic>) // Asegurar casteo
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'fechaVencimiento': fechaVencimiento?.toIso8601String().split('T')[0], // Formato a 'YYYY-MM-DD'
      'archivoPath': archivoPath, // *** CAMBIO: Usar archivoPath para enviar al JSON ***
      'vehiculoId': vehiculoId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      // 'vehiculo': vehiculo?.toJson(), // No suele enviarse el objeto completo del vehículo al actualizar/crear una obligación
    };
  }

  // Ayuda para mostrar la fecha formateada
  String get formattedFechaVencimiento {
    if (fechaVencimiento == null) return 'N/A';
    // *** CAMBIO: Formato solo de fecha para DATEONLY ***
    return DateFormat('dd MMMM yyyy', 'es').format(fechaVencimiento!);
  }

  bool get isVencida {
    if (fechaVencimiento == null) return false; // O el comportamiento que prefieras para nulos
    return fechaVencimiento!.isBefore(DateTime.now());
  }
}