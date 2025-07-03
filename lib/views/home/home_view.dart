// lib/views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:yana/views/home/tabs/alerts_tab.dart';
import 'package:yana/views/home/tabs/reports_tab.dart';
import 'package:yana/views/maintenance/qr_maintenance_view.dart';
import 'package:yana/views/vehicles/add_vehicle_view.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yana'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // actualiza índice cuando cambias de pestaña
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
