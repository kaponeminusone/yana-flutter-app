// lib/models/auth_response.dart
import 'package:yana/models/propietario_model.dart'; // Asegúrate de la ruta correcta

class AuthResponse {
  final String accessToken;
  final PropietarioModel propietario;

  AuthResponse({required this.accessToken, required this.propietario});
}