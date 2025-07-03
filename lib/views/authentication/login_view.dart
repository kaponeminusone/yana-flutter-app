import 'package:flutter/material.dart';
import 'package:yana/views/home/home_view.dart';
import 'register_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16.0),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Por ahora, solo simula el login navegando al home
                    // En la vida real, aquí pondrías la lógica de autenticación
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeView(), // Navega al Home
                      ),
                    );
                  },
                  child: const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 16.0),
              // El botón para ir a la vista de registro
              TextButton(
                onPressed: () {
                  // Navega a la vista de registro. Usa push para que se añada a la pila y se pueda regresar.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterView(),
                    ),
                  );
                },
                child: const Text('¿No tienes una cuenta? Crea una'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
