class TallerMecanicoModel {
  final String id;
  final String nombre;
  final String nitOCedula;

  TallerMecanicoModel({
    required this.id,
    required this.nombre,
    required this.nitOCedula,
  });

  factory TallerMecanicoModel.fromJson(Map<String, dynamic> json) {
    return TallerMecanicoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      nitOCedula: json['nitOCedula'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nitOCedula': nitOCedula,
    };
  }
}