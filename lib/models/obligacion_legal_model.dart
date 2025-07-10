// lib/models/obligacion_legal_model.dart
import 'package:intl/intl.dart';

/// Vehículo anidado para Obligaciones: sólo los campos que vienen en la respuesta JSON.
class ObligacionVehiculo {
  final String id;
  final String placa;
  final String marca;
  final String modelo;

  ObligacionVehiculo({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
  });

  factory ObligacionVehiculo.fromJson(Map<String, dynamic> json) {
    return ObligacionVehiculo(
      id: json['id']?.toString() ?? '',
      placa: json['placa']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
    );
  }
}

class ObligacionLegalModel {
  final String id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final DateTime? fechaVencimiento;
  final String? documentoPath;
  final String vehiculoId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ObligacionVehiculo? vehiculo;

  ObligacionLegalModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.fechaVencimiento,
    this.documentoPath,
    required this.vehiculoId,
    this.createdAt,
    this.updatedAt,
    this.vehiculo,
  });

  factory ObligacionLegalModel.fromJson(Map<String, dynamic> json) {
    // Parseo seguro del vehículo anidado
    ObligacionVehiculo? veh;
    if (json['vehiculo'] != null && json['vehiculo'] is Map) {
      try {
        veh = ObligacionVehiculo.fromJson(
          Map<String, dynamic>.from(json['vehiculo'] as Map),
        );
      } catch (e) {
        // Si algo falla, reportamos y dejamos veh = null
        print('[warn] ObligacionLegalModel: error parseando vehiculo: \$e');
        veh = null;
      }
    }

    return ObligacionLegalModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.tryParse(json['fechaVencimiento'].toString())
          : null,
      documentoPath: json['documentoPath']?.toString(),
      vehiculoId: json['vehiculoId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      vehiculo: veh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'fechaVencimiento': fechaVencimiento
          ?.toIso8601String()
          .split('T')[0],
      'documentoPath': documentoPath,
      'vehiculoId': vehiculoId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedFechaVencimiento {
    if (fechaVencimiento == null) return 'N/A';
    return DateFormat('dd MMMM yyyy', 'es').format(fechaVencimiento!);
  }

  bool get isVencida {
    if (fechaVencimiento == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(
      fechaVencimiento!.year,
      fechaVencimiento!.month,
      fechaVencimiento!.day,
    );
    return exp.isBefore(today);
  }
}
