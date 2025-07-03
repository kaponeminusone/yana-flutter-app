import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idController = TextEditingController(); // Para identificación
  final TextEditingController _phoneController = TextEditingController(); // Para celular

  late AuthProvider _authProvider; // Referencia al AuthProvider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider.addListener(_handleAuthChanges);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    
    // Es CRUCIAL que _authProvider se haya inicializado antes de intentar remover el listener
    // Si la vista se desmonta muy rápido (ej. si haces pop antes de que addPostFrameCallback se ejecute)
    // _authProvider podría no estar inicializado.
    // Una forma más segura sería:
    if (mounted && _authProvider != null) { // <-- Verificación adicional para robustez
      _authProvider.removeListener(_handleAuthChanges);
    }
    // Otra alternativa, si el `_authProvider` nunca es null porque `initState` siempre lo asigna,
    // es simplemente dejar `_authProvider.removeListener(_handleAuthChanges);`
    // asumiento que addPostFrameCallback ya se ejecutó.
    // Para este caso, con `late` y `addPostFrameCallback`, la verificación `if(mounted && _authProvider != null)`
    // es una capa extra de seguridad, aunque `late` ya garantiza que no será nulo al momento de usarse si `initState` completa.

    super.dispose();
  }

  void _handleAuthChanges() {
    // Asegurarse de que el widget sigue montado
    if (!mounted) return;

    final authProvider = _authProvider; // Usar la referencia guardada

    // Solo manejar errores aquí. La navegación de éxito se manejará en _performRegister.
    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearErrorMessage();
    }
    // NOTA: Se elimina la lógica de navegación de éxito y SnackBar de éxito de aquí.
  }

  Future<void> _performRegister() async {
    final authProvider = _authProvider; // Usar la referencia guardada

    // Limpiar errores previos si los hubiera para no mostrarlos dos veces
    authProvider.clearErrorMessage(); // Agrega esto si no lo tienes en AuthProvider

    // Intentar el registro
    await authProvider.register(
      nombre: _nameController.text,
      identificacion: _idController.text,
      correo: _emailController.text,
      password: _passwordController.text,
      celular: _phoneController.text,
    );

    // NUEVO: Manejo de la respuesta después de que register() ha completado
    // Asegurarse de que el widget sigue montado antes de cualquier operación de UI/navegación
    if (!mounted) return;

    if (authProvider.errorMessage == null) {
      // Registro exitoso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Por favor, inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      // Solo hacer pop si realmente podemos (evita errores si la ruta ya no existe)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Regresar a la vista de Login
      }
    }
    // Si hay un error, el _handleAuthChanges lo mostrará y authProvider.errorMessage ya estará seteado
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Identificación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 16.0),
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
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
                    onPressed: isLoading ? null : _performRegister,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Registrarse'),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}