// lib/models/propietario_model.dart
class PropietarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String identificacion;
  final String celular;

  PropietarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.identificacion,
    required this.celular,
  });

  factory PropietarioModel.fromJson(Map<String, dynamic> json) {
    return PropietarioModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      identificacion: json['identificacion'] as String,
      celular: json['celular'] as String,
    );
  }
}

// lib/models/auth_response_models.dart
class RegisterResponse {
  final String message;
  final PropietarioModel propietario;

  RegisterResponse({required this.message, required this.propietario});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String,
      propietario:
          PropietarioModel.fromJson(json['propietario'] as Map<String, dynamic>),
    );
  }
}

class LoginResponse {
  final String message;
  final String accessToken;
  final PropietarioModel propietario;

  LoginResponse({
    required this.message,
    required this.accessToken,
    required this.propietario,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      accessToken: json['accessToken'] as String,
      propietario:
          PropietarioModel.fromJson(json['propietario'] as Map<String, dynamic>),
    );
  }
}
