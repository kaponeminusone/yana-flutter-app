import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // NUEVO: Guardar una referencia al AuthProvider
  late AuthProvider _authProvider; // Usamos 'late' porque se inicializará en initState

  @override
  void initState() {
    super.initState();
    // NOTA: No usamos Provider.of(context, listen: false) directamente aquí.
    // Lo haremos en didChangeDependencies o addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Guardar la referencia al provider una vez que el contexto esté disponible
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider.addListener(_handleAuthChanges);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // Ahora usamos la referencia guardada, que es segura en dispose
    _authProvider.removeListener(_handleAuthChanges); // <-- ¡Cambio aquí!
    super.dispose();
  }

  void _handleAuthChanges() {
    // Asegurarse de que el widget sigue montado antes de mostrar SnackBar
    if (!mounted) return; // <-- Buena práctica adicional

    final authProvider = _authProvider; // Usar la referencia guardada

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearErrorMessage();
    }
  }

  Future<void> _performLogin() async {
    final authProvider = _authProvider; // Usar la referencia guardada
    await authProvider.login(
      correo: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // En el build, podemos usar context.watch sin problema
    final authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.status == AuthStatus.authenticating;

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
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _performLogin,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: isLoading ? null : () {
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