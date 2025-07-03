import 'package:flutter/material.dart'; // Solo si necesitas anotaciones como @required
import 'vehiculo_model.dart'; // Asumo que tienes VehiculoModel definido
import 'taller_mecanico_model.dart'; // Nuevo archivo para TallerMecanicoModel

class MantenimientoModel {
  final String id;
  final String tipo;
  final DateTime fecha;
  final DateTime? fechaProximoMantenimiento;
  final int kilometraje;
  final String descripcion;
  final double costo;
  final String? facturaPath; // URL o path relativo del archivo
  final String vehiculoId;
  final String? tallerMecanicoId; // Puede ser nulo

  // Campos de tiempo
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones (pueden ser nulas si no se cargan o no existen)
  final VehiculoModel? vehiculo;
  final TallerMecanicoModel? tallerMecanico;

  MantenimientoModel({
    required this.id,
    required this.tipo,
    required this.fecha,
    this.fechaProximoMantenimiento,
    required this.kilometraje,
    required this.descripcion,
    required this.costo,
    this.facturaPath,
    required this.vehiculoId,
    this.tallerMecanicoId,
    required this.createdAt,
    required this.updatedAt,
    this.vehiculo,
    this.tallerMecanico,
  });

  factory MantenimientoModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      fechaProximoMantenimiento: json['fechaProximoMantenimiento'] != null
          ? DateTime.parse(json['fechaProximoMantenimiento'] as String)
          : null,
      kilometraje: json['kilometraje'] as int,
      descripcion: json['descripcion'] as String,
      costo: (json['costo'] as num).toDouble(), // Maneja int o double
      facturaPath: json['facturaPath'] as String?,
      vehiculoId: json['vehiculoId'] as String,
      tallerMecanicoId: json['tallerMecanicoId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      vehiculo: json['vehiculo'] != null
          ? VehiculoModel.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
      tallerMecanico: json['tallerMecanico'] != null
          ? TallerMecanicoModel.fromJson(json['tallerMecanico'] as Map<String, dynamic>)
          : null,
    );
  }

  // Método para convertir a JSON, útil para enviar al backend (sin las relaciones anidadas)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'fechaProximoMantenimiento': fechaProximoMantenimiento?.toIso8601String(),
      'kilometraje': kilometraje,
      'descripcion': descripcion,
      'costo': costo,
      'facturaPath': facturaPath,
      'vehiculoId': vehiculoId,
      'tallerMecanicoId': tallerMecanicoId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // No incluimos 'vehiculo' y 'tallerMecanico' aquí,
      // ya que el backend espera solo los IDs para las relaciones.
    };
  }
}