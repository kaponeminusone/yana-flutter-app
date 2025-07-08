// lib/views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts

import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/providers/report_provider.dart';
// import 'package:yana/providers/maintenance_provider.dart'; // Descomentar si tienes

import 'package:yana/views/authentication/login_view.dart';
import 'package:yana/views/home/tabs/alerts_tab.dart';
import 'package:yana/views/home/tabs/report_tab.dart';
import 'package:yana/views/maintenance/add_maintenance_view.dart';
import 'package:yana/views/maintenance/qr_maintenance_view.dart';
import 'package:yana/views/vehicles/add_obligacion_legal_view.dart';
import 'package:yana/views/vehicles/add_vehicle_view.dart';
import 'dart:developer';

import 'tabs/vehicles_tab.dart';
import 'tabs/maintenance_tab.dart' hide AddMaintenanceView;

// Eliminamos el BackgroundPainter para optimizar el rendimiento.
// Si lo necesitas en otro lugar, asegúrate de mantenerlo en un archivo separado.

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_authStatusListener);
      log('AuthProvider listener añadido en HomeView initState.', name: 'HomeView');
    });

    _tabController.addListener(_tabIndexListener);
  }

  void _tabIndexListener() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      log('Tab cambiado a índice: $_currentIndex', name: 'HomeView');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabIndexListener);
    _tabController.dispose();
    Provider.of<AuthProvider>(context, listen: false).removeListener(_authStatusListener);
    log('HomeView disposed, listeners removidos.', name: 'HomeView');
    super.dispose();
  }

  void _authStatusListener() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.status == AuthStatus.unauthenticated || authProvider.status == AuthStatus.error) {
      log('Estado de autenticación no válido, navegando a LoginView. Status: ${authProvider.status}', name: 'HomeViewAuth');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (Route<dynamic> route) => false,
      );
      if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        authProvider.clearErrorMessage();
        log('Mostrando Snackbar de error de autenticación: ${authProvider.errorMessage}', name: 'HomeViewAuth');
      }
    }
  }

  List<SpeedDialChild> _buildSpeedDialActions(int index) {
    log('Construyendo SpeedDialChilds para índice: $index', name: 'HomeViewSpeedDial');
    switch (index) {
      case 0: // Vehículos
        return [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Nuevo vehículo',
            onTap: () async {
              log('Navegando a AddVehicleView...', name: 'HomeViewSpeedDial');
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddVehicleView()),
              );
              if (result == true) {
                log('Vehículo añadido, recargando vehículos.', name: 'HomeViewSpeedDial');
                Provider.of<VehiculoProvider>(context, listen: false).fetchVehiculos();
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.assignment),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Añadir Obligación Legal',
            onTap: () async {
              log('Navegando a AddObligacionLegalView...', name: 'HomeViewSpeedDial');
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddObligacionLegalView()),
              );
              if (result == true) {
                log('Obligación legal añadida, recargando vehículos (o obligaciones).', name: 'HomeViewSpeedDial');
                Provider.of<VehiculoProvider>(context, listen: false).fetchVehiculos();
              }
            },
          ),
        ];
      case 1: // Mantenimiento
        return [
          SpeedDialChild(
            child: const Icon(Icons.build),
            label: 'Nuevo mantenimiento',
            onTap: () async {
              log('Navegando a AddMaintenanceView...', name: 'HomeViewSpeedDial');
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMaintenanceView()),
              );
              if (result == true) {
                log('Mantenimiento añadido, recargando mantenimientos (asumiendo MaintenanceProvider).', name: 'HomeViewSpeedDial');
                // Provider.of<MaintenanceProvider>(context, listen: false).fetchMaintenances();
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Nueva orden QR',
            onTap: () async {
              log('Intentando abrir diálogo para seleccionar vehículo para QR Order...', name: 'HomeViewSpeedDial');
              final vehiculoProvider = Provider.of<VehiculoProvider>(context, listen: false);
              if (vehiculoProvider.vehiculos.isEmpty && !vehiculoProvider.isLoading) {
                log('Vehículos no cargados, fetching vehiculos...', name: 'HomeViewSpeedDial');
                await vehiculoProvider.fetchVehiculos();
              }

              if (vehiculoProvider.vehiculos.isEmpty) {
                log('No hay vehículos disponibles para QR Order.', name: 'HomeViewSpeedDial');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay vehículos disponibles para seleccionar.')),
                );
                return;
              }

              final seleccionado = await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Selecciona un vehículo'),
                  children: vehiculoProvider.vehiculos.map((v) {
                    return SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, v),
                      child: Text('${v.marca} ${v.modelo} (${v.placa})'),
                    );
                  }).toList(),
                ),
              );

              if (seleccionado != null) {
                log('Vehículo seleccionado para QR Order: ${seleccionado.placa}', name: 'HomeViewSpeedDial');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => QrOrderView(vehiculoId: seleccionado.id)),
                );
              } else {
                log('Selección de vehículo para QR Order cancelada.', name: 'HomeViewSpeedDial');
              }
            },
          ),
        ];
      case 2: // Reportes
        return [
          SpeedDialChild(
            child: const Icon(Icons.insert_chart),
            label: 'Generar reporte',
            onTap: () {
              log('Generar reporte (placeholder).', name: 'HomeViewSpeedDial');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad "Generar reporte" en desarrollo.')),
              );
            },
          ),
        ];
      case 3: // Alertas
        return [
          SpeedDialChild(
            child: const Icon(Icons.notification_add),
            label: 'Agregar alerta',
            onTap: () {
              log('Agregar alerta (placeholder).', name: 'HomeViewSpeedDial');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad "Agregar alerta" en desarrollo.')),
              );
            },
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    log('HomeView build: _currentIndex = $_currentIndex, Auth Status: ${authProvider.status}', name: 'HomeView');

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
      appBar: AppBar(
        title: Text(
          'Yana',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Color del título
          ),
        ),
        // Mantener el AppBar transparente o con un color claro que se integre.
        // Aquí lo dejaremos transparente para mantener un aspecto minimalista,
        // asumiendo que el fondo será un color sólido (blanco).
        backgroundColor: Colors.white, // Color de fondo sólido para el AppBar
        elevation: 1, // Una pequeña elevación puede ayudar a separarlo del contenido si el fondo es blanco.
        iconTheme: const IconThemeData(color: Colors.black54), // Color de los íconos del AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              log('Mostrando diálogo de cerrar sesión.', name: 'HomeView');
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
                          Navigator.of(context).pop();
                          log('Cerrar sesión cancelado.', name: 'HomeView');
                        },
                      ),
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          authProvider.logout();
                          log('Cerrando sesión...', name: 'HomeView');
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
          indicatorColor: Colors.blue, // Color del indicador de la pestaña seleccionada
          labelColor: Colors.blue, // Color del texto/ícono de la pestaña seleccionada
          unselectedLabelColor: Colors.black54, // Color de las pestañas no seleccionadas
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600), // Fuente Poppins para etiquetas seleccionadas
          unselectedLabelStyle: GoogleFonts.poppins(), // Fuente Poppins para etiquetas no seleccionadas
          tabs: const [
            Tab(text: 'Vehículos', icon: Icon(Icons.directions_car)),
            Tab(text: 'Mantenimiento', icon: Icon(Icons.build_circle)),
            Tab(text: 'Reportes', icon: Icon(Icons.insert_chart)),
            Tab(text: 'Alertas', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: TabBarView( // Ya no necesitamos un Stack si no hay elementos de fondo custom.
        controller: _tabController,
        children: const [
          VehiclesTab(),
          MaintenanceTab(),
          ReportsTab(),
          AlertsTab(),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue, // Usar un color consistente
        foregroundColor: Colors.white,
        children: _buildSpeedDialActions(_currentIndex),
      ),
    );
  }
}