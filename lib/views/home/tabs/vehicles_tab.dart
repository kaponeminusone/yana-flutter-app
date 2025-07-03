// lib/views/home/tabs/vehicles_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ¡Importar Provider!
import 'package:yana/models/vehiculo_model.dart'; // ¡Importar tu modelo de vehículo!
import 'package:yana/providers/vehiculo_provider.dart'; // ¡Importar tu VehiculoProvider!
import 'package:yana/views/documents/docs_view.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({Key? key}) : super(key: key);

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  // Ahora el selectedIndex se refiere al índice en la lista de vehículos reales
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cuando el widget se inicializa, solicita al provider que cargue los vehículos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehiculoProvider>(context, listen: false).fetchVehiculos();
    });
  }

  // Función auxiliar para generar datos de documentos (simulados) para cada vehículo.
  // Esto es necesario porque tu `VehiculoModel` del backend no incluye esta información.
  List<Map<String, dynamic>> _generateFakeDocs() {
    return [
      {'name': 'SOAT', 'status': Colors.green},
      {'name': 'Propiedad', 'status': Colors.yellow},
      {'name': 'Revisión1', 'status': Colors.red},
      {'name': 'Revisión2', 'status': Colors.red},
      {'name': 'Revisión3', 'status': Colors.red},
      {'name': 'Revisión4', 'status': Colors.red},
      {'name': 'Revisión5', 'status': Colors.red},
      {'name': 'Revisión6', 'status': Colors.red},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en VehiculoProvider
    final vehiculoProvider = context.watch<VehiculoProvider>();

    if (vehiculoProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehiculoProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              'Error: ${vehiculoProvider.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Intenta cargar de nuevo los vehículos
                vehiculoProvider.fetchVehiculos();
                vehiculoProvider.clearErrorMessage(); // Limpia el mensaje de error
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final List<VehiculoModel> vehicles = vehiculoProvider.vehiculos;

    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes vehículos registrados.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Usa el botón "+" para agregar uno.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Asegura que selectedIndex sea válido si la lista de vehículos cambia.
    if (selectedIndex >= vehicles.length) {
      selectedIndex = 0;
    }
    final VehiculoModel featuredVehicle = vehicles[selectedIndex];

    // Combinamos el modelo de vehículo real con los datos de documentos simulados
    final Map<String, dynamic> featuredDataForCard = {
      'id': featuredVehicle.id,
      'placa': featuredVehicle.placa,
      'marca': featuredVehicle.marca,
      'modelo': featuredVehicle.modelo,
      'year': featuredVehicle.year,
      'color': featuredVehicle.color,
      'propietarioId': featuredVehicle.propietarioId,
      // Los documentos son simulados, ya que no están en VehiculoModel de tu backend
      'docs': _generateFakeDocs(),
      'isCar': featuredVehicle.modelo.toLowerCase().contains('auto') || featuredVehicle.modelo.toLowerCase().contains('carro'), // Intenta deducir si es carro/moto
    };


    return CustomScrollView(
      slivers: [
        // Modelo 3D que desaparece al scrollear
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: Text(
                '📦 Modelo 3D',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
          ),
        ),

        // Header persistente con card redondeada abajo
        SliverPersistentHeader(
          pinned: true,
          delegate: _DocsHeaderDelegate(
            minHeight: 141,
            maxHeight: 141,
            // Pasa el Map combinado para el _DocsCard
            child: _DocsCard(data: featuredDataForCard),
          ),
        ),

        // Lista de vehículos con el nuevo diseño
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = vehicles[index];
                final isSelected = index == selectedIndex;
                // Ajusta el ícono basado en el modelo o un nuevo campo en VehiculoModel
                final icon = v.modelo.toLowerCase().contains('moto') ? Icons.two_wheeler : Icons.directions_car;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // Ícono de vehículo (carro o moto)
                            Icon(icon, size: 32, color: Colors.black54),

                            const SizedBox(width: 24), // Espacio entre el ícono y el divisor

                            // Divisor vertical
                            const SizedBox(
                              height: 40, // Altura fija para el divisor
                              child: VerticalDivider(
                                thickness: 1,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Información del vehículo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Muestra marca y modelo
                                    '${v.marca} ${v.modelo}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placa: ${v.placa}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Indicador de selección
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.blue),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1), // Divisor horizontal entre elementos de la lista
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

// Delegate para SliverPersistentHeader (SIN CAMBIOS)
class _DocsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _DocsHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _DocsHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// Widget para cada documento (SIN CAMBIOS)
class _DocTile extends StatelessWidget {
  final String name;
  final Color dotColor;
  const _DocTile({Key? key, required this.name, required this.dotColor}) : super(key: key);

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
                    width: 1.5,
                  ),
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

// Card de documentos y marca con bordes inferiores redondeados (AJUSTADO PARA RECIBIR Map<String, dynamic>)
class _DocsCard extends StatelessWidget {
  // Ahora data puede venir de un VehiculoModel convertido a Map,
  // o directamente de un Map si así lo decides manejar.
  final Map<String, dynamic> data;
  const _DocsCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aseguramos que 'docs' sea una lista, aunque sean simulados
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
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con la marca y el botón de flecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      // Muestra la marca y modelo del vehículo real
                      '${data['marca']} ${data['modelo']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // El nuevo botón de flecha
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    iconSize: 20,
                    color: Colors.black54,
                    onPressed: () {
                      // Navega a la nueva vista de documentos, pasando el Map completo.
                      // En DocsView, tendrías que adaptar para leer los datos del Map.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocsView(vehicleData: data),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ListView horizontal para los documentos
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
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