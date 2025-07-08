// lib/models/mantenimiento_model.dart
import 'package:yana/models/vehiculo_model.dart';
import 'package:intl/intl.dart'; // Agrega si lo usas para formatear fechas

class MantenimientoModel {
  final String id;
  final String vehiculoId;
  final String? tallerMecanicoId; // <--- ¡AÑADIR ESTE CAMPO!
  final String tipo;
  final DateTime fecha;
  final int kilometraje;
  final String? descripcion;
  final String? facturaPath;
  final double costo;
  final DateTime? fechaVencimiento;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TallerMecanicoModel? tallerMecanico;
  final VehiculoModel? vehiculo;

  MantenimientoModel({
    required this.id,
    required this.vehiculoId,
    this.tallerMecanicoId, // <--- AÑADIR EN EL CONSTRUCTOR
    required this.tipo,
    required this.fecha,
    required this.kilometraje,
    this.descripcion,
    this.facturaPath,
    required this.costo,
    this.fechaVencimiento,
    required this.createdAt,
    required this.updatedAt,
    this.tallerMecanico,
    this.vehiculo,
  });

  factory MantenimientoModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoModel(
      id: json['id'] as String,
      vehiculoId: json['vehiculoId'] as String,
      tallerMecanicoId: json['tallerMecanicoId'] as String?, // <--- ¡LEERLO COMO String?!
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      kilometraje: json['kilometraje'] is int
          ? json['kilometraje'] as int
          : (json['kilometraje'] != null ? int.tryParse(json['kilometraje'].toString()) ?? 0 : 0),
      descripcion: json['descripcion'] as String?,
      facturaPath: json['facturaPath'] as String?,
      costo: json['costo'] is double
          ? json['costo'] as double
          : (json['costo'] != null ? double.tryParse(json['costo'].toString()) ?? 0.0 : 0.0),
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tallerMecanico: json['tallerMecanico'] != null
          ? TallerMecanicoModel.fromJson(json['tallerMecanico'] as Map<String, dynamic>)
          : null,
      vehiculo: json['vehiculo'] != null
          ? VehiculoModel.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculoId': vehiculoId,
      'tallerMecanicoId': tallerMecanicoId, // <--- Incluir en toJson
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'kilometraje': kilometraje,
      'descripcion': descripcion,
      'facturaPath': facturaPath,
      'costo': costo,
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tallerMecanico': tallerMecanico?.toJson(),
      'vehiculo': vehiculo?.toJson(), // Asegúrate de que VehiculoModel tiene toJson
    };
  }
}

// Asegúrate de que TallerMecanicoModel.dart esté así también
class TallerMecanicoModel {
  final String id;
  final String nombre;
  final String? nitOCedula;
  final String? direccion;
  final String? telefono;
  final String? correo;

  TallerMecanicoModel({
    required this.id,
    required this.nombre,
    this.nitOCedula,
    this.direccion,
    this.telefono,
    this.correo,
  });

  factory TallerMecanicoModel.fromJson(Map<String, dynamic> json) {
    return TallerMecanicoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      nitOCedula: json['nitOCedula'] as String?,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nitOCedula': nitOCedula,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
    };
  }
}

// También, si no lo tienes, deberías tener un VehiculoModel con un toJson
// Ejemplo (ajusta si es diferente):
class VehiculoModel {
  final String id;
  final String placa;
  final String marca;
  final String modelo;

  VehiculoModel({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] as String,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
    };
  }
}