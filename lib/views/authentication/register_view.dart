import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de tenerlo importado
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// REUTILIZAMOS EL PAINTER DEL LOGIN PARA CONSISTENCIA
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Círculo superior izquierdo
    paint.color = Colors.blue.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 150, paint);

    // Círculo inferior derecho
    paint.color = Colors.blue.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.8), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late AuthProvider _authProvider;

  // --- Tu lógica de estado se mantiene intacta ---
  // El código de initState, dispose, _handleAuthChanges y _performRegister
  // es robusto y no necesita cambios. ¡Buen trabajo ahí!

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
    _authProvider.removeListener(_handleAuthChanges);
    super.dispose();
  }

  void _handleAuthChanges() {
    if (!mounted) return;
    final authProvider = _authProvider;
    if (authProvider.errorMessage != null) {
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

  Future<void> _performRegister() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado
    final authProvider = _authProvider;
    authProvider.clearErrorMessage();

    await authProvider.register(
      nombre: _nameController.text.trim(),
      identificacion: _idController.text.trim(),
      correo: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      celular: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (authProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }


  // --- El Widget Build rediseñado ---
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Fondo con figuras
          CustomPaint(
            painter: BackgroundPainter(),
            size: Size.infinite,
          ),

          // 2. Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Text(
                    'Crea tu cuenta',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa los datos para unirte.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Formulario con el nuevo estilo ---
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Nombre Completo',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _idController,
                    labelText: 'Identificación',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                   _buildTextField(
                    controller: _phoneController,
                    labelText: 'Celular',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32.0),

                  // Botón de Registrarse
                  ElevatedButton(
                    onPressed: isLoading ? null : _performRegister,
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
                            'Crear Cuenta',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20.0),

                  // Botón para ir al Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                         style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(
                          'Inicia sesión',
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
        ],
      ),
    );
  }

  // Widget helper para no repetir código de los TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}