// lib/views/home/tabs/vehicles_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/views/documents/docs_view.dart';
import 'package:yana/views/vehicles/edit_vehicle_view.dart'; // <-- IMPORT EDIT VIEW

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({Key? key}) : super(key: key);

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().fetchVehiculos();
    });
  }

  List<Map<String, dynamic>> _generateFakeDocs() => [
        {'name': 'SOAT', 'status': Colors.green},
        {'name': 'Propiedad', 'status': Colors.yellow},
        {'name': 'Revisión1', 'status': Colors.red},
        {'name': 'Revisión2', 'status': Colors.red},
        {'name': 'Revisión3', 'status': Colors.red},
        {'name': 'Revisión4', 'status': Colors.red},
        {'name': 'Revisión5', 'status': Colors.red},
        {'name': 'Revisión6', 'status': Colors.red},
      ];

  @override
  Widget build(BuildContext context) {
    final vehProv = context.watch<VehiculoProvider>();

    if (vehProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehProv.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              'Error: ${vehProv.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                vehProv.clearErrorMessage();
                vehProv.fetchVehiculos();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final vehicles = vehProv.vehiculos;
    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tienes vehículos registrados.',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Usa el botón "+" para agregar uno.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    if (selectedIndex >= vehicles.length) selectedIndex = 0;
    final featuredVehicle = vehicles[selectedIndex];
    final featuredDataForCard = {
      'id': featuredVehicle.id,
      'placa': featuredVehicle.placa,
      'marca': featuredVehicle.marca,
      'modelo': featuredVehicle.modelo,
      'year': featuredVehicle.year,
      'color': featuredVehicle.color,
      'propietarioId': featuredVehicle.propietarioId,
      'docs': _generateFakeDocs(),
      'isCar': !featuredVehicle.modelo.toLowerCase().contains('moto'),
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: Text('📦 Modelo 3D',
                  style: TextStyle(fontSize: 18, color: Colors.black54)),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _DocsHeaderDelegate(
            minHeight: 141,
            maxHeight: 141,
            child: _DocsCard(data: featuredDataForCard),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = vehicles[index];
                final isSelected = index == selectedIndex;
                final icon = v.modelo.toLowerCase().contains('moto')
                    ? Icons.two_wheeler
                    : Icons.directions_car;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        selectedIndex = index;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(icon, size: 32, color: Colors.black54),
                            const SizedBox(width: 24),
                            const SizedBox(
                              height: 40,
                              child:
                                  VerticalDivider(thickness: 1, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${v.marca} ${v.modelo}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Placa: ${v.placa}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              const Icon(Icons.check_circle, color: Colors.blue),
                              const SizedBox(width: 8),
                              // EDIT BUTTON
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditVehicleView(vehicle: v),
                                    ),
                                  );
                                },
                              ),
                              // DELETE BUTTON
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title:
                                          const Text('Confirmar eliminación'),
                                      content: const Text(
                                          '¿Seguro que quieres eliminar este vehículo?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await vehProv
                                                .deleteVehiculo(v.id);
                                          },
                                          child: const Text('Eliminar',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
              childCount: vehicles.length,
            ),
          ),
        ),
      ],
    );
  }
}

// Delegate para SliverPersistentHeader
class _DocsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _DocsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _DocsHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// Documento tile
class _DocTile extends StatelessWidget {
  final String name;
  final Color dotColor;
  const _DocTile({Key? key, required this.name, required this.dotColor})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.description, size: 32),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Card de documentos y marca
class _DocsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DocsCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docs = data['docs'] as List;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Material(
        elevation: 0,
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${data['marca']} ${data['modelo']}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocsView(vehicleData: data),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _DocTile(
                        name: doc['name'] as String,
                        dotColor: doc['status'] as Color,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
