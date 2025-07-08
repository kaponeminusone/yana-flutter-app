import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'register_view.dart';

// NUEVO: Painter para las figuras de fondo
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Círculo superior izquierdo (más grande y tenue)
    paint.color = Colors.blue.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 150, paint);

    // Círculo inferior derecho (más pequeño y un poco más opaco)
    paint.color = Colors.blue.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.8), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AuthProvider _authProvider;

  // ... (Tu lógica de initState, dispose, _handleAuthChanges y _performLogin se mantiene igual)
  // Recomiendo mantenerla tal como la tienes, ya que está bien estructurada.

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
    _emailController.dispose();
    _passwordController.dispose();
    _authProvider.removeListener(_handleAuthChanges);
    super.dispose();
  }

  void _handleAuthChanges() {
    if (!mounted) return;
    final authProvider = _authProvider;
    if (authProvider.errorMessage != null &&
        (authProvider.status == AuthStatus.error ||
         authProvider.status == AuthStatus.unauthenticated)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      authProvider.clearErrorMessage();
    }
  }

  Future<void> _performLogin() async {
    // Oculta el teclado al presionar el botón
    FocusScope.of(context).unfocus(); 
    
    final authProvider = _authProvider;
    authProvider.clearErrorMessage();
    await authProvider.login(
      correo: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.status == AuthStatus.authenticating;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
      body: Stack(
        children: [
          // 1. Figuras de fondo
          CustomPaint(
            painter: BackgroundPainter(),
            size: Size.infinite,
          ),

          // 2. Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mensaje de bienvenida
                    Text(
                      'Bienvenido a Yana',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08), // Espacio dinámico

                    // Campo de Correo
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Campo de Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Botón de Iniciar Sesión
                    ElevatedButton(
                      onPressed: isLoading ? null : _performLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blue.withOpacity(0.4),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            )
                          : Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20.0),

                    // Botón para registrarse
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta?',
                           style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const RegisterView(),
                            ));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            'Crea una aquí',
                             style: GoogleFonts.poppins(
                               fontWeight: FontWeight.w600,
                             ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}