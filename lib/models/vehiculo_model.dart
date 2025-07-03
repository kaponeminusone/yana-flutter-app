class VehiculoModel {
  final String id;
  final String placa;
  final String marca;
  final String modelo;
  final int year;
  final String color;
  final String propietarioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehiculoModel({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.year,
    required this.color,
    required this.propietarioId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] as String,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      propietarioId: json['propietarioId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}