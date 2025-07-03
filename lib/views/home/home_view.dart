// lib/views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart'; // ¡Importar Provider!
import 'package:yana/providers/auth_provider.dart'; // ¡Importar tu AuthProvider!
import 'package:yana/views/authentication/login_view.dart';
import 'package:yana/views/home/tabs/alerts_tab.dart';
import 'package:yana/views/home/tabs/reports_tab.dart';
import 'package:yana/views/maintenance/qr_maintenance_view.dart';
import 'package:yana/views/vehicles/add_vehicle_view.dart';
// Asegúrate de importar la pantalla de login si aún no lo haces

import 'tabs/vehicles_tab.dart';
import 'tabs/maintenance_tab.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Escuchar el estado de autenticación al inicio
    // Esto es crucial para reaccionar si la sesión expira mientras se usa la app
    // o si el auto-login falla después de un reinicio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_authStatusListener);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Es importante remover el listener para evitar fugas de memoria
    Provider.of<AuthProvider>(context, listen: false).removeListener(_authStatusListener);
    super.dispose();
  }

  void _authStatusListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.status == AuthStatus.unauthenticated || authProvider.status == AuthStatus.error) {
      // Si el estado es desautenticado o hay un error de autenticación,
      // navega de vuelta a la pantalla de login y limpia la pila de rutas.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()), // Tu pantalla de login
        (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
      );
      // Opcional: mostrar un SnackBar con el mensaje de error si existe
      if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        authProvider.clearErrorMessage(); // Limpiar el mensaje después de mostrarlo
      }
    }
  }

  /// Define aquí las acciones para cada pestaña.
  List<SpeedDialChild> _buildSpeedDialActions(int index) {
    switch (index) {
      case 0:
      // Vehículos
        return [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Nuevo vehículo',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddVehicleView()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            label: 'Escanear VIN',
            onTap: () => debugPrint('Escanear VIN'),
          ),
        ];
      case 1:
      // Mantenimiento
        return [
          SpeedDialChild(
            child: const Icon(Icons.build),
            label: 'Nueva orden',
            onTap: () => debugPrint('Crear orden de mantenimiento'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Nueva orden QR',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrOrderView()),
            ),
          ),
        ];
      case 2:
      // Reportes
        return [
          SpeedDialChild(
            child: const Icon(Icons.insert_chart),
            label: 'Generar reporte',
            onTap: () => debugPrint('Generar reporte'),
          ),
        ];
      case 3:
      // Alertas
        return [
          SpeedDialChild(
            child: const Icon(Icons.notification_add),
            label: 'Agregar alerta',
            onTap: () => debugPrint('Agregar alerta'),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabController.index;
    final authProvider = context.watch<AuthProvider>(); // Usamos watch para reconstruir si el usuario cambia

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yana'),
        actions: [
          // Botón para desloguearse
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              // Muestra un diálogo de confirmación
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que quieres cerrar tu sesión?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Cierra el diálogo
                        },
                      ),
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Cierra el diálogo
                          authProvider.logout(); // Llama al método de logout del provider
                          // La navegación al login se manejará automáticamente por _authStatusListener
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          tabs: const [
            Tab(text: 'Vehículos', icon: Icon(Icons.directions_car)),
            Tab(text: 'Mantenimiento', icon: Icon(Icons.build_circle)),
            Tab(text: 'Reportes', icon: Icon(Icons.insert_chart)),
            Tab(text: 'Alertas', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VehiclesTab(),
          MaintenanceTab(),
          ReportsTab(),
          AlertsTab()
        ],
      ),
      floatingActionButton: SpeedDial(
        key: ValueKey(_currentIndex),
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        children: _buildSpeedDialActions(currentIndex),
      ),
    );
  }
}