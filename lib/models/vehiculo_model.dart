// lib/models/vehiculo_model.dart

class VehiculoModel {
  final String id;
  final String placa; // NO es anulable según tu log de createVehiculo
  final String marca;
  final String modelo;
  final int year; // NO es anulable según tu log de createVehiculo
  final String? color; // OK, puede ser anulable
  final String propietarioId; // NO es anulable según tu log de createVehiculo
  final DateTime createdAt; // NO es anulable según tu log de createVehiculo
  final DateTime updatedAt; // NO es anulable según tu log de createVehiculo

  VehiculoModel({
    required this.id,
    required this.placa, // Requerido
    required this.marca,
    required this.modelo,
    required this.year, // Requerido
    this.color,
    required this.propietarioId, // Requerido
    required this.createdAt, // Requerido
    required this.updatedAt, // Requerido
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] as String,
      placa: json['placa'] as String, // Aquí, como String (no String?)
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      // Mantenemos tu manejo robusto para 'year' en caso de que venga distinto a int.
      // Pero si tu backend siempre lo devuelve como int, `json['year'] as int` es suficiente.
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? '') ?? 0, // Fallback a 0 o lanza error si prefieres
      color: json['color'] as String?,
      propietarioId: json['propietarioId'] as String, // Aquí, como String (no String?)
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'year': year,
      'color': color,
      'propietarioId': propietarioId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}