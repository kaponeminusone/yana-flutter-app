// main.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert'; // Para jsonEncode, útil para imprimir el payload y la respuesta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yana Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestRegistrationScreen(),
    );
  }
}

class TestRegistrationScreen extends StatefulWidget {
  const TestRegistrationScreen({super.key});

  @override
  State<TestRegistrationScreen> createState() => _TestRegistrationScreenState();
}

class _TestRegistrationScreenState extends State<TestRegistrationScreen> {
  final Dio _dio = Dio(); // Instancia de Dio
  String _responseMessage = 'Presiona el botón para intentar registrar un usuario.';
  Color _messageColor = Colors.black;

  // Función para realizar la petición de registro
  Future<void> _registerUserTest() async {
    final String endpoint = 'https://yana-gestorvehicular.onrender.com/api/auth/register';

    // Datos del usuario a registrar.
    // CAMBIA ESTOS DATOS si necesitas registrar un usuario diferente en cada prueba
    // (especialmente el correo y la identificación si tu backend no permite duplicados)
    final Map<String, dynamic> userData = {
      "nombre": "Juan Pérez",
      "identificacion": "1234567890", // Cambia esto para cada registro si hay restricción de unicidad
      "correo": "juan.perez@example.com", // Cambia esto para cada registro si hay restricción de unicidad
      "password": "UnaContrasenaSegura123",
      "celular": "+573001234567"
    };

    setState(() {
      _responseMessage = 'Intentando registrar usuario...';
      _messageColor = Colors.blue;
    });

    print('--- Iniciando prueba de registro ---');
    print('URL del endpoint: $endpoint');
    print('Datos a enviar (JSON): ${jsonEncode(userData)}');

    try {
      final response = await _dio.post(
        endpoint,
        data: userData,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      print('--- Petición exitosa ---');
      print('Status Code: ${response.statusCode}');
      print('Respuesta del servidor (data): ${jsonEncode(response.data)}');
      print('Encabezados de la respuesta: ${response.headers}');

      if (response.statusCode == 201) {
        setState(() {
          _responseMessage = '¡Usuario registrado exitosamente!\nStatus: ${response.statusCode}\nDatos: ${jsonEncode(response.data)}';
          _messageColor = Colors.green;
        });
        print('¡Usuario registrado exitosamente!');
      } else {
        // Aunque el status sea 2xx, si no es 201 podría ser un caso especial
        setState(() {
          _responseMessage = 'Registro completado con status inusual: ${response.statusCode}\nDatos: ${jsonEncode(response.data)}';
          _messageColor = Colors.orange;
        });
      }

    } on DioException catch (e) {
      print('--- Error en la petición ---');
      print('Tipo de error Dio: ${e.type}');
      print('Mensaje de error: ${e.message}');
      String errorMsg = 'Error desconocido al registrar usuario.';

      if (e.response != null) {
        print('Status Code del error: ${e.response?.statusCode}');
        print('Datos de error (response.data): ${jsonEncode(e.response?.data)}');
        print('Encabezados de error: ${e.response?.headers}');

        // Intenta obtener un mensaje de error específico del backend
        if (e.response?.data != null && e.response?.data is Map && e.response?.data.containsKey('message')) {
          errorMsg = e.response?.data['message'];
        } else {
          errorMsg = 'Error del servidor: ${e.response?.statusCode}';
        }
      } else {
        errorMsg = 'Error de conexión: ${e.message} (puede ser problema de red o URL incorrecta)';
      }

      setState(() {
        _responseMessage = 'Error al registrar: $errorMsg';
        _messageColor = Colors.red;
      });

    } catch (e) {
      print('--- Error inesperado ---');
      print('Error general: $e');
      setState(() {
        _responseMessage = 'Error inesperado: $e';
        _messageColor = Colors.red;
      });
    } finally {
      print('--- Fin de la prueba de registro ---');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de Registro de Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _responseMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _messageColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _registerUserTest,
              child: const Text('Intentar Registrar Usuario'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Abre la consola de depuración para ver los detalles de la petición y la respuesta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}